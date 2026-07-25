/// Nhân vật AI để trò chuyện cùng (giáo viên, bạn cùng lớp, sếp...).
class KaiwaPersona {
  const KaiwaPersona({
    required this.id,
    required this.name,
    required this.glyph,
    required this.role,
    required this.gender,
    required this.personality,
    required this.politenessLevel,
    required this.description,
    required this.orderIndex,
    required this.voiceStyle,
  });

  final String id;
  final String name;
  final String glyph;
  final String role;
  final String gender;
  final String personality;
  final String politenessLevel;
  final String description;
  final int orderIndex;

  /// Khoá cấu hình pitch/tốc độ đọc TTS — xem `_voiceProfiles` trong
  /// kaiwa_chat_screen.dart để mỗi nhân vật nghe khác nhau dù dùng chung
  /// 1 giọng engine của máy.
  final String voiceStyle;
}
