import 'dart:math';

import 'package:flutter/foundation.dart' show setEquals;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/entities/grammar_point.dart';
import '../../../domain/entities/lesson.dart';
import '../../../domain/services/quiz_generator.dart';
import '../../grammar/providers/grammar_progress_providers.dart';
import '../../kaiwa/providers/kaiwa_review_providers.dart';
import '../../kanji/providers/kanji_progress_providers.dart';
import '../../lesson/providers/content_providers.dart';
import '../../vocabulary/providers/vocab_progress_providers.dart';
import '../../vocabulary/providers/vocab_review_providers.dart' show isSmartPick;
import 'review_mistakes_providers.dart';

const _quizGenerator = QuizGenerator();

/// 1 nhóm sinh câu hỏi trong Quiz tổng hợp — dùng để bật/tắt riêng từng
/// nhóm ở Quiz Tuỳ chỉnh (Task 7, xem `ReviewMixedQuizCustomScreen`). Gộp cả
/// 2 nguồn Error Correction (Sổ tay lỗi + AI Kaiwa) thành 1 lựa chọn vì với
/// người dùng đây là cùng 1 khái niệm "Sửa lỗi", chỉ khác nguồn dữ liệu nền.
enum MixedQuizSource {
  multipleChoice,
  fillBlank,
  typing,
  translation,
  sentenceOrdering,
  grammarSelection,
  particleSelection,
  errorCorrection,
  conversationCompletion,
}

/// Cấu hình 1 phiên Quiz Tuỳ chỉnh — [enabledSources] mặc định bật hết
/// (giống hành vi [mixedQuizQuestionsProvider] cũ khi không tuỳ chỉnh gì).
/// Cần `==`/`hashCode` thủ công (so nội dung [enabledSources], không phải
/// định danh Set) để Riverpod `family` nhận diện đúng 2 config giống hệt
/// nhau là cùng 1 key, tránh sinh lại provider không cần thiết.
class MixedQuizConfig {
  const MixedQuizConfig({
    required this.questionCount,
    this.enabledSources = const {...MixedQuizSource.values},
    this.timedMode = false,
    this.survivalMode = false,
  });

  final int questionCount;
  final Set<MixedQuizSource> enabledSources;
  final bool timedMode;
  final bool survivalMode;

  @override
  bool operator ==(Object other) =>
      other is MixedQuizConfig &&
      other.questionCount == questionCount &&
      other.timedMode == timedMode &&
      other.survivalMode == survivalMode &&
      setEquals(other.enabledSources, enabledSources);

  @override
  int get hashCode => Object.hash(
        questionCount,
        timedMode,
        survivalMode,
        Object.hashAllUnordered(enabledSources),
      );
}

/// true khi [g] có đủ dữ liệu soạn sẵn cho câu hỏi Điền từ (xem
/// `QuizGenerator.generateGrammarFillBlank`) — dùng để tách nhóm ngữ pháp
/// này khỏi nhóm chỉ đủ cho câu hỏi nghĩa thông thường, tránh 1 mẫu ngữ
/// pháp xuất hiện 2 lần (vừa câu nghĩa vừa câu điền từ) trong cùng 1 bài.
bool _hasFillBlankData(GrammarPoint g) =>
    g.practiceBlankIndex != null &&
    g.practiceBlankIndex! >= 0 &&
    g.practiceBlankIndex! < g.practiceTokens.length;

/// Số mục Từ vựng/Kanji/Ngữ pháp ĐÃ HỌC (có bản ghi progress thật) ở cấp độ
/// hiện tại — dùng để hiện số liệu thật ở `ReviewMixedQuizScreen` và quyết
/// định trạng thái rỗng, tách khỏi [mixedQuizQuestionsProvider] để màn chọn
/// số câu không phải tính lại câu hỏi chỉ để đếm.
final mixedQuizStudiedCountProvider = Provider.autoDispose<int>((ref) {
  final vocab = ref.watch(vocabularyListProvider).valueOrNull ?? const [];
  final kanji = ref.watch(kanjiListProvider).valueOrNull ?? const [];
  final grammar = ref.watch(grammarListProvider).valueOrNull ?? const [];
  final vocabProgress =
      ref.watch(vocabProgressProvider).valueOrNull ?? const {};
  final kanjiProgress =
      ref.watch(kanjiProgressProvider).valueOrNull ?? const {};
  final grammarProgress =
      ref.watch(grammarProgressProvider).valueOrNull ?? const {};

  return vocab.where((v) => vocabProgress.containsKey(v.id)).length +
      kanji.where((k) => kanjiProgress.containsKey(k.id)).length +
      grammar.where((g) => grammarProgress.containsKey(g.id)).length;
});

/// Quiz tổng hợp — trộn Từ vựng + Kanji + Ngữ pháp ĐÃ HỌC (có progress thật)
/// ở cấp độ hiện tại thành 1 bài trắc nghiệm, khác
/// `levelCategoryQuizQuestionsProvider` (dùng toàn bộ nội dung cấp độ, không
/// tách đã học hay chưa, và chỉ 1 mảng/lần). Nhiễu (`distractorPool`) lấy từ
/// toàn bộ nội dung cấp độ đang học, không giới hạn "đã học", để có đủ lựa
/// chọn sai đa dạng — vẫn không trộn cấp độ khác. Câu hỏi nghĩa/chữ/cách đọc
/// dùng lại nguyên `QuizGenerator.generate`; ngữ pháp có sẵn
/// `practiceTokens`/`practiceBlankIndex` được tách riêng để sinh thêm câu
/// Điền từ (`QuizGenerator.generateGrammarFillBlank`, Task 2). Task 3 thêm 2
/// nhóm câu hỏi gõ đáp án: Typing (`generateTyping` — Từ vựng/Kanji, gõ cách
/// đọc) và Translation (`generateTranslation` — Từ vựng gõ nghĩa, Ngữ pháp gõ
/// bản dịch `exampleVi`). Task 4 thêm 3 nhóm câu hỏi Ngữ pháp nữa:
/// Sentence Ordering (`generateSentenceOrdering` — ghép tile `practiceTokens`
/// đúng thứ tự, hiện gợi ý nghĩa bằng `exampleVi`), Grammar Selection
/// (`generateGrammarSelection` — hiện `exampleJp`, chọn đúng `title` minh
/// hoạ), Particle Selection (`generateParticleSelection` — điền đúng trợ từ
/// thật tách từ `practiceTokens`). Task 5 thêm Error Correction từ 2 nguồn:
/// `generateErrorCorrectionFromMistakes` (Sổ tay lỗi —
/// `reviewMistakesProvider`, `originalAnswer`→`correctAnswer` thật) và
/// `generateErrorCorrectionFromKaiwa` (AI Kaiwa History —
/// `kaiwaReviewableMessagesProvider`, `contentJp`→`betterPhrasing` thật, chỉ
/// tin nhắn `isReviewable`). Task 6 thêm Conversation Completion
/// (`generateConversationCompletion` — hiện câu người học thật đã nói, chọn
/// đúng câu AI thật trả lời tiếp theo trong cùng hội thoại, dữ liệu gom sẵn
/// bởi `kaiwaConversationTurnsProvider`). Task 7 thêm Quiz Tuỳ chỉnh (chọn
/// bớt [MixedQuizSource], xem [MixedQuizConfig]/`customMixedQuizQuestionsProvider`
/// bên dưới) cùng 2 chế độ chơi mới ở `QuizScreen`: tính giờ toàn bài
/// (`timedMode`) và sinh tồn (`survivalMode`) — 2 cờ này không ảnh hưởng
/// việc sinh câu, chỉ đổi hành vi màn chơi — xem `docs/MIXED_QUIZ_DESIGN.md`.
/// Cả 10 nhóm câu hỏi được trộn ngẫu nhiên chung 1 danh sách rồi cắt còn đúng
/// [questionCount] — 1 mục có thể xuất hiện ở nhiều dạng câu hỏi khác nhau
/// trong cùng 1 bài (khác góc luyện: nghĩa/chữ/cách đọc/gõ/ghép câu/chọn
/// mẫu/chọn trợ từ), không coi là trùng lặp cần loại trừ. Giao diện dùng lại
/// nguyên `QuizScreen` — câu Điền từ/Grammar Selection/Particle Selection vẫn
/// là 1 `QuizQuestion` trắc nghiệm bình thường; câu gõ đáp án dùng
/// `typedAnswerMode`/`typedAcceptedAnswers`; câu Sentence Ordering dùng
/// `orderTiles`/`orderCorrectSequence` — `QuizScreen` tự chuyển UI theo field
/// nào khác null.
///
/// `autoDispose` — mỗi lần vào sinh lại bộ câu hỏi mới, không cache thứ tự
/// cũ (xem giải thích ở `lessonQuizQuestionsProvider` trong `quiz_providers.dart`).
///
/// Chế độ Quick (5/10/20/50, `ReviewMixedQuizScreen`) — luôn bật đủ mọi nhóm
/// câu hỏi. Quiz Tuỳ chỉnh (Task 7) dùng [customMixedQuizQuestionsProvider]
/// bên dưới, cùng chung logic sinh câu qua [_buildMixedQuizQuestions] nhưng
/// cho chọn bớt nhóm.
final mixedQuizQuestionsProvider =
    Provider.autoDispose.family<List<QuizQuestion>, int>((ref, questionCount) {
  return _buildMixedQuizQuestions(
    ref,
    questionCount,
    MixedQuizSource.values.toSet(),
  );
});

/// Quiz Tuỳ chỉnh — như [mixedQuizQuestionsProvider] nhưng cho chọn bớt
/// nhóm câu hỏi qua [MixedQuizConfig.enabledSources] (xem
/// `ReviewMixedQuizCustomScreen`). Chế độ tính giờ toàn bài/sinh tồn
/// (`timedMode`/`survivalMode`) không ảnh hưởng việc SINH câu — 2 cờ đó chỉ
/// đổi hành vi UI ở `QuizScreen`, đọc trực tiếp từ [MixedQuizConfig] ở
/// route, không cần đi qua provider này.
final customMixedQuizQuestionsProvider = Provider.autoDispose
    .family<List<QuizQuestion>, MixedQuizConfig>((ref, config) {
  return _buildMixedQuizQuestions(
    ref,
    config.questionCount,
    config.enabledSources,
  );
});

/// "Thử thách điểm yếu" (Task 8) — như [mixedQuizQuestionsProvider] (bật đủ
/// mọi nhóm câu hỏi) nhưng chỉ lấy Từ vựng/Kanji/Ngữ pháp [isSmartPick] thật
/// (đến hạn HOẶC đang yếu) làm nguồn, tái dùng nguyên logic "AI chọn thay
/// bạn" của Smart Review (`review_smart_screen.dart`) qua
/// `weakPointOnly: true` — không tự đặt công thức chọn mục yếu mới.
final weakPointMixedQuizQuestionsProvider =
    Provider.autoDispose.family<List<QuizQuestion>, int>((ref, questionCount) {
  return _buildMixedQuizQuestions(
    ref,
    questionCount,
    MixedQuizSource.values.toSet(),
    weakPointOnly: true,
  );
});

/// Số mục yếu/đến hạn thật ([isSmartPick]) ở cấp độ hiện tại — dùng cho
/// trạng thái rỗng/hiện số liệu ở entry point "Thử thách điểm yếu", song
/// song [mixedQuizStudiedCountProvider] (đếm riêng, không sinh câu hỏi).
final weakPointMixedQuizAvailableCountProvider =
    Provider.autoDispose<int>((ref) {
  final vocab = ref.watch(vocabularyListProvider).valueOrNull ?? const [];
  final kanji = ref.watch(kanjiListProvider).valueOrNull ?? const [];
  final grammar = ref.watch(grammarListProvider).valueOrNull ?? const [];
  final vocabProgress =
      ref.watch(vocabProgressProvider).valueOrNull ?? const {};
  final kanjiProgress =
      ref.watch(kanjiProgressProvider).valueOrNull ?? const {};
  final grammarProgress =
      ref.watch(grammarProgressProvider).valueOrNull ?? const {};

  return vocab.where((v) {
        final p = vocabProgress[v.id];
        return p != null && isSmartPick(p.reviewCount, p.easeFactor, p.isDueNow);
      }).length +
      kanji.where((k) {
        final p = kanjiProgress[k.id];
        return p != null && isSmartPick(p.reviewCount, p.easeFactor, p.isDueNow);
      }).length +
      grammar.where((g) {
        final p = grammarProgress[g.id];
        return p != null && isSmartPick(p.reviewCount, p.easeFactor, p.isDueNow);
      }).length;
});

List<QuizQuestion> _buildMixedQuizQuestions(
  Ref ref,
  int questionCount,
  Set<MixedQuizSource> enabledSources, {
  bool weakPointOnly = false,
}) {
  final vocab = ref.watch(vocabularyListProvider).valueOrNull ?? const [];
  final kanji = ref.watch(kanjiListProvider).valueOrNull ?? const [];
  final grammar = ref.watch(grammarListProvider).valueOrNull ?? const [];
  final vocabProgress =
      ref.watch(vocabProgressProvider).valueOrNull ?? const {};
  final kanjiProgress =
      ref.watch(kanjiProgressProvider).valueOrNull ?? const {};
  final grammarProgress =
      ref.watch(grammarProgressProvider).valueOrNull ?? const {};
  final mistakes = ref.watch(reviewMistakesProvider).valueOrNull ?? const [];
  final reviewableKaiwaMessages =
      ref.watch(kaiwaReviewableMessagesProvider).valueOrNull ?? const [];
  final conversationTurns =
      ref.watch(kaiwaConversationTurnsProvider).valueOrNull ?? const [];

  bool vocabEligible(String id) {
    final p = vocabProgress[id];
    if (p == null) return false;
    return !weakPointOnly || isSmartPick(p.reviewCount, p.easeFactor, p.isDueNow);
  }

  bool kanjiEligible(String id) {
    final p = kanjiProgress[id];
    if (p == null) return false;
    return !weakPointOnly || isSmartPick(p.reviewCount, p.easeFactor, p.isDueNow);
  }

  bool grammarEligible(String id) {
    final p = grammarProgress[id];
    if (p == null) return false;
    return !weakPointOnly || isSmartPick(p.reviewCount, p.easeFactor, p.isDueNow);
  }

  final studiedVocab = [for (final v in vocab) if (vocabEligible(v.id)) v];
  final studiedKanji = [for (final k in kanji) if (kanjiEligible(k.id)) k];
  final studiedGrammar = [for (final g in grammar) if (grammarEligible(g.id)) g];
  final fillBlankGrammar = studiedGrammar.where(_hasFillBlankData).toList();

  final studiedPool = [
    for (final v in studiedVocab) LessonContentItem.vocabulary(v),
    for (final k in studiedKanji) LessonContentItem.kanji(k),
    for (final g in studiedGrammar)
      if (!_hasFillBlankData(g)) LessonContentItem.grammar(g),
  ];
  final distractorPool = [
    for (final v in vocab) LessonContentItem.vocabulary(v),
    for (final k in kanji) LessonContentItem.kanji(k),
    for (final g in grammar) LessonContentItem.grammar(g),
  ];
  final typingPool = [
    for (final v in studiedVocab) LessonContentItem.vocabulary(v),
    for (final k in studiedKanji) LessonContentItem.kanji(k),
  ];
  final translationPool = [
    for (final v in studiedVocab) LessonContentItem.vocabulary(v),
    for (final g in studiedGrammar) LessonContentItem.grammar(g),
  ];

  bool on(MixedQuizSource s) => enabledSources.contains(s);

  final questions = [
    if (on(MixedQuizSource.multipleChoice))
      ..._quizGenerator.generate(
        pool: studiedPool,
        distractorPool: distractorPool,
        questionCount: questionCount,
      ),
    if (on(MixedQuizSource.fillBlank))
      ..._quizGenerator.generateGrammarFillBlank(
        pool: fillBlankGrammar,
        questionCount: questionCount,
      ),
    if (on(MixedQuizSource.typing))
      ..._quizGenerator.generateTyping(
        pool: typingPool,
        questionCount: questionCount,
      ),
    if (on(MixedQuizSource.translation))
      ..._quizGenerator.generateTranslation(
        pool: translationPool,
        questionCount: questionCount,
      ),
    if (on(MixedQuizSource.sentenceOrdering))
      ..._quizGenerator.generateSentenceOrdering(
        pool: studiedGrammar,
        questionCount: questionCount,
      ),
    if (on(MixedQuizSource.grammarSelection))
      ..._quizGenerator.generateGrammarSelection(
        pool: studiedGrammar,
        questionCount: questionCount,
      ),
    if (on(MixedQuizSource.particleSelection))
      ..._quizGenerator.generateParticleSelection(
        pool: studiedGrammar,
        questionCount: questionCount,
      ),
    if (on(MixedQuizSource.errorCorrection)) ...[
      ..._quizGenerator.generateErrorCorrectionFromMistakes(
        pool: mistakes,
        questionCount: questionCount,
      ),
      ..._quizGenerator.generateErrorCorrectionFromKaiwa(
        pool: reviewableKaiwaMessages,
        questionCount: questionCount,
      ),
    ],
    if (on(MixedQuizSource.conversationCompletion))
      ..._quizGenerator.generateConversationCompletion(
        pool: conversationTurns,
        questionCount: questionCount,
      ),
  ]..shuffle(Random());

  return questions.take(questionCount).toList();
}
