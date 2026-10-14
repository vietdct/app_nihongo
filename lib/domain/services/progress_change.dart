/// Các mốc streak có hiệu ứng riêng.
const streakMilestones = <int>{3, 7, 30};

/// Chuẩn hoá về ngày (giờ địa phương, 0h) — đúng quy ước của `study_days`
/// (`DateTime.parse('YYYY-MM-DD')`), để so sánh theo GIÁ TRỊ ngày chứ không
/// theo object hay giờ giấc.
Set<DateTime> normalizeStudyDays(Iterable<DateTime> days) =>
    {for (final d in days) DateTime(d.year, d.month, d.day)};

/// Những ngày có trong [next] nhưng chưa có trong [previous]. Ngày bị xoá khỏi
/// [next] không sinh ra gì. Cả hai phải là snapshot thành công đã chuẩn hoá.
Set<DateTime> newStudyDays(Set<DateTime> previous, Set<DateTime> next) =>
    next.difference(previous);

/// Mốc streak (3/7/30) VỪA đạt giữa hai snapshot thành công, hoặc null.
///
/// Chỉ trả mốc khi streak tăng đúng 1 ngày ([previous] + 1 == [next]) và
/// [next] đúng bằng một mốc. Nhảy cóc (6→8, 2→7, 1→30), giữ nguyên, giảm,
/// hoặc chưa có [previous] (baseline) đều không phải "vừa đạt mốc" đáng tin:
/// không suy diễn mốc trung gian chưa từng được snapshot xác nhận.
int? streakMilestoneReached(int? previous, int next) {
  if (previous == null) return null;
  if (next != previous + 1) return null;
  return streakMilestones.contains(next) ? next : null;
}
