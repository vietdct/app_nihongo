/// Tính chuỗi ngày nói chuyện liên tiếp (speaking streak) từ mốc thời gian
/// hoạt động thật của các phiên Kaiwa (`lastMessageAt` mỗi hội thoại) — không
/// đọc `profiles.streak_count` (đó là streak học tập chung toàn app, không
/// riêng cho Kaiwa).
///
/// Quy tắc chuẩn của streak: còn tính nếu hôm nay CHƯA nói chuyện nhưng hôm
/// qua có (chưa "lỡ" ngày nào) — chỉ về 0 khi có ít nhất 1 ngày trống hoàn
/// toàn giữa hôm nay và lần nói gần nhất.
int computeKaiwaStreak(List<DateTime> activityTimestamps, {DateTime? now}) {
  final today = _dateOnly(now ?? DateTime.now());
  final days = activityTimestamps.map(_dateOnly).toSet();
  if (days.isEmpty) return 0;

  var cursor = today;
  if (!days.contains(cursor)) {
    cursor = cursor.subtract(const Duration(days: 1));
    if (!days.contains(cursor)) return 0;
  }

  var streak = 0;
  while (days.contains(cursor)) {
    streak++;
    cursor = cursor.subtract(const Duration(days: 1));
  }
  return streak;
}

// Supabase trả timestamp dạng UTC — phải quy về giờ địa phương trước khi
// lấy ngày, nếu không hoạt động lúc nửa đêm giờ VN (UTC+7) sẽ bị tính nhầm
// sang "hôm qua" theo lịch UTC.
DateTime _dateOnly(DateTime dt) {
  final local = dt.toLocal();
  return DateTime(local.year, local.month, local.day);
}
