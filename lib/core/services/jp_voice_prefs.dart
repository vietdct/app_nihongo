import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../theme/app_theme.dart';

/// Khoá SharedPreferences lưu giọng đọc tiếng Nhật người dùng đã chọn — dùng
/// chung giữa AI Kaiwa và Quiz/Nghe hiểu, chọn 1 lần ở màn nào cũng áp dụng
/// cho màn còn lại vì cùng đọc từ 1 khoá lưu trữ.
const jpVoiceNamePrefKey = 'kaiwa_tts_voice_name';
const jpVoiceLocalePrefKey = 'kaiwa_tts_voice_locale';

Future<List<Map<String, String>>> loadJapaneseVoices(FlutterTts tts) async {
  final raw = await tts.getVoices as List<dynamic>? ?? const [];
  return raw
      .map((v) => Map<String, String>.from(v as Map))
      .where((v) => (v['locale'] ?? '').toLowerCase().startsWith('ja'))
      .toList()
    ..sort((a, b) => (a['name'] ?? '').compareTo(b['name'] ?? ''));
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
