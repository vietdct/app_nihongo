class Profile {
  const Profile({
    required this.displayName,
    required this.xp,
    required this.streakCount,
    this.lastStudyDate,
    this.lastQuizCompletedAt,
    this.missionXpDates = const {},
  });

  final String displayName;
  final int xp;
  final int streakCount;

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
