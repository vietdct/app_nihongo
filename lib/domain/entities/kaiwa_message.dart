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
    this.suggestedReplyJp,
    this.suggestedReplyVi,
    this.intervalDays = 0,
    this.easeFactor = 2.5,
    this.dueAt,
    this.reviewCount = 0,
  });

  final String id;
  final KaiwaMessageRole role;
  final String contentJp;
  final String? translationVi;
  final String? furigana;
  final KaiwaFeedback? feedback;

  /// Chỉ có ý nghĩa ở message role AI — câu trả lời mẫu AI gợi ý cho người
  /// học dùng để đáp lại [contentJp], xem "Gợi ý trả lời" ở `kaiwa_chat_screen.dart`.
  final String? suggestedReplyJp;
  final String? suggestedReplyVi;

  /// Lịch ôn tập SRS thật (SM-2 rút gọn, xem `srs_scheduler.dart`) — ghi bởi
  /// `KaiwaReviewScreen`, migration `20260728010000_kaiwa_srs.sql`.
  final double intervalDays;
  final double easeFactor;
  final DateTime? dueAt;
  final int reviewCount;

  /// Chỉ những câu THẬT SỰ bị sửa mới đáng ôn tập — feedback có câu tự nhiên
  /// hơn ([KaiwaFeedback.betterPhrasing]) và câu đó khác với câu gốc đã nói.
  /// Không đoán/không ôn những câu AI chấm đã ổn (rating cao, không có sửa).
  bool get isReviewable =>
      feedback != null &&
      feedback!.hasContent &&
      feedback!.betterPhrasing.trim().isNotEmpty &&
      feedback!.betterPhrasing.trim() != contentJp.trim();

  /// true nếu chưa từng ôn theo SRS ([dueAt] null) hoặc đã tới/qua hạn ôn.
  bool get isDueNow => dueAt == null || !dueAt!.isAfter(DateTime.now());
}
