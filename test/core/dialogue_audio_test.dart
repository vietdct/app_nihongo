import 'package:flutter_test/flutter_test.dart';
import 'package:nihongo/core/services/dialogue_audio.dart';

void main() {
  test('hash khớp bản Python (tool/generate_listening_audio.py)', () {
    expect(fnv1a64Hex('こんにちは。'), '6f0c7d66dcd001b4');
  });

  test('hash bit cao = 1 không âm, khớp Python', () {
    // Từ log thật: Dart từng in "-158c0e51aee02afa" cho các câu như vậy.
    expect(fnv1a64Hex('何名様ですか。'), 'a5512b5e4320284c');
    expect(fnv1a64Hex('十枚お願いします。'), '92372f12cc1c5aaf');
    expect(fnv1a64Hex('はい、よろしくお願いします。'), '4d583989878b2c4a');
  });

  test('đường dẫn theo slot quay vòng 3 giọng', () {
    expect(dialogueAudioPath(0, 'a'), startsWith('s0/'));
    expect(dialogueAudioPath(2, 'a'), startsWith('s2/'));
    expect(dialogueAudioPath(3, 'a'), startsWith('s0/'));
    expect(dialogueAudioPath(1, ' a '), dialogueAudioPath(1, 'a'));
  });

  test('chưa khởi tạo Supabase → play trả false, không ném lỗi', () async {
    expect(await DialogueAudio().play(0, 'こんにちは', 1.0), isFalse);
  });
}
