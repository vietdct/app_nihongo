import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../theme/app_theme.dart';

/// Khoá SharedPreferences lưu giọng đọc tiếng Nhật người dùng đã chọn — dùng
/// chung giữa AI Kaiwa và Quiz/Nghe hiểu, chọn 1 lần ở màn nào cũng áp dụng
/// cho màn còn lại vì cùng đọc từ 1 khoá lưu trữ.
const jpVoiceNamePrefKey = 'kaiwa_tts_voice_name';
const jpVoiceLocalePrefKey = 'kaiwa_tts_voice_locale';

/// Khoá SharedPreferences lưu tốc độ phát âm người dùng chọn (toàn app).
const jpSpeechSpeedPrefKey = 'jp_tts_speed';

/// Tốc độ "thường" trên thang engine của flutter_tts (0–1): 0.5 là tốc độ
/// mặc định tự nhiên của iOS/Android — 1.0× của app = đúng giá trị này. Chậm
/// hơn (VD 0.45 như trước) làm giọng đọc nghe đều đều, thiếu nhịp.
const double kTtsNormalRate = 0.5;

/// Tốc độ phát âm theo bội số so với tốc độ thường. [ttsRate] là giá trị
/// truyền cho `FlutterTts.setSpeechRate` (thang 0–1 của engine, không phải
/// bội số) — nơi duy nhất map bội số → tham số engine.
enum AudioPlaybackSpeed {
  x050(0.5, '0.5×'),
  x075(0.75, '0.75×'),
  x100(1.0, '1.0×'),
  x125(1.25, '1.25×'),
  x150(1.5, '1.5×');

  const AudioPlaybackSpeed(this.multiplier, this.label);

  final double multiplier;
  final String label;

  double get ttsRate => (kTtsNormalRate * multiplier).clamp(0.1, 1.0);
}

Future<AudioPlaybackSpeed> loadJpSpeechSpeed() async {
  final prefs = await SharedPreferences.getInstance();
  final saved = prefs.getDouble(jpSpeechSpeedPrefKey);
  return AudioPlaybackSpeed.values.firstWhere(
    (s) => s.multiplier == saved,
    orElse: () => AudioPlaybackSpeed.x100,
  );
}

Future<void> saveJpSpeechSpeed(AudioPlaybackSpeed speed) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setDouble(jpSpeechSpeedPrefKey, speed.multiplier);
}

/// Xếp hạng chất lượng giọng: premium/enhanced (iOS) hoặc quality số cao
/// (Android) nghe tự nhiên hơn hẳn giọng "default/compact" nén nhỏ.
int voiceQualityRank(Map<String, String> v) {
  final q = (v['quality'] ?? '').toLowerCase();
  if (q.contains('premium')) return 3;
  if (q.contains('enhanced')) return 2;
  final n = int.tryParse(q);
  if (n != null) return n >= 500 ? 3 : (n >= 400 ? 2 : 0);
  return 0;
}

/// Giọng ja-* của máy, giọng chất lượng cao nhất đứng đầu (cùng hạng xếp theo tên).
Future<List<Map<String, String>>> loadJapaneseVoices(FlutterTts tts) async {
  final raw = await tts.getVoices as List<dynamic>? ?? const [];
  return raw
      .map((v) => Map<String, String>.from(v as Map))
      .where((v) => (v['locale'] ?? '').toLowerCase().startsWith('ja'))
      .toList()
    ..sort((a, b) {
      final byQuality = voiceQualityRank(b).compareTo(voiceQualityRank(a));
      return byQuality != 0
          ? byQuality
          : (a['name'] ?? '').compareTo(b['name'] ?? '');
    });
}

/// Khởi tạo chung cho mọi nơi đọc tiếng Nhật 1 giọng (nút loa từ vựng/kanji,
/// câu quiz, đề thi): ngôn ngữ, âm lượng, pitch gốc, chờ đọc xong, audio
/// category iOS, tốc độ đã lưu, và giọng = giọng người dùng đã chọn, nếu chưa
/// chọn thì giọng chất lượng cao nhất của máy. Trả về danh sách giọng + giọng
/// người dùng đã lưu (null nếu đang tự chọn) để UI picker dùng tiếp.
Future<({List<Map<String, String>> voices, Map<String, String>? saved})>
    configureJpTts(FlutterTts tts) async {
  await tts.setLanguage('ja-JP');
  await tts.setVolume(1.0);
  await tts.setPitch(1.0);
  await tts.awaitSpeakCompletion(true);
  await applyIosTtsPlaybackCategory(tts);
  await tts.setSpeechRate((await loadJpSpeechSpeed()).ttsRate);
  final voices = await loadJapaneseVoices(tts);
  final saved = await loadSavedJpVoice(voices);
  final chosen = saved ?? (voices.isEmpty ? null : voices.first);
  if (chosen != null) await tts.setVoice(chosen);
  return (voices: voices, saved: saved);
}

/// Chữ cái Latin đơn lẻ đứng trước "さん" (placeholder tên nhân vật kiểu
/// "Aさん") hay bị TTS tiếng Nhật lướt qua — đổi sang cách đọc katakana.
const _latinLetterKana = {
  'A': 'エー', 'B': 'ビー', 'C': 'シー', 'D': 'ディー', 'E': 'イー',
  'F': 'エフ', 'G': 'ジー', 'H': 'エイチ', 'I': 'アイ', 'J': 'ジェー',
  'K': 'ケー', 'L': 'エル', 'M': 'エム', 'N': 'エヌ', 'O': 'オー',
  'P': 'ピー', 'Q': 'キュー', 'R': 'アール', 'S': 'エス', 'T': 'ティー',
  'U': 'ユー', 'V': 'ブイ', 'W': 'ダブリュー', 'X': 'エックス',
  'Y': 'ワイ', 'Z': 'ゼット',
};
final _latinLetterBeforeSan = RegExp(r'(?<![A-Za-z])([A-Z])(?=さん)');

/// Chuẩn hoá chữ trước khi đưa cho TTS để ngắt nghỉ tự nhiên hơn: bỏ dấu "〜"
/// mở đầu mẫu ngữ pháp (engine hay đọc thành ký hiệu), "…" thành quãng nghỉ,
/// gộp khoảng trắng thừa, và đọc chữ Latin trước "さん" bằng katakana.
String prepareJpForSpeech(String text) {
  var t = text.replaceAllMapped(
    _latinLetterBeforeSan,
    (m) => _latinLetterKana[m[1]] ?? m[1]!,
  );
  t = t
      .replaceAll(RegExp(r'^[〜～~]+'), '')
      .replaceAll(RegExp(r'[〜～~]'), '、')
      .replaceAll(RegExp(r'(…+|・{3,}|\.{3,})'), '、')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
  return t;
}

Future<Map<String, String>?> loadSavedJpVoice(
    List<Map<String, String>> voices,) async {
  final prefs = await SharedPreferences.getInstance();
  final savedName = prefs.getString(jpVoiceNamePrefKey);
  if (savedName == null) return null;
  final savedLocale = prefs.getString(jpVoiceLocalePrefKey);
  for (final v in voices) {
    if (v['name'] == savedName && v['locale'] == savedLocale) return v;
  }
  return null;
}

Future<void> saveJpVoice(Map<String, String> voice) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(jpVoiceNamePrefKey, voice['name'] ?? '');
  await prefs.setString(jpVoiceLocalePrefKey, voice['locale'] ?? '');
}

/// Bottom sheet chọn giọng đọc tiếng Nhật trong số giọng máy đã cài — dùng
/// chung giữa AI Kaiwa và Quiz.
void showJpVoicePicker({
  required BuildContext context,
  required List<Map<String, String>> voices,
  required Map<String, String>? selected,
  required ValueChanged<Map<String, String>> onSelected,
  AudioPlaybackSpeed? speed,
  ValueChanged<AudioPlaybackSpeed>? onSpeedChanged,
}) {
  if (voices.isEmpty) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(
          content:
              Text('Không tìm thấy giọng đọc tiếng Nhật nào trên máy.'),),);
    return;
  }
  showModalBottomSheet(
    context: context,
    showDragHandle: true,
    builder: (sheetContext) {
      return SafeArea(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.only(bottom: 12),
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Text('Chọn giọng đọc tiếng Nhật',
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.ink,),),
            ),
            if (speed != null && onSpeedChanged != null)
              JpSpeedChips(selected: speed, onChanged: onSpeedChanged),
            if (voices.isNotEmpty &&
                voices.every((v) => voiceQualityRank(v) == 0))
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 0, 20, 8),
                child: Text(
                  'Máy mới có giọng chuẩn. Để nghe tự nhiên hơn, tải giọng '
                  'Enhanced/Premium tiếng Nhật: Cài đặt › Trợ năng › Nội dung '
                  'được đọc › Giọng nói › Tiếng Nhật.',
                  style: TextStyle(fontSize: 11.5, color: AppColors.inkSoft),
                ),
              ),
            for (final voice in voices)
              RadioListTile<String>(
                value: '${voice['name']}|${voice['locale']}',
                // ignore: deprecated_member_use
                groupValue: selected == null
                    ? null
                    : '${selected['name']}|${selected['locale']}',
                activeColor: AppColors.teal,
                title: Text(voice['name'] ?? '',
                    style: const TextStyle(fontSize: 13.5),),
                subtitle: (voice['quality'] != null || voice['gender'] != null)
                    ? Text(
                        [voice['gender'], voice['quality']]
                            .where((e) => e != null && e.isNotEmpty)
                            .join(' · '),
                        style: const TextStyle(fontSize: 11.5),
                      )
                    : null,
                // ignore: deprecated_member_use
                onChanged: (_) {
                  Navigator.of(sheetContext).pop();
                  onSelected(voice);
                },
              ),
          ],
        ),
      );
    },
  );
}

/// Buộc audio TTS phát ra loa và không bị tắt tiếng bởi nút gạt Silent hay
/// khoá màn hình — mặc định của flutter_tts trên iOS là category
/// `ambientSolo`, bị nút gạt Silent tắt tiếng hoàn toàn, khiến TTS gọi
/// `speak()` thành công nhưng không phát ra âm thanh nào (im lặng).
Future<void> applyIosTtsPlaybackCategory(FlutterTts tts) async {
  try {
    await tts
        .setIosAudioCategory(
          IosTextToSpeechAudioCategory.playback,
          [IosTextToSpeechAudioCategoryOptions.mixWithOthers],
        )
        .timeout(const Duration(seconds: 2));
  } catch (_) {
    // bỏ qua trên Android hoặc nếu native phản hồi chậm — vẫn tiếp tục phát
  }
}


/// Hàng chọn tốc độ đọc (0.5×–1.5×, 1.0× là tốc độ thường) — lưu chung toàn
/// app qua [saveJpSpeechSpeed]; nơi dùng tự áp dụng từ lần đọc kế tiếp.
class JpSpeedChips extends StatefulWidget {
  const JpSpeedChips({super.key, required this.selected, required this.onChanged});

  final AudioPlaybackSpeed selected;
  final ValueChanged<AudioPlaybackSpeed> onChanged;

  @override
  State<JpSpeedChips> createState() => _JpSpeedChipsState();
}

class _JpSpeedChipsState extends State<JpSpeedChips> {
  late AudioPlaybackSpeed _current = widget.selected;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Tốc độ đọc',
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.inkSoft)),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            children: [
              for (final s in AudioPlaybackSpeed.values)
                ChoiceChip(
                  label: Text(s == AudioPlaybackSpeed.x100
                      ? '${s.label} · thường'
                      : s.label),
                  selected: s == _current,
                  showCheckmark: false,
                  onSelected: (_) {
                    setState(() => _current = s);
                    unawaited(saveJpSpeechSpeed(s));
                    widget.onChanged(s);
                  },
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Bottom sheet chỉ chọn tốc độ — dùng khi giữ nút loa (từ vựng/kanji/ngữ pháp).
Future<void> showJpSpeedSheet(BuildContext context) async {
  final current = await loadJpSpeechSpeed();
  if (!context.mounted) return;
  await showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (_) => SafeArea(
      child: JpSpeedChips(selected: current, onChanged: (_) {}),
    ),
  );
}
