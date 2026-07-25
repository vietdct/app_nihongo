enum KaiwaMessageRole { user, ai }

/// Đánh giá AI chấm cho 1 lượt nói của người học. [rating] == 0 nghĩa là
/// tin nhắn mở đầu hội thoại, chưa có câu để chấm — UI nên ẩn khối feedback.
class KaiwaFeedback {
  const KaiwaFeedback({
    required this.rating,
    required this.naturalness,
    required this.grammar,
    required this.vocabulary,
    required this.politeness,
    required this.nativeLikeness,
    required this.explanation,
    required this.commonMistake,
    required this.betterPhrasing,
  });

  factory KaiwaFeedback.fromJson(Map<String, dynamic> json) => KaiwaFeedback(
        rating: json['rating'] as int? ?? 0,
        naturalness: json['naturalness'] as String? ?? '',
        grammar: json['grammar'] as String? ?? '',
        vocabulary: json['vocabulary'] as String? ?? '',
        politeness: json['politeness'] as String? ?? '',
        nativeLikeness: json['native_likeness'] as String? ?? '',
        explanation: json['explanation'] as String? ?? '',
        commonMistake: json['common_mistake'] as String? ?? '',
        betterPhrasing: json['better_phrasing'] as String? ?? '',
      );

  final int rating;
  final String naturalness;
  final String grammar;
  final String vocabulary;
  final String politeness;
  final String nativeLikeness;
  final String explanation;
  final String commonMistake;
  final String betterPhrasing;

  bool get hasContent => rating > 0;

  Map<String, dynamic> toJson() => {
        'rating': rating,
        'naturalness': naturalness,
        'grammar': grammar,
        'vocabulary': vocabulary,
        'politeness': politeness,
        'native_likeness': nativeLikeness,
        'explanation': explanation,
        'common_mistake': commonMistake,
        'better_phrasing': betterPhrasing,
      };
}

class KaiwaMessage {
  const KaiwaMessage({
    required this.id,
    required this.role,
    required this.contentJp,
    this.translationVi,
    this.furigana,
    this.feedback,
  });

  final String id;
  final KaiwaMessageRole role;
  final String contentJp;
  final String? translationVi;
  final String? furigana;
  final KaiwaFeedback? feedback;
}
