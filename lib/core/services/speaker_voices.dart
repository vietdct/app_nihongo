import 'package:flutter/foundation.dart';

import 'jp_voice_prefs.dart';

/// Hồ sơ giọng của 1 nhân vật: chỉ chênh NHẸ cao độ/tốc độ so với giọng gốc —
/// sự khác biệt chính phải đến từ giọng ja-JP thật khác nhau của máy. Không gắn
/// với giới tính hay vai trò dữ liệu; chỉ là 3 "tông" xoay vòng theo thứ tự
/// xuất hiện của nhân vật (A→Natural, B→Calm, C→Bright, D→Natural...).
enum VoiceProfile {
  /// Trung tính, tự nhiên — nhân vật đầu tiên.
  natural(pitch: 1.0, rate: 1.0),

  /// Điềm tĩnh: thấp và chậm hơn nhẹ.
  calm(pitch: 0.96, rate: 0.97),

  /// Sáng, thân thiện: cao và nhanh hơn nhẹ.
  bright(pitch: 1.04, rate: 1.03);

  const VoiceProfile({required this.pitch, required this.rate});

  /// Hệ số cao độ truyền cho `FlutterTts.setPitch` (1.0 = gốc).
  final double pitch;

  /// Hệ số NHÂN vào tốc độ đọc đang chọn (0.75×/1.0×/1.25×...) — đổi tốc độ
  /// chỉ nhân thêm hệ số này, không đụng tới pitch.
  final double rate;

  static VoiceProfile forSlot(int slot) => values[slot % values.length];
}

/// Giọng đọc gán cho 1 nhân vật: [voice] là 1 giọng ja-JP thật của máy (null
/// nếu máy không liệt kê giọng nào → dùng giọng mặc định), [profile] là tông
/// giọng nhẹ đi kèm.
@immutable
class SpeakerVoice {
  const SpeakerVoice({
    required this.voice,
    this.profile = VoiceProfile.natural,
    this.spread = 1.0,
  });

  final Map<String, String>? voice;
  final VoiceProfile profile;

  /// Hệ số khuếch đại độ chênh pitch/rate của profile: 1.0 khi nhân vật có giọng
  /// thật riêng; [sharedVoiceSpread] khi phải dùng chung 1 giọng với nhân vật
  /// khác (máy thiếu giọng) — chỉ pitch/rate mới tách được các nhân vật.
  final double spread;

  String? get voiceName => voice?['name'];
  double get pitch => 1.0 + (profile.pitch - 1.0) * spread;

  /// Hệ số nhân tốc độ của profile (xem [VoiceProfile.rate]).
  double get rateFactor => 1.0 + (profile.rate - 1.0) * spread;
}

bool? _isFemale(Map<String, String> v) {
  final gender = (v['gender'] ?? '').toLowerCase();
  if (gender.contains('female')) return true;
  if (gender.contains('male')) return false;
  final name = (v['name'] ?? '').toLowerCase();
  const female = ['kyoko', 'o-ren', 'oren', 'sakura', 'haruka', 'nanami'];
  const male = ['otoya', 'hattori', 'ichiro', 'keita', 'takumi'];
  if (female.any(name.contains)) return true;
  if (male.any(name.contains)) return false;
  return null;
}

/// Chọn giọng máy đúng giới tính theo khoá `voice_style` của persona
/// (`male_*`/`female_*`), ưu tiên giọng chất lượng cao nhất. Null nếu máy
/// không có giọng đúng giới → dùng giọng mặc định, chỉ khác pitch/tốc độ.
Map<String, String>? pickVoiceForStyle(
  List<Map<String, String>> voices,
  String style,
) {
  final wantFemale = style.startsWith('female')
      ? true
      : style.startsWith('male')
          ? false
          : null;
  if (wantFemale == null) return null;
  final match = voices.where((v) => _isFemale(v) == wantFemale).toList();
  if (match.isEmpty) return null;
  match.sort((a, b) => voiceQualityRank(b).compareTo(voiceQualityRank(a)));
  return match.first;
}

/// Xếp các giọng ja-JP theo thứ tự ưu tiên gán cho nhân vật 1, 2, 3...: giọng
/// người dùng đã chọn (hoặc giọng nữ đầu tiên) đứng đầu, sau đó xen kẽ giới
/// tính để 2 nhân vật liền nhau luôn khác giọng rõ nhất có thể.
@visibleForTesting
List<Map<String, String>> orderVoices(
  List<Map<String, String>> voices,
  Map<String, String>? saved,
) {
  if (voices.isEmpty) return const [];
  // Chất lượng trước (premium/enhanced nghe tự nhiên hơn), trong cùng hạng cao
  // nhất ưu tiên giọng nữ đầu tiên.
  final topRank = voices.map(voiceQualityRank).reduce((a, b) => a > b ? a : b);
  final top = voices.where((v) => voiceQualityRank(v) == topRank).toList();
  final first = saved ??
      top.firstWhere(
        (v) => _isFemale(v) == true,
        orElse: () => top.first,
      );
  final rest =
      voices.where((v) => v['name'] != first['name']).toList(growable: true);
  final ordered = [first];
  var wantFemale = _isFemale(first) == null ? null : !_isFemale(first)!;
  while (rest.isNotEmpty) {
    final i = wantFemale == null
        ? 0
        : rest.indexWhere((v) => _isFemale(v) == wantFemale);
    ordered.add(rest.removeAt(i < 0 ? 0 : i));
    if (wantFemale != null) wantFemale = !wantFemale;
  }
  return ordered;
}

/// Độ khuếch đại khi các nhân vật dùng chung 1 giọng (Calm ≈ 0.88/0.91,
/// Bright ≈ 1.12/1.09): đủ nghe ra "người khác" mà chưa thành giọng hoạt hình.
const sharedVoiceSpread = 3.0;

/// Gán giọng cho từng nhân vật (theo thứ tự xuất hiện, ổn định trong cả đoạn
/// hội thoại và khi nghe lại): mỗi nhân vật 1 giọng ja-JP thật khác nhau khi
/// máy đủ giọng, đi kèm [VoiceProfile] xoay vòng Natural→Calm→Bright. Máy ít
/// giọng hơn số nhân vật thì dùng chung giọng nhưng khác profile; không có
/// giọng nào thì voice = null (giọng mặc định, vẫn khác profile).
Map<String, SpeakerVoice> assignSpeakerVoices(
  List<String> speakers,
  List<Map<String, String>> voices,
  Map<String, String>? saved,
) {
  final ordered = orderVoices(voices, saved);
  final n = ordered.length;
  return {
    for (var i = 0; i < speakers.length; i++)
      speakers[i]: SpeakerVoice(
        voice: n == 0 ? null : ordered[i % n],
        profile: VoiceProfile.forSlot(i),
        spread: n > 0 && n < speakers.length ? sharedVoiceSpread : 1.0,
      ),
  };
}
