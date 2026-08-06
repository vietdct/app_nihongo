class Profile {
  const Profile({
    required this.displayName,
    required this.xp,
    required this.streakCount,
    required this.longestStreakCount,
    required this.createdAt,
    this.country,
    this.lastStudyDate,
    this.lastQuizCompletedAt,
    this.missionXpDates = const {},
  });

  final String displayName;
  final int xp;
  final int streakCount;

  /// Mốc chuỗi ngày cao nhất từng đạt — không giảm khi streak hiện tại bị
  /// reset, dùng để huy hiệu streak là vĩnh viễn (xem AchievementsScreen).
  final int longestStreakCount;

  /// Quốc gia người học tự nhập ở Edit Profile — null nếu chưa từng nhập.
  final String? country;

  /// Mốc tạo tài khoản (cột `created_at` có sẵn từ Pha 1) — dùng hiển thị
  /// "Học từ ngày..." ở Profile Home, không cần bảng/cột riêng.
  final DateTime createdAt;

  /// Ngày học gần nhất (cột `last_study_date`) — chỉ dùng để biết "hôm nay đã
  /// học chưa", không phải lịch sử đầy đủ theo ngày.
  final DateTime? lastStudyDate;

  /// Mốc quiz hoàn thành gần nhất — Quiz không có bảng log buổi làm bài nào
  /// khác, dùng cho mission "Hoàn thành 1 bài Quiz" (xem `daily_mission.dart`).
  final DateTime? lastQuizCompletedAt;

  /// mission key ('vocab'/'kanji'/'quiz'/'kaiwa') → ngày (yyyy-MM-dd) đã
  /// thưởng XP — chặn cộng XP nhiều lần trong cùng 1 ngày.
  final Map<String, String> missionXpDates;
}
