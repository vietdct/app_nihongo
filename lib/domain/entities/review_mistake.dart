/// 1 lỗi thật đã ghi nhận ở màn Review (Từ vựng/Kanji/Ngữ pháp), nguồn dữ
/// liệu cho Mistake Notebook. Xem bảng `review_mistakes`
/// (`supabase/migrations/20260803090000_review_mistakes.sql`).
class ReviewMistake {
  const ReviewMistake({
    required this.id,
    required this.sourceType,
    required this.sourceId,
    required this.correctAnswer,
    required this.occurrenceCount,
    required this.bookmarked,
    required this.updatedAt,
    this.originalAnswer,
    this.explanation,
    this.note,
  });

  final String id;

  /// 'vocab' | 'kanji' | 'grammar'
  final String sourceType;
  final String sourceId;
  final String? originalAnswer;
  final String correctAnswer;
  final String? explanation;
  final String? note;
  final bool bookmarked;
  final int occurrenceCount;
  final DateTime updatedAt;
}
