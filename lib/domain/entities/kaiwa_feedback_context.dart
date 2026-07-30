/// Ngữ cảnh 1 lượt nói + feedback đã chấm — dùng để mở `KaiwaTutorScreen`
/// hỏi sâu thêm về đúng câu đó (xem `kaiwa_tutor_service.dart`).
class KaiwaFeedbackContext {
  const KaiwaFeedbackContext({
    required this.originalSentence,
    required this.betterPhrasing,
    required this.explanation,
    required this.commonMistake,
    required this.grammarNote,
    required this.vocabularyNote,
    required this.politenessNote,
    required this.personaName,
    required this.scenarioTitle,
  });

  final String originalSentence;
  final String? betterPhrasing;
  final String? explanation;
  final String? commonMistake;
  final String? grammarNote;
  final String? vocabularyNote;
  final String? politenessNote;
  final String personaName;
  final String scenarioTitle;
}
