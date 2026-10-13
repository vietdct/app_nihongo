import 'package:flutter_test/flutter_test.dart';
import 'package:nihongo/core/services/speaker_voices.dart';
import 'package:nihongo/domain/entities/listening_dialogue.dart';

Map<String, String> voice(String name, [String? gender]) => {
      'name': name,
      'locale': 'ja-JP',
      if (gender != null) 'gender': gender,
    };

List<ListeningTurn> turns(String speakers) =>
    [for (final s in speakers.split('')) ListeningTurn(speaker: s, jp: 'x$s')];

void main() {
  final voices = [voice('Otoya'), voice('Kyoko'), voice('Hattori')];

  test('1 người nói → 1 giọng, profile Natural (pitch 1.0)', () {
    final m = assignSpeakerVoices(turns('AAA').speakerOrder, voices, null);
    expect(m.keys, ['A']);
    expect(m['A']!.voiceName, 'Kyoko');
    expect(m['A']!.pitch, 1.0);
  });

  test('2 người xen kẽ A→B→A: 2 giọng thật khác nhau, giữ nguyên theo người',
      () {
    final t = turns('ABA');
    final m = assignSpeakerVoices(t.speakerOrder, voices, null);
    expect(m['A']!.voiceName, 'Kyoko');
    expect(m['B']!.voiceName, 'Otoya');
    expect(m['A']!.profile, VoiceProfile.natural);
    expect(m['B']!.profile, VoiceProfile.calm);
    expect(
      [for (final x in t) m[x.speaker]!.voiceName],
      ['Kyoko', 'Otoya', 'Kyoko'],
    );
  });

  test('2 người nói liên tục A A B B: giọng đổi đúng theo người nói', () {
    final t = turns('AABB');
    final m = assignSpeakerVoices(t.speakerOrder, voices, null);
    expect(
      [for (final x in t) m[x.speaker]!.voiceName],
      ['Kyoko', 'Kyoko', 'Otoya', 'Otoya'],
    );
  });

  test('3 người: 3 giọng khác nhau khi máy đủ giọng', () {
    final m = assignSpeakerVoices(turns('ABCA').speakerOrder, voices, null);
    expect({for (final v in m.values) v.voiceName}.length, 3);
    expect(m['C']!.profile, VoiceProfile.bright);
  });

  test('3 người nhưng chỉ 2 giọng: C dùng chung giọng A nhưng khác profile',
      () {
    final m = assignSpeakerVoices(
      ['A', 'B', 'C'],
      [voice('Kyoko'), voice('Otoya')],
      null,
    );
    expect(m['C']!.voiceName, m['A']!.voiceName);
    expect(m['C']!.profile, isNot(m['A']!.profile));
  });

  test('người thứ 4 quay lại Natural; mapping ổn định giữa các lần gọi', () {
    final order = ['A', 'B', 'C', 'D'];
    final m1 = assignSpeakerVoices(order, voices, null);
    final m2 = assignSpeakerVoices(order, voices, null);
    expect(m1['D']!.profile, VoiceProfile.natural);
    for (final k in order) {
      expect(m1[k]!.voiceName, m2[k]!.voiceName);
      expect(m1[k]!.profile, m2[k]!.profile);
    }
  });

  test('chênh lệch pitch/rate chỉ nhẹ (không cực đoan)', () {
    for (final p in VoiceProfile.values) {
      expect(p.pitch, inInclusiveRange(0.9, 1.1));
      expect(p.rate, inInclusiveRange(0.9, 1.1));
    }
  });

  test('giọng chất lượng cao nhất được ưu tiên cho người 1, kể cả giọng nam', () {
    final m = assignSpeakerVoices(
      ['A', 'B'],
      [
        {'name': 'Kyoko', 'locale': 'ja-JP', 'quality': 'default'},
        {'name': 'Otoya', 'locale': 'ja-JP', 'quality': 'premium'},
      ],
      null,
    );
    expect(m['A']!.voiceName, 'Otoya');
    expect(m['B']!.voiceName, 'Kyoko');
  });

  test('giọng đã lưu dành cho người 1, người 2 lấy giọng khác giới', () {
    final m = assignSpeakerVoices(
      ['A', 'B'],
      [voice('Kyoko'), voice('Otoya'), voice('O-Ren')],
      voice('Otoya'),
    );
    expect(m['A']!.voiceName, 'Otoya');
    expect(m['B']!.voiceName, isIn(['Kyoko', 'O-Ren']));
  });

  test('máy chỉ có 1 giọng: 2 người khác nhau bằng profile nhẹ', () {
    final m = assignSpeakerVoices(['A', 'B'], [voice('Kyoko')], null);
    expect(m['A']!.voiceName, m['B']!.voiceName);
    expect(m['A']!.pitch, isNot(m['B']!.pitch));
    expect(m['A']!.rateFactor, isNot(m['B']!.rateFactor));
  });

  test('không có giọng nào: không crash, voice null', () {
    final m = assignSpeakerVoices(['A', 'B', 'C'], const [], null);
    expect(m.length, 3);
    expect(m['A']!.voice, isNull);
    expect(m['A']!.pitch, isNot(m['B']!.pitch));
  });

  group('dữ liệu cũ / hỏng', () {
    test('lượt chỉ là chuỗi, hoặc thiếu speaker → speaker mặc định', () {
      expect(ListeningTurn.tryParse('こんにちは')!.speaker, defaultSpeakerId);
      expect(ListeningTurn.tryParse({'jp': 'はい'})!.speaker, defaultSpeakerId);
      expect(
        ListeningTurn.tryParse({'speaker': '  ', 'jp': 'はい'})!.speaker,
        defaultSpeakerId,
      );
    });

    test('đọc speaker/speaker_id và cắt khoảng trắng', () {
      expect(
        ListeningTurn.tryParse({'speaker': ' B ', 'jp': ' はい '})!.speaker,
        'B',
      );
      expect(
        ListeningTurn.tryParse({'speaker_id': 'C', 'jp': 'x'})!.speaker,
        'C',
      );
    });

    test('nội dung rỗng/không phải chuỗi → bỏ lượt', () {
      expect(ListeningTurn.tryParse({'speaker': 'A', 'jp': '  '}), isNull);
      expect(ListeningTurn.tryParse({'speaker': 'A'}), isNull);
      expect(ListeningTurn.tryParse(null), isNull);
      expect(ListeningTurn.tryParse(42), isNull);
    });

    test('speakerOrder theo thứ tự xuất hiện, hasMultipleSpeakers', () {
      expect(turns('BABC').speakerOrder, ['B', 'A', 'C']);
      expect(turns('AAA').hasMultipleSpeakers, isFalse);
      expect(turns('AB').hasMultipleSpeakers, isTrue);
    });
  });
}
