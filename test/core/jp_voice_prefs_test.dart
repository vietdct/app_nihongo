import 'package:flutter_test/flutter_test.dart';
import 'package:nihongo/core/services/jp_voice_prefs.dart';

void main() {
  test('1.0× = tốc độ thường của engine; các mức khác nhân theo', () {
    expect(AudioPlaybackSpeed.x100.ttsRate, kTtsNormalRate);
    expect(AudioPlaybackSpeed.x075.ttsRate, closeTo(kTtsNormalRate * 0.75, 1e-9));
    expect(AudioPlaybackSpeed.x150.ttsRate, closeTo(kTtsNormalRate * 1.5, 1e-9));
    expect(AudioPlaybackSpeed.x050.ttsRate, closeTo(kTtsNormalRate * 0.5, 1e-9));
  });

  test('xếp hạng chất lượng giọng: premium > enhanced > mặc định', () {
    expect(voiceQualityRank({'quality': 'premium'}), 3);
    expect(voiceQualityRank({'quality': 'enhanced'}), 2);
    expect(voiceQualityRank({'quality': 'default'}), 0);
    expect(voiceQualityRank({'quality': '500'}), 3);
    expect(voiceQualityRank({'quality': '300'}), 0);
    expect(voiceQualityRank({'name': 'x'}), 0);
  });

  group('prepareJpForSpeech', () {
    test('bỏ dấu 〜 đầu mẫu ngữ pháp, đổi 〜 giữa thành quãng nghỉ', () {
      expect(prepareJpForSpeech('〜について'), 'について');
      expect(prepareJpForSpeech('〜に〜ます'), 'に、ます');
    });

    test('… thành quãng nghỉ, gộp khoảng trắng', () {
      expect(prepareJpForSpeech('えっと…  そうですね'), 'えっと、 そうですね');
    });

    test('chữ Latin trước さん đọc bằng katakana', () {
      expect(prepareJpForSpeech('Aさんは来ました'), 'エーさんは来ました');
    });

    test('văn bản thường giữ nguyên', () {
      expect(prepareJpForSpeech('今日は会議があります。'), '今日は会議があります。');
    });
  });
}
