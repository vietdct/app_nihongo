/// Tiến độ học 1 từ vựng của người dùng hiện tại.
/// [isKnown]: null = chưa ôn qua flashcard, true = đã thuộc (vuốt phải),
/// false = chưa thuộc (vuốt trái). [intervalDays]/[easeFactor]/[dueAt]/
/// [reviewCount] là dữ liệu SRS thật (SM-2 rút gọn, xem `srs_scheduler.dart`)
/// — ghi bởi pha Review của Lesson Runner, độc lập với [isKnown] (flashcard cũ).
class VocabProgress {
  const VocabProgress({
    required this.vocabId,
    this.isKnown,
    this.starred = false,
    this.updatedAt,
    this.intervalDays = 0,
    this.easeFactor = 2.5,
    this.dueAt,
    this.reviewCount = 0,
  });

  final String vocabId;
  final bool? isKnown;
  final bool starred;
  final DateTime? updatedAt;
  final double intervalDays;
  final double easeFactor;
  final DateTime? dueAt;
  final int reviewCount;

  /// true nếu chưa từng ôn theo SRS ([dueAt] null) hoặc đã tới/qua hạn ôn.
  bool get isDueNow => dueAt == null || !dueAt!.isAfter(DateTime.now());
}
