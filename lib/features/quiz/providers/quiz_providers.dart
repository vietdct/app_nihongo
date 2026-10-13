import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/network/supabase_providers.dart';
import '../../../domain/entities/grammar_practice_question.dart';
import '../../../domain/entities/lesson.dart';
import '../../../domain/entities/listening_dialogue.dart';
import '../../../domain/services/dialogue_listening_generator.dart';
import '../../../domain/services/practice_strategy.dart';
import '../../../domain/services/quiz_generator.dart';
import '../../lesson/it_learning_hub.dart' show lessonProgressMapProvider;
import '../../lesson/providers/content_providers.dart';
import '../../lesson/providers/level_providers.dart';
import 'grammar_practice_providers.dart';
import 'listening_dialogue_providers.dart';

const _quizGenerator = QuizGenerator();
const _dialogueGenerator = DialogueListeningGenerator();

/// Quiz theo 1 bài học cụ thể — pool câu hỏi = đúng nội dung bài học đó
/// (`lessonItemsProvider`). Không cần distractorPool riêng: nếu bài học
/// quá ít item, QuizGenerator tự co số lựa chọn mỗi câu (xem quiz_generator.dart).
///
/// `autoDispose`: cố ý KHÔNG giữ cache — `Provider` thường sẽ chỉ gọi
/// `generate()` (và xáo trộn) đúng 1 lần rồi tái dùng mãi mãi trong suốt
/// vòng đời app, khiến làm lại quiz vẫn ra y hệt thứ tự câu/đáp án cũ
/// (dễ đoán). `autoDispose` khiến provider bị huỷ khi rời màn quiz, nên
/// lần vào sau tính lại từ đầu — random mới mỗi lần học.
final lessonQuizQuestionsProvider = Provider.autoDispose
    .family<AsyncValue<List<QuizQuestion>>, String>((ref, lessonId) {
  final itemsAsync = ref.watch(lessonItemsProvider(lessonId));
  return itemsAsync.whenData((items) => _quizGenerator.generate(pool: items));
});

/// 1 trong 3 mảng nội dung có thể quiz riêng theo trình độ — người dùng chọn
/// đúng 1 mảng trước khi vào quiz (xem `quiz_category_screen.dart`), không
/// còn gộp chung Vocabulary+Kanji+Grammar vào 1 bài như trước.
enum QuizCategory { vocabulary, kanji, grammar }

extension QuizCategoryLabel on QuizCategory {
  String get label => switch (this) {
        QuizCategory.vocabulary => 'Từ vựng',
        QuizCategory.kanji => 'Kanji',
        QuizCategory.grammar => 'Ngữ pháp',
      };

  /// Khớp giá trị dùng trong path `/quiz/:category` — xem app_router.dart.
  String get routeSegment => name;

  static QuizCategory? fromRouteSegment(String segment) {
    for (final c in QuizCategory.values) {
      if (c.routeSegment == segment) return c;
    }
    return null;
  }
}

/// Yêu cầu quiz theo 1 mảng nội dung. [lessonIds] (id cách nhau bằng dấu
/// phẩy) null = toàn bộ cấp độ;
/// [count] null = số câu mặc định cũ (15). Dùng record để có so sánh bằng
/// giá trị làm key family.
typedef QuizRequest = ({QuizCategory category, String? lessonIds, int? count});

/// Quiz theo 1 mảng nội dung riêng (Từ vựng/Kanji/Ngữ pháp), trong phạm vi
/// 1 bài (`lessonId`) hoặc toàn bộ cấp độ hiện tại (currentLevelIdProvider).
/// Cách sinh câu hỏi do [PracticeStrategy] của level quyết định (N5–N1 vs IT,
/// xem `practice_strategy.dart`). `autoDispose` — xem giải thích ở
/// [lessonQuizQuestionsProvider].
final levelCategoryQuizQuestionsProvider = Provider.autoDispose
    .family<AsyncValue<List<QuizQuestion>>, QuizRequest>((ref, req) {
  final count = req.count ?? 15;
  final profile = practiceProfileFor(ref.watch(selectedLevelCodeProvider));
  final strategy = practiceStrategyFor(profile);
  final isIt = profile == PracticeProfile.it;
  final lessonIds = req.lessonIds?.split(',');

  // Câu Ngữ pháp đã soạn sẵn (có nhiễu + lời giải + nguồn) chỉ dùng cho IT.
  // Chờ tải xong rồi mới sinh đề để danh sách câu hỏi không đổi giữa chừng.
  var curated = const AsyncValue<List<GrammarPracticeQuestion>>.data([]);
  if (isIt && req.category == QuizCategory.grammar) {
    final levelId = ref.watch(currentLevelIdProvider);
    if (lessonIds != null) {
      curated = ref.watch(grammarPracticeForLessonsProvider(req.lessonIds!));
    } else if (levelId == null) {
      return const AsyncValue.loading();
    } else {
      curated = ref.watch(grammarPracticeForLevelProvider(levelId));
    }
  }
  if (curated.isLoading) return const AsyncValue.loading();
  final curatedList = curated.valueOrNull ?? const <GrammarPracticeQuestion>[];

  if (lessonIds != null) {
    final merged = _mergeAsync<LessonContentItem>([
      for (final id in lessonIds) ref.watch(lessonItemsProvider(id)),
    ]);
    return merged.whenData((all) {
      List<LessonContentItem> ofType(LessonItemType t) =>
          [for (final i in all) if (i.type == t) i];
      final vocab = [
        for (final i in ofType(LessonItemType.vocabulary)) i.vocabulary!,
      ];
      return switch (req.category) {
        QuizCategory.vocabulary => strategy.vocabulary(vocab, count),
        QuizCategory.grammar => strategy.grammar(
            [for (final i in ofType(LessonItemType.grammar)) i.grammar!],
            count,
            curated: curatedList,
          ),
        QuizCategory.kanji => strategy.kanji(
            kanjiItems: ofType(LessonItemType.kanji),
            vocabulary: vocab,
            count: count,
          ),
      };
    });
  }
  switch (req.category) {
    case QuizCategory.vocabulary:
      return ref
          .watch(vocabularyListProvider)
          .whenData((items) => strategy.vocabulary(items, count));
    case QuizCategory.kanji:
      final kanji = ref.watch(kanjiListProvider);
      if (!isIt) {
        return kanji.whenData(
          (items) => strategy.kanji(
            kanjiItems: [for (final k in items) LessonContentItem.kanji(k)],
            vocabulary: const [],
            count: count,
          ),
        );
      }
      final vocab = ref.watch(vocabularyListProvider);
      if (kanji.hasError) return AsyncValue.error(kanji.error!, kanji.stackTrace!);
      if (vocab.hasError) return AsyncValue.error(vocab.error!, vocab.stackTrace!);
      if (!kanji.hasValue || !vocab.hasValue) return const AsyncValue.loading();
      return AsyncValue.data(strategy.kanji(
        kanjiItems: [for (final k in kanji.requireValue) LessonContentItem.kanji(k)],
        vocabulary: vocab.requireValue,
        count: count,
      ));
    case QuizCategory.grammar:
      return ref.watch(grammarListProvider).whenData(
            (items) => strategy.grammar(items, count, curated: curatedList),
          );
  }
});

/// Phạm vi/số câu người dùng chọn trên màn Luyện tập (chỉ khóa IT) — state
/// cục bộ, không lưu DB.
enum QuizScope { current, learned, all }

final quizScopeProvider = StateProvider<QuizScope>((ref) => QuizScope.current);
final quizQuestionCountProvider = StateProvider<int>((ref) => 10);

/// Bài đang học của khóa hiện tại: bài đầu tiên chưa hoàn thành (cùng quy tắc
/// với "Tiếp tục học" ở Learning Hub), hết bài thì bài cuối.
final quizCurrentLessonProvider =
    FutureProvider.autoDispose<Lesson?>((ref) async {
  final lessons = await ref.watch(lessonsProvider.future);
  if (lessons.isEmpty) return null;
  final progress = await ref.watch(lessonProgressMapProvider.future);
  final sorted = [...lessons]
    ..sort((a, b) => a.orderIndex.compareTo(b.orderIndex));
  return sorted.firstWhere(
    (l) => !(progress[l.id]?.isCompleted ?? false),
    orElse: () => sorted.last,
  );
});

/// Các bài đã học = bài đã hoàn thành hoặc đã bắt đầu (có bước dừng > 0),
/// luôn gồm cả bài hiện tại. Dựa trên `user_lesson_progress`, không bịa thêm.
final quizLearnedLessonsProvider =
    FutureProvider.autoDispose<List<Lesson>>((ref) async {
  final lessons = await ref.watch(lessonsProvider.future);
  final current = await ref.watch(quizCurrentLessonProvider.future);
  final progress = await ref.watch(lessonProgressMapProvider.future);
  final sorted = [...lessons]
    ..sort((a, b) => a.orderIndex.compareTo(b.orderIndex));
  return [
    for (final l in sorted)
      if (l.id == current?.id ||
          (progress[l.id]?.isCompleted ?? false) ||
          (progress[l.id]?.lastStepIndex ?? 0) > 0)
        l,
  ];
});

AsyncValue<List<T>> _mergeAsync<T>(List<AsyncValue<List<T>>> parts) {
  for (final p in parts) {
    if (p.hasError) return AsyncValue.error(p.error!, p.stackTrace!);
  }
  if (parts.any((p) => !p.hasValue)) return const AsyncValue.loading();
  return AsyncValue.data([for (final p in parts) ...p.requireValue]);
}

/// Nghe hiểu giới hạn trong 1 bài (hội thoại gắn `lesson_id`).
final lessonListeningQuestionsProvider = Provider.autoDispose
    .family<AsyncValue<List<QuizQuestion>>, ({String lessonIds, int count})>(
        (ref, req) {
  final merged = _mergeAsync<ListeningDialogue>([
    for (final id in req.lessonIds.split(','))
      ref.watch(listeningDialoguesForLessonProvider(id)),
  ]);
  return merged.whenData(
    (d) => _dialogueGenerator.generate(
      dialogues: d,
      questionCount: req.count,
      allowSingle: true,
    ),
  );
});

/// Quiz nghe hiểu theo trình độ hiện tại — kiểu đề nghe JLPT thật, trộn nhiều
/// thể loại khác nhau (hội thoại hỏi chi tiết / hội thoại "làm gì trước-tiếp
/// theo" / độc thoại-thông báo / câu ngắn chọn phản hồi phù hợp — xem
/// `seed_listening_n5.sql` + `seed_listening_n5_more.sql`) để đỡ lặp lại
/// đúng 1 kiểu. Mỗi lần vào chọn ngẫu nhiên 1 tập con trong toàn bộ pool nên
/// thể loại/độ dài/thứ tự khác nhau mỗi lượt học. `autoDispose` — xem giải
/// thích ở [lessonQuizQuestionsProvider].
final levelListeningQuestionsProvider = Provider.autoDispose
    .family<AsyncValue<List<QuizQuestion>>, int>((ref, count) {
  final levelId = ref.watch(currentLevelIdProvider);
  if (levelId == null) return const AsyncValue.loading();

  final dialoguesAsync = ref.watch(listeningDialoguesForLevelProvider(levelId));
  return dialoguesAsync.whenData(
    (dialogues) =>
        _dialogueGenerator.generate(dialogues: dialogues, questionCount: count),
  );
});

final quizXpControllerProvider = Provider.autoDispose<QuizXpController?>((ref) {
  final sb = ref.watch(supabaseProvider);
  final userId = ref.watch(currentUserProvider)?.id;
  if (userId == null) return null;
  return QuizXpController(sb, userId);
});

/// Cộng XP thật vào `profiles.xp` mỗi câu trả lời đúng trong quiz. Đọc giá
/// trị hiện tại rồi ghi đè (không có RPC increment riêng) — chấp nhận được
/// vì các lệnh gọi trong 1 phiên quiz luôn được await tuần tự, không có 2
/// request cộng XP chạy song song từ cùng 1 thiết bị.
class QuizXpController {
  QuizXpController(this._sb, this._userId);

  final SupabaseClient _sb;
  final String _userId;

  Future<void> addXp(int delta) async {
    final row =
        await _sb.from('profiles').select('xp').eq('id', _userId).single();
    final current = (row['xp'] as num?)?.toInt() ?? 0;
    await _sb
        .from('profiles')
        .update({'xp': current + delta}).eq('id', _userId);
  }

  /// Ghi mốc hoàn thành 1 bài quiz — Quiz không có bảng log buổi làm bài nào
  /// khác, dùng để mission "Hoàn thành 1 bài Quiz" trên Home biết hôm nay đã
  /// làm chưa (xem `daily_mission.dart`/`mission_providers.dart`). Gọi khi
  /// hết câu hỏi, không phụ thuộc điểm số (mission là "hoàn thành", không
  /// phải "đạt điểm cao").
  Future<void> markQuizCompletedToday() async {
    await _sb
        .from('profiles')
        .update({'last_quiz_completed_at': DateTime.now().toUtc().toIso8601String()})
        .eq('id', _userId);
  }
}
