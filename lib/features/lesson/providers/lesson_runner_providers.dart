import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/supabase_providers.dart';
import '../../../domain/entities/lesson.dart';
import '../../../domain/entities/lesson_progress.dart';
import '../../../domain/services/dialogue_listening_generator.dart';
import '../../../domain/services/grammar_practice_generator.dart';
import '../../../domain/services/lesson_mission_generator.dart';
import '../../../domain/services/quiz_generator.dart';
import '../../quiz/providers/listening_dialogue_providers.dart';
import '../lesson_runner_steps.dart';
import 'content_providers.dart';

const _dialogueGenerator = DialogueListeningGenerator();
const _quizGenerator = QuizGenerator();

/// Tìm 1 [Lesson] theo id trong danh sách bài học của cấp độ đang chọn —
/// không cần thêm phương thức repository riêng, [lessonsProvider] đã watch
/// đúng cấp độ hiện tại và bài học luôn thuộc cấp độ đó.
final lessonByIdProvider = Provider.family<AsyncValue<Lesson?>, String>((ref, lessonId) {
  final lessonsAsync = ref.watch(lessonsProvider);
  return lessonsAsync.whenData((list) {
    for (final l in list) {
      if (l.id == lessonId) return l;
    }
    return null;
  });
});

/// Danh sách bước của 1 phiên học, build 1 lần từ nội dung thật của bài —
/// xem `buildLessonSteps`. Ghép thêm câu hỏi nghe hiểu (hội thoại thật của
/// cấp độ bài học — `ListeningDialogue` không có khoá lesson_id riêng, xem
/// `listening_dialogue_providers.dart`) và bài luyện tập (từ chính nội dung
/// bài học, giống cách `lessonQuizQuestionsProvider` đã làm) cho pha
/// Practice — honest-empty tự vắng mặt khi chưa đủ dữ liệu.
final lessonRunnerStepsProvider =
    FutureProvider.family<List<LessonStep>, String>((ref, lessonId) async {
  final items = await ref.watch(lessonItemsProvider(lessonId).future);
  if (items.isEmpty) return const [];

  final lessons = await ref.watch(lessonsProvider.future);
  Lesson? lesson;
  for (final l in lessons) {
    if (l.id == lessonId) {
      lesson = l;
      break;
    }
  }
  if (lesson == null) return const [];

  final dialogues = await ref.watch(listeningDialoguesForLevelProvider(lesson.levelId).future);
  final listeningQuestions = _dialogueGenerator.generate(dialogues: dialogues, questionCount: 2);

  final quizQuestions = _quizGenerator.generate(pool: items, questionCount: 6);
  final grammarPool = [
    for (final item in items)
      if (item.type == LessonItemType.grammar) item.grammar!,
  ];
  final grammarExercises = generatePracticeSession(
    pool: grammarPool,
    exerciseCount: grammarPool.length,
  );

  final practiceItems = <LessonPracticeItem>[
    ...quizQuestions.map(LessonQuizPracticeItem.new),
    ...grammarExercises.map(LessonGrammarPracticeItem.new),
  ]..shuffle();

  final mission = generateLessonMission(lesson: lesson, items: items);
  final reviewItems = [...items]..shuffle();

  return buildLessonSteps(
    items: items,
    listeningQuestions: listeningQuestions,
    practiceItems: practiceItems,
    mission: mission,
    reviewItems: reviewItems,
  );
});

/// Tiến trình đã lưu của 1 bài (nếu có) — đọc từ `user_lesson_progress` để
/// [LessonRunnerScreen] khôi phục đúng bước đang dừng lại khi mở lại bài.
final lessonProgressProvider =
    FutureProvider.family.autoDispose<LessonProgress?, String>((ref, lessonId) async {
  final sb = ref.watch(supabaseProvider);
  final userId = ref.watch(currentUserProvider)?.id;
  if (userId == null) return null;

  final row = await sb
      .from('user_lesson_progress')
      .select('last_step_index, total_steps, completed_at')
      .eq('user_id', userId)
      .eq('lesson_id', lessonId)
      .maybeSingle();
  if (row == null) return null;

  return LessonProgress(
    lastStepIndex: row['last_step_index'] as int,
    totalSteps: row['total_steps'] as int,
    completedAt: row['completed_at'] == null
        ? null
        : DateTime.parse(row['completed_at'] as String),
  );
});

/// Vị trí bước hiện tại trong phiên học — bắt đầu ở 0, được đồng bộ về đúng
/// bước đã lưu ở [lessonProgressProvider] ngay khi mở bài (xem
/// `_LessonRunnerScreenState._restoreIfNeeded`).
class LessonRunnerController extends StateNotifier<int> {
  LessonRunnerController() : super(0);

  void goTo(int index) => state = index;

  void next(int totalSteps) {
    if (state < totalSteps - 1) state++;
  }

  void back() {
    if (state > 0) state--;
  }
}

final lessonRunnerControllerProvider =
    StateNotifierProvider.autoDispose.family<LessonRunnerController, int, String>(
  (ref, lessonId) => LessonRunnerController(),
);
