/// Mức tự chấm sau khi xem lại 1 thẻ — người học tự đánh giá trí nhớ của
/// chính mình, không phải app chấm điểm tự động.
enum SrsGrade { forgot, hard, good }

class SrsScheduleResult {
  const SrsScheduleResult({
    required this.intervalDays,
    required this.easeFactor,
    required this.dueAt,
  });

  final double intervalDays;
  final double easeFactor;
  final DateTime dueAt;
}

const double _minEase = 1.3;
const double _maxEase = 3.0;
const double _defaultEase = 2.5;
const double _maxIntervalDays = 365;

/// SM-2 rút gọn — 3 mức thay vì 4 (không có "Dễ" riêng biệt):
/// - [SrsGrade.forgot]: reset về 1 ngày, ease -0.2.
/// - [SrsGrade.hard]: interval cũ × ease × 0.8 (tối thiểu 1 ngày), ease -0.15.
/// - [SrsGrade.good]: interval cũ × ease (lần đầu = 3 ngày), ease +0.1.
///
/// Ease luôn kẹp trong [1.3, 3.0] — dưới 1.3 khiến interval co lại quá nhanh
/// và không bao giờ hội tụ, đây là ngưỡng chuẩn của thuật toán SM-2 gốc.
SrsScheduleResult computeNextSchedule({
  required double? previousIntervalDays,
  required double? previousEaseFactor,
  required SrsGrade grade,
  DateTime? now,
}) {
  final ease = previousEaseFactor ?? _defaultEase;
  final previousInterval = previousIntervalDays ?? 0;
  final isFirstReview = previousInterval <= 0;

  double nextInterval;
  double nextEase;
  switch (grade) {
    case SrsGrade.forgot:
      nextInterval = 1;
      nextEase = ease - 0.2;
    case SrsGrade.hard:
      nextInterval = isFirstReview ? 1 : previousInterval * ease * 0.8;
      nextEase = ease - 0.15;
    case SrsGrade.good:
      nextInterval = isFirstReview ? 3 : previousInterval * ease;
      nextEase = ease + 0.1;
  }

  nextInterval = nextInterval.clamp(1, _maxIntervalDays);
  nextEase = nextEase.clamp(_minEase, _maxEase);

  final base = now ?? DateTime.now();
  return SrsScheduleResult(
    intervalDays: nextInterval,
    easeFactor: nextEase,
    dueAt: base.add(Duration(minutes: (nextInterval * 24 * 60).round())),
  );
}
