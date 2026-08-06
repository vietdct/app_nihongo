import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../domain/entities/lesson.dart';
import '../../../../domain/services/dialogue_listening_generator.dart';
import '../../../../domain/services/jlpt_scoring.dart';
import '../../../../domain/services/quiz_generator.dart';
import '../../../../domain/services/reading_question_generator.dart';
import '../../../lesson/providers/level_providers.dart';
import '../../../quiz/providers/listening_dialogue_providers.dart';
import '../providers/jlpt_exam_content_providers.dart';
import 'exam_blueprint.dart';

/// "Theo giờ JLPT" ước lượng phút theo tỉ lệ số câu (dùng
/// [officialTimingMinutesBySectionType]), "Không giới hạn" là mặc định —
/// cùng khái niệm `MiniTestTimerMode` nhưng khai báo riêng vì Custom Test
/// không phụ thuộc `mini_test_settings_sheet.dart`.
enum CustomTestTimerMode { unlimited, jlptTimed }

/// Cấu hình 1 lượt Custom Test — người dùng tự chọn PHẦN NÀO thi + SỐ CÂU
/// MỖI PHẦN (docs/JLPT_MOCK_EXAM_DESIGN.md §3 "giống UX
/// ReviewMixedQuizCustomScreen"), khác Mini Test ở chỗ mỗi phần được sinh
/// thành 1 [ExamRunSection] RIÊNG (không gộp xáo chung 1 section "mixed")
/// để giữ đúng trải nghiệm "làm từng phần" như Full Exam. Build ĐỘNG lúc
/// runtime, không ghi vào bảng `jlpt_exam_blueprints` dùng chung nhiều
/// người — cùng lý do đã áp dụng cho `MiniTestBlueprint`.
class CustomTestBlueprint {
  const CustomTestBlueprint({
    required this.levelId,
    required this.sourceCounts,
    this.timerMode = CustomTestTimerMode.unlimited,
  });

  final String levelId;

  /// key: 'vocabulary' | 'grammar' | 'kanji' | 'reading' | 'listening' —
  /// CHỈ chứa các phần người dùng đã bật (count > 0), không chứa entry 0.
  final Map<String, int> sourceCounts;

  final CustomTestTimerMode timerMode;

  static const sessionMode = 'custom_test';
}

const _quizGenerator = QuizGenerator();
const _readingGenerator = ReadingQuestionGenerator();
const _listeningGenerator = DialogueListeningGenerator();

/// Sinh câu hỏi 1 LẦN cho mỗi phần đã chọn — tái dùng nguyên
/// `QuizGenerator`/`ReadingQuestionGenerator`/`DialogueListeningGenerator`
/// + provider nội dung đã có ở Mini Test/Full Exam
/// (`jlpt_exam_content_providers.dart`), không viết generator mới. Phần
/// nào không có đủ nội dung (pool rỗng) sẽ bị BỎ QUA thay vì chặn cả đề —
/// người dùng vẫn thi được các phần còn lại, đúng tinh thần Custom Test
/// "chọn phần muốn luyện" chứ không phải "phải có đủ mọi phần mới thi
/// được".
Future<List<ExamRunSection>> buildCustomTestRunSections(
  WidgetRef ref,
  CustomTestBlueprint blueprint,
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

  Map<String, int>? officialMinutes;
  if (blueprint.timerMode == CustomTestTimerMode.jlptTimed &&
      levelCode != null) {
    officialMinutes = officialTimingMinutesBySectionType(
      levelCode: levelCode,
      sections: [
        for (final e in blueprint.sourceCounts.entries)
          ExamSectionSpec(type: e.key, questionCount: e.value, timeMinutes: 0),
      ],
    );
  }

  Future<void> addQuizSection(
    String type,
    List<LessonContentItem> pool,
  ) async {
    final count = blueprint.sourceCounts[type];
    if (count == null || count <= 0 || pool.isEmpty) return;
    sections.add(
      ExamRunSection(
        type: type,
        timeMinutes: officialMinutes?[type] ?? 0,
        questions: _quizGenerator.generate(pool: pool, questionCount: count),
      ),
    );
  }

  if (blueprint.sourceCounts.containsKey('vocabulary')) {
    final vocab = await ref.read(
      examVocabularyForLevelProvider(blueprint.levelId).future,
    );
    await addQuizSection(
      'vocabulary',
      [for (final v in vocab) LessonContentItem.vocabulary(v)],
    );
  }
  if (blueprint.sourceCounts.containsKey('grammar')) {
    final grammar = await ref.read(
      examGrammarForLevelProvider(blueprint.levelId).future,
    );
    await addQuizSection(
      'grammar',
      [for (final g in grammar) LessonContentItem.grammar(g)],
    );
  }
  if (blueprint.sourceCounts.containsKey('kanji')) {
    final kanji =
        await ref.read(examKanjiForLevelProvider(blueprint.levelId).future);
    await addQuizSection(
      'kanji',
      [for (final k in kanji) LessonContentItem.kanji(k)],
    );
  }
  final readingCount = blueprint.sourceCounts['reading'];
  if (readingCount != null && readingCount > 0) {
    final passages = await ref.read(
      examReadingPassagesForLevelProvider(blueprint.levelId).future,
    );
    if (passages.isNotEmpty) {
      sections.add(
        ExamRunSection(
          type: 'reading',
          timeMinutes: officialMinutes?['reading'] ?? 0,
          questions: _readingGenerator.generate(
            passages: passages,
            questionCount: readingCount,
          ),
        ),
      );
    }
  }
  final listeningCount = blueprint.sourceCounts['listening'];
  if (listeningCount != null && listeningCount > 0) {
    final dialogues = await ref.read(
      listeningDialoguesForLevelProvider(blueprint.levelId).future,
    );
    if (dialogues.isNotEmpty) {
      sections.add(
        ExamRunSection(
          type: 'listening',
          timeMinutes: officialMinutes?['listening'] ?? 0,
          questions: _listeningGenerator.generate(
            dialogues: dialogues,
            questionCount: listeningCount,
          ),
        ),
      );
    }
  }

  return sections;
}
