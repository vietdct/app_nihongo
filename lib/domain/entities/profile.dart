class Profile {
  const Profile({
    required this.displayName,
    required this.xp,
    required this.streakCount,
    this.lastStudyDate,
  });

  final String displayName;
  final int xp;
  final int streakCount;

  /// Ngày học gần nhất (cột `last_study_date`) — chỉ dùng để biết "hôm nay đã
  /// học chưa", không phải lịch sử đầy đủ theo ngày.
  final DateTime? lastStudyDate;
}
