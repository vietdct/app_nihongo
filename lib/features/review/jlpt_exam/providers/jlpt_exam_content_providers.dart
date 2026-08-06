import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/supabase_providers.dart';
import '../../../../data/repositories/content_repository_provider.dart';
import '../../../../domain/entities/grammar_point.dart';
import '../../../../domain/entities/kanji.dart';
import '../../../../domain/entities/lesson.dart';
import '../../../../domain/entities/reading_passage.dart';
import '../../../../domain/entities/vocabulary.dart';
import '../../../../domain/services/dialogue_listening_generator.dart';
import '../../../../domain/services/jlpt_scoring.dart';
import '../../../../domain/services/quiz_generator.dart';
import '../../../../domain/services/reading_question_generator.dart';
import '../../../lesson/providers/level_providers.dart';
import '../../../quiz/providers/listening_dialogue_providers.dart';
import '../models/exam_blueprint.dart';

const _examQuizGenerator = QuizGenerator();
const _examDialogueGenerator = DialogueListeningGenerator();
const _examReadingGenerator = ReadingQuestionGenerator();

/// Đọc cấu trúc đề theo level+mode từ `jlpt_exam_blueprints` — null khi
/// chưa seed đề cho level/mode đó (UI cần xử lý null bằng thông báo
/// "chưa có đề", không giả định luôn có).
final examBlueprintProvider =
    FutureProvider.family<ExamBlueprint?, ({String levelId, String mode})>(
        (ref, args) async {
  final sb = ref.watch(supabaseProvider);
  final rows = await sb
      .from('jlpt_exam_blueprints')
      .select()
      .eq('level_id', args.levelId)
      .eq('mode', args.mode)
      .limit(1);
  if (rows.isEmpty) return null;
  return ExamBlueprint.fromRow(rows.first);
});

/// Nội dung Từ vựng/Ngữ pháp theo ĐÚNG level đã chọn ở màn "Thi thử JLPT"
/// — gọi trực tiếp `contentRepositoryProvider`, KHÔNG dùng
/// `vocabularyListProvider`/`grammarListProvider` (lesson/providers/content_providers.dart)
/// vì 2 provider đó khoá theo `currentLevelIdProvider` (level đang browse ở
/// tab Lesson), có thể khác level người dùng chọn để thi.
final examVocabularyForLevelProvider =
    StreamProvider.family<List<Vocabulary>, String>((ref, levelId) {
  return ref.watch(contentRepositoryProvider).watchVocabulary(levelId);
});

final examGrammarForLevelProvider =
    StreamProvider.family<List<GrammarPoint>, String>((ref, levelId) {
  return ref.watch(contentRepositoryProvider).watchGrammar(levelId);
});

/// Nguồn câu "Kanji" cho Mini Test (docs/JLPT_MINI_TEST_DESIGN.md §4) — cùng
/// pattern [examVocabularyForLevelProvider]/[examGrammarForLevelProvider].
final examKanjiForLevelProvider =
    StreamProvider.family<List<Kanji>, String>((ref, levelId) {
  return ref.watch(contentRepositoryProvider).watchKanji(levelId);
});

/// Đoạn văn đọc hiểu — nội dung riêng của Mock Exam (không dùng chung với
/// Quiz feature như Listening), fetch thẳng từ Supabase, không cần cache
/// Drift (nội dung ít, soạn tay — xem docs/JLPT_MOCK_EXAM_DESIGN.md §8).
final examReadingPassagesForLevelProvider =
    FutureProvider.family<List<ReadingPassage>, String>((ref, levelId) async {
  final sb = ref.watch(supabaseProvider);
  final rows =
      await sb.from('reading_passages').select().eq('level_id', levelId);
  return [
    for (final r in rows)
      ReadingPassage(
        id: r['id'] as String,
        levelId: r['level_id'] as String,
        title: r['title'] as String,
        bodyJa: r['body_ja'] as String,
        questions: [
          for (final q in r['questions'] as List)
            ReadingPassageQuestion(
              questionJa: q['question_ja'] as String,
              options: List<String>.from(q['options'] as List),
              correctIndex: q['correct_index'] as int,
            ),
        ],
      ),
  ];
});

/// 1 phần đề đã sinh xong câu hỏi thật — [questions] cố định 1 lần khi tạo
/// (không sinh lại), để khớp đúng với `question_snapshot` sẽ ghi vào
/// `jlpt_exam_answers` (xem [buildExamRunSections]).
class ExamRunSection {
  const ExamRunSection({
    required this.type,
    required this.timeMinutes,
    required this.questions,
  });

  final String type;
  final int timeMinutes;
  final List<QuizQuestion> questions;
}

/// Sinh câu hỏi 1 LẦN cho toàn bộ các phần Vocab/Grammar của [blueprint],
/// dùng lại nguyên `QuizGenerator.generate` (không viết generator mới —
/// xem docs/JLPT_MOCK_EXAM_DESIGN.md §6). Đây là hàm one-shot (không phải
/// Provider phản ứng lại thay đổi dữ liệu) vì đề JLPT phải cố định trong
/// suốt 1 lượt thi — nếu dùng Provider phản ứng, câu hỏi có thể đổi giữa
/// lúc thi khi nội dung gốc thay đổi.
///
/// Hỗ trợ đủ 4 loại section: vocabulary/grammar (QuizGenerator), listening
/// (DialogueListeningGenerator), reading (ReadingQuestionGenerator).
///
/// Task 7: số phút mỗi section ưu tiên lấy theo Official Timing thật (xem
/// [officialTimingMinutesBySectionType]) thay vì `spec.timeMinutes` trong
/// blueprint — chỉ fallback về `spec.timeMinutes` khi level chưa có rule
/// công khai (`jlptScoringRules`).
Future<List<ExamRunSection>> buildExamRunSections(
  Ref ref,
  ExamBlueprint blueprint,
) async {
  final sections = <ExamRunSection>[];

  final levels = await ref.read(jlptLevelsProvider.future);
  String? levelCode;
  for (final l in levels) {
    if (l.id == blueprint.levelId) {
      levelCode = l.code;
      break;
    }
  }
  final officialMinutes = levelCode == null
      ? null
      : officialTimingMinutesBySectionType(
          levelCode: levelCode,
          sections: blueprint.sections,
        );

  for (final spec in blueprint.sections) {
    final timeMinutes = officialMinutes?[spec.type] ?? spec.timeMinutes;
    switch (spec.type) {
      case 'vocabulary':
        final vocab = await ref.read(
          examVocabularyForLevelProvider(blueprint.levelId).future,
        );
        final pool = [for (final v in vocab) LessonContentItem.vocabulary(v)];
        sections.add(
          ExamRunSection(
            type: spec.type,
            timeMinutes: timeMinutes,
            questions: _examQuizGenerator.generate(
              pool: pool,
              questionCount: spec.questionCount,
            ),
          ),
        );
      case 'grammar':
        final grammar = await ref.read(
          examGrammarForLevelProvider(blueprint.levelId).future,
        );
        final pool = [for (final g in grammar) LessonContentItem.grammar(g)];
        sections.add(
          ExamRunSection(
            type: spec.type,
            timeMinutes: timeMinutes,
            questions: _examQuizGenerator.generate(
              pool: pool,
              questionCount: spec.questionCount,
            ),
          ),
        );
      case 'listening':
        final dialogues = await ref.read(
          listeningDialoguesForLevelProvider(blueprint.levelId).future,
        );
        sections.add(
          ExamRunSection(
            type: spec.type,
            timeMinutes: timeMinutes,
            questions: _examDialogueGenerator.generate(
              dialogues: dialogues,
              questionCount: spec.questionCount,
            ),
          ),
        );
      case 'reading':
        final passages = await ref.read(
          examReadingPassagesForLevelProvider(blueprint.levelId).future,
        );
        sections.add(
          ExamRunSection(
            type: spec.type,
            timeMinutes: timeMinutes,
            questions: _examReadingGenerator.generate(
              passages: passages,
              questionCount: spec.questionCount,
            ),
          ),
        );
      default:
        break;
    }
  }

  return sections;
}

/// Gộp [examBlueprintProvider] + [buildExamRunSections] thành 1 provider
/// duy nhất cho màn thi đọc — `autoDispose` nên rời màn thi rồi quay lại sẽ
/// sinh đề MỚI (đúng ngữ nghĩa "làm lại 1 lượt thi mới", không phải tiếp
/// tục lượt cũ dang dở — tiếp tục phiên dang dở là tính năng mở rộng chưa
/// nằm trong Task 4).
final examRunSectionsProvider = FutureProvider.autoDispose
    .family<List<ExamRunSection>, ({String levelId, String mode})>(
        (ref, args) async {
  final blueprint = await ref.watch(examBlueprintProvider(args).future);
  if (blueprint == null) return [];
  return buildExamRunSections(ref, blueprint);
});

/// Snapshot tối giản của 1 [QuizQuestion] để ghi vào cột jsonb
/// `question_snapshot` (bảng `jlpt_exam_answers`) — chỉ gồm field câu hỏi
/// trắc nghiệm thường (Task 4 chỉ dùng `QuizGenerator.generate`, không có
/// typed/order question ở phần Vocab/Grammar của Mock Exam).
Map<String, dynamic> quizQuestionToSnapshot(QuizQuestion q) => {
      'prompt_vi': q.promptVi,
      'display_jp': q.displayJp,
      'display_is_japanese': q.displayIsJapanese,
      'options': q.options,
      'correct_index': q.correctIndex,
      'source_type': q.sourceType?.name,
    };
