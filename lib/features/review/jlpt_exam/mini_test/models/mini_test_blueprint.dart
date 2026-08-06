import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../domain/entities/lesson.dart';
import '../../../../../domain/services/dialogue_listening_generator.dart';
import '../../../../../domain/services/jlpt_scoring.dart';
import '../../../../../domain/services/quiz_generator.dart';
import '../../../../../domain/services/reading_question_generator.dart';
import '../../../../grammar/providers/grammar_progress_providers.dart';
import '../../../../kanji/providers/kanji_progress_providers.dart';
import '../../../../lesson/providers/level_providers.dart';
import '../../../../quiz/providers/listening_dialogue_providers.dart';
import '../../../../vocabulary/providers/vocab_progress_providers.dart';
import '../../../../vocabulary/providers/vocab_review_providers.dart' show isSmartPick;
import '../../providers/jlpt_exam_content_providers.dart';
import '../mini_test_settings_sheet.dart' show MiniTestTimerMode;
import 'mini_test_variant.dart';

/// Cấu hình 1 lượt Mini Test — build ĐỘNG lúc runtime theo lựa chọn người
/// dùng (docs/JLPT_MINI_TEST_DESIGN.md §5, §13). Khác `ExamBlueprint` (Full
/// Exam): KHÔNG đọc/ghi bảng `jlpt_exam_blueprints` — bảng đó là dữ liệu
/// tham chiếu dùng CHUNG nhiều người (không có `user_id`), trong khi mỗi
/// lượt Mini Test phải khác nhau (docs §1 "mỗi đề luôn khác nhau") — nếu
/// ghi vào bảng chung sẽ đụng độ khi 2 người cùng làm Mini Test 1 lúc.
class MiniTestBlueprint {
  const MiniTestBlueprint({
    required this.levelId,
    required this.variant,
    required this.questionCount,
    required this.sources,
    this.timerMode = MiniTestTimerMode.unlimited,
  });

  final String levelId;
  final MiniTestVariant variant;
  final int questionCount;

  /// 'vocabulary' | 'grammar' | 'kanji' | 'reading' | 'listening' — Đọc
  /// hiểu/Nghe hiểu chỉ mở cho Daily/Weak Point Mini (2026-08-06), Quick 5
  /// vẫn giữ nguyên 2 nguồn cố định để "bấm là chạy ngay" (xem
  /// `mini_test_settings_sheet.dart`, docs §4).
  final List<String> sources;

  /// docs §4 — "Theo giờ JLPT" ước lượng phút theo tỉ lệ số câu đã chọn so
  /// với Official Timing của Full Exam cùng level (xem
  /// `_resolveTimerMinutes`), "Không giới hạn" là mặc định.
  final MiniTestTimerMode timerMode;

  /// Giá trị lưu vào cột `mode` của `jlpt_exam_sessions` — CHỈ để phân loại
  /// thống kê/lịch sử (docs §5), KHÔNG dùng để tra `jlpt_exam_blueprints`
  /// như Full Exam.
  String get sessionMode => 'mini_${variant.name}';
}

const _quizGenerator = QuizGenerator();
const _readingGenerator = ReadingQuestionGenerator();
const _listeningGenerator = DialogueListeningGenerator();

/// Sinh câu hỏi cho 1 section "Tổng hợp" từ NHIỀU loại nguồn cùng lúc, mỗi
/// loại sinh RIÊNG (nhiễu Vocab/Grammar/Kanji chỉ lấy trong cùng loại) rồi
/// mới gộp + xáo lại — tránh nhiễu chéo kiểu 1 câu hỏi Từ vựng bị chọn nhầm
/// nguyên câu giải thích Ngữ pháp làm đáp án nhiễu (phát hiện thật khi test
/// Weak Point Mini 2026-08-06, đáp án C của câu hỏi 子 là 1 câu giải thích
/// ngữ pháp). [extraQuestionSets] chứa câu Đọc hiểu/Nghe hiểu đã sinh sẵn
/// (khác cơ chế `QuizGenerator.generate(pool:)` — dùng
/// `ReadingQuestionGenerator`/`DialogueListeningGenerator` riêng, xem
/// `_buildReadingListeningQuestionSets`), gộp thẳng vào không qua pool. Mỗi
/// loại xin đủ `questionCount` câu (dư ra để xáo ngẫu nhiên tỉ lệ các
/// loại), rồi cắt về đúng `questionCount` sau khi gộp.
List<QuizQuestion> _generateMixedQuestions(
  Map<String, List<LessonContentItem>> poolsByType,
  List<List<QuizQuestion>> extraQuestionSets,
  int questionCount,
) {
  final combined = <QuizQuestion>[];
  for (final typePool in poolsByType.values) {
    if (typePool.isEmpty) continue;
    combined.addAll(
      _quizGenerator.generate(pool: typePool, questionCount: questionCount),
    );
  }
  for (final extra in extraQuestionSets) {
    combined.addAll(extra);
  }
  combined.shuffle(Random());
  return combined.take(questionCount).toList();
}

/// Sinh câu Đọc hiểu/Nghe hiểu nếu người dùng chọn (docs §2/§4, mở rộng
/// 2026-08-06) — tái dùng nguyên `ReadingQuestionGenerator`/
/// `DialogueListeningGenerator` + provider nội dung đã có ở Full Exam
/// (`jlpt_exam_content_providers.dart`/`listening_dialogue_providers.dart`),
/// KHÔNG viết generator mới. Mỗi danh sách trả về rỗng nếu chưa có nội dung
/// cho level đó — [ExamRunSection] rỗng ở nguồn này không chặn các nguồn
/// khác vẫn có câu.
Future<List<List<QuizQuestion>>> _buildReadingListeningQuestionSets(
  WidgetRef ref,
  MiniTestBlueprint blueprint,
) async {
  final extra = <List<QuizQuestion>>[];
  if (blueprint.sources.contains('reading')) {
    final passages = await ref.read(
      examReadingPassagesForLevelProvider(blueprint.levelId).future,
    );
    if (passages.isNotEmpty) {
      extra.add(
        _readingGenerator.generate(
          passages: passages,
          questionCount: blueprint.questionCount,
        ),
      );
    }
  }
  if (blueprint.sources.contains('listening')) {
    final dialogues = await ref.read(
      listeningDialoguesForLevelProvider(blueprint.levelId).future,
    );
    if (dialogues.isNotEmpty) {
      extra.add(
        _listeningGenerator.generate(
          dialogues: dialogues,
          questionCount: blueprint.questionCount,
        ),
      );
    }
  }
  return extra;
}

/// Sinh câu hỏi 1 LẦN cho 1 lượt Mini Test — tái dùng nguyên `QuizGenerator`
/// + provider nội dung đã có ở `jlpt_exam_content_providers.dart`
/// (`examVocabularyForLevelProvider`/`examGrammarForLevelProvider`), không
/// viết generator mới (docs/JLPT_MINI_TEST_DESIGN.md §6). Trả về đúng kiểu
/// `ExamRunSection` mà `ExamRunnerScreen` đã hiểu, để màn thi dùng lại
/// nguyên vẹn — xem docs §7.
Future<List<ExamRunSection>> buildMiniTestRunSections(
  WidgetRef ref,
  MiniTestBlueprint blueprint,
) async {
  final poolsByType = <String, List<LessonContentItem>>{};
  if (blueprint.sources.contains('vocabulary')) {
    final vocab = await ref.read(
      examVocabularyForLevelProvider(blueprint.levelId).future,
    );
    poolsByType['vocabulary'] = [
      for (final v in vocab) LessonContentItem.vocabulary(v),
    ];
  }
  if (blueprint.sources.contains('grammar')) {
    final grammar = await ref.read(
      examGrammarForLevelProvider(blueprint.levelId).future,
    );
    poolsByType['grammar'] = [
      for (final g in grammar) LessonContentItem.grammar(g),
    ];
  }
  if (blueprint.sources.contains('kanji')) {
    final kanji =
        await ref.read(examKanjiForLevelProvider(blueprint.levelId).future);
    poolsByType['kanji'] = [
      for (final k in kanji) LessonContentItem.kanji(k),
    ];
  }

  final extraQuestionSets = await _buildReadingListeningQuestionSets(ref, blueprint);

  if (poolsByType.values.every((p) => p.isEmpty) &&
      extraQuestionSets.every((e) => e.isEmpty)) {
    return const [];
  }

  final timeMinutes = await _resolveTimerMinutes(ref, blueprint);
  return [
    ExamRunSection(
      type: 'mixed',
      timeMinutes: timeMinutes,
      questions: _generateMixedQuestions(
        poolsByType,
        extraQuestionSets,
        blueprint.questionCount,
      ),
    ),
  ];
}

/// Ngưỡng tối thiểu số mục "đang yếu" (đã chốt 2026-08-06, docs §21/§22) —
/// dưới ngưỡng này không đủ dữ liệu để ra 1 đề riêng, fallback về ngẫu
/// nhiên như Quick 5/Daily ([buildMiniTestRunSections]).
const weakPointMiniTestThreshold = 5;

/// Sinh câu hỏi cho biến thể **Weak Point Mini** (docs §21/§22, Task 8) —
/// chỉ lấy các mục thoả [isSmartPick] (đến hạn HOẶC ease factor thấp, đã ôn
/// ít nhất 1 lần), tái dùng nguyên logic "AI chọn thay bạn" của Smart
/// Review/"Thử thách điểm yếu" (`vocab_review_providers.dart`,
/// `mixed_quiz_providers.dart`), KHÔNG tự đặt công thức chọn điểm yếu mới.
/// Nếu số mục yếu < [weakPointMiniTestThreshold], trả `usedFallback: true`
/// và tự chuyển sang đề ngẫu nhiên qua [buildMiniTestRunSections] — UI cần
/// hiện thông báo rõ cho người dùng thay vì âm thầm.
Future<({List<ExamRunSection> sections, bool usedFallback})>
    buildWeakPointMiniTestRunSections(
  WidgetRef ref,
  MiniTestBlueprint blueprint,
) async {
  final poolsByType = <String, List<LessonContentItem>>{};

  if (blueprint.sources.contains('vocabulary')) {
    final vocab = await ref.read(
      examVocabularyForLevelProvider(blueprint.levelId).future,
    );
    final progress = await ref.read(vocabProgressProvider.future);
    poolsByType['vocabulary'] = [
      for (final v in vocab)
        if (progress[v.id] case final p?)
          if (isSmartPick(p.reviewCount, p.easeFactor, p.isDueNow))
            LessonContentItem.vocabulary(v),
    ];
  }
  if (blueprint.sources.contains('grammar')) {
    final grammar = await ref.read(
      examGrammarForLevelProvider(blueprint.levelId).future,
    );
    final progress = await ref.read(grammarProgressProvider.future);
    poolsByType['grammar'] = [
      for (final g in grammar)
        if (progress[g.id] case final p?)
          if (isSmartPick(p.reviewCount, p.easeFactor, p.isDueNow))
            LessonContentItem.grammar(g),
    ];
  }
  if (blueprint.sources.contains('kanji')) {
    final kanji =
        await ref.read(examKanjiForLevelProvider(blueprint.levelId).future);
    final progress = await ref.read(kanjiProgressProvider.future);
    poolsByType['kanji'] = [
      for (final k in kanji)
        if (progress[k.id] case final p?)
          if (isSmartPick(p.reviewCount, p.easeFactor, p.isDueNow))
            LessonContentItem.kanji(k),
    ];
  }

  final weakCount = poolsByType.values.fold(0, (a, p) => a + p.length);
  if (weakCount < weakPointMiniTestThreshold) {
    final fallbackSections = await buildMiniTestRunSections(ref, blueprint);
    return (sections: fallbackSections, usedFallback: true);
  }

  // Đọc hiểu/Nghe hiểu: KHÔNG có dữ liệu SRS/progress theo từng đoạn văn/
  // hội thoại (chỉ dùng trong Mock Exam, không thuộc Review Module) nên
  // không áp được `isSmartPick()` — thêm NGẪU NHIÊN nếu người dùng chọn,
  // không tính vào `weakCount`/ngưỡng fallback ở trên (docs §21 "áp dụng
  // Reading/Listening theo dimension" vẫn để mở rộng, cần nguồn progress
  // riêng chưa có — không tự bịa công thức yếu điểm cho 2 loại này).
  final extraQuestionSets = await _buildReadingListeningQuestionSets(ref, blueprint);

  final timeMinutes = await _resolveTimerMinutes(ref, blueprint);
  return (
    sections: [
      ExamRunSection(
        type: 'mixed',
        timeMinutes: timeMinutes,
        questions: _generateMixedQuestions(
          poolsByType,
          extraQuestionSets,
          blueprint.questionCount,
        ),
      ),
    ],
    usedFallback: false,
  );
}

/// "Theo giờ JLPT" (docs §4) — ước lượng phút cho Mini Test theo tỉ lệ số
/// câu đã chọn so với Official Timing thật của Full Exam cùng level: lấy
/// `officialTimingMinutesBySectionType` áp cho các section Full Exam để có
/// tổng phút + tổng câu CHÍNH THỨC, rồi chia đều theo phút/câu cho số câu
/// Mini Test đã chọn. Trả 0 ("không giới hạn") nếu chưa xác định được level
/// hoặc chưa có blueprint Full Exam cho level đó — không tự bịa số phút.
Future<int> _resolveTimerMinutes(
  WidgetRef ref,
  MiniTestBlueprint blueprint,
) async {
  if (blueprint.timerMode == MiniTestTimerMode.unlimited) return 0;

  final levels = await ref.read(jlptLevelsProvider.future);
  String? levelCode;
  for (final l in levels) {
    if (l.id == blueprint.levelId) {
      levelCode = l.code;
      break;
    }
  }
  if (levelCode == null) return 0;

  final fullExamBlueprint = await ref.read(
    examBlueprintProvider((levelId: blueprint.levelId, mode: 'full_exam'))
        .future,
  );
  if (fullExamBlueprint == null || fullExamBlueprint.sections.isEmpty) {
    return 0;
  }

  final officialMinutes = officialTimingMinutesBySectionType(
    levelCode: levelCode,
    sections: fullExamBlueprint.sections,
  );
  if (officialMinutes == null) return 0;

  final totalMinutes = officialMinutes.values.fold(0, (a, b) => a + b);
  final totalQuestions =
      fullExamBlueprint.sections.fold(0, (a, s) => a + s.questionCount);
  if (totalQuestions == 0) return 0;

  final minutes = (totalMinutes / totalQuestions * blueprint.questionCount)
      .round();
  return minutes < 1 ? 1 : minutes;
}
