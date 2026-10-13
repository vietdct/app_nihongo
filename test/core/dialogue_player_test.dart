import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nihongo/core/services/dialogue_player.dart';
import 'package:nihongo/core/services/speaker_voices.dart';
import 'package:nihongo/core/services/jp_voice_prefs.dart';
import 'package:nihongo/domain/entities/listening_dialogue.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Giả lập plugin flutter_tts: ghi lại mỗi lần `speak` kèm giọng/cao độ/tốc độ
/// đang được đặt, và giữ lượt đọc cho tới khi test cho kết thúc (hoặc `stop`).
class _FakeTts {
  final spoken =
      <({String text, String? voice, double? pitch, double? rate})>[];
  String? _voice;
  double? _pitch;
  double? _rate;
  Completer<void>? _current;

  Future<Object?> handle(MethodCall call) async {
    switch (call.method) {
      case 'getVoices':
        return [
          {'name': 'Kyoko', 'locale': 'ja-JP', 'gender': 'female'},
          {'name': 'Otoya', 'locale': 'ja-JP', 'gender': 'male'},
          {'name': 'Sakura', 'locale': 'ja-JP', 'gender': 'female'},
        ];
      case 'setVoice':
        _voice = (call.arguments as Map)['name'] as String?;
      case 'setPitch':
        _pitch = (call.arguments as num).toDouble();
      case 'setSpeechRate':
        _rate = (call.arguments as num).toDouble();
      case 'speak':
        spoken.add(
          (
            text: call.arguments as String,
            voice: _voice,
            pitch: _pitch,
            rate: _rate
          ),
        );
        final c = _current = Completer<void>();
        await c.future;
      case 'stop':
        _finish();
    }
    return 1;
  }

  void _finish() {
    final c = _current;
    _current = null;
    if (c != null && !c.isCompleted) c.complete();
  }

  /// Cho lượt đang đọc kết thúc tự nhiên.
  void finishCurrent() => _finish();

  Future<void> waitSpoken(int n) async {
    final end = DateTime.now().add(const Duration(seconds: 3));
    while (spoken.length < n) {
      if (DateTime.now().isAfter(end)) {
        fail('chưa đủ $n lượt, có ${spoken.length}');
      }
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }
  }
}

List<ListeningTurn> turns(String speakers) => [
      for (var i = 0; i < speakers.length; i++)
        ListeningTurn(speaker: speakers[i], jp: 'câu-${speakers[i]}-$i'),
    ];

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late _FakeTts fake;
  late DialoguePlayer player;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    fake = _FakeTts();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('flutter_tts'),
          fake.handle,
        );
    player = DialoguePlayer();
  });

  tearDown(() {
    player.dispose();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(const MethodChannel('flutter_tts'), null);
  });

  test('2 người A→B→A: phát tuần tự, mỗi người đúng 1 giọng riêng', () async {
    final t = [
      const ListeningTurn(speaker: 'A', jp: 'a1'),
      const ListeningTurn(speaker: 'B', jp: 'b1'),
      const ListeningTurn(speaker: 'A', jp: 'a2'),
    ];
    unawaited(player.play(t));
    await fake.waitSpoken(1);
    expect(player.currentSpeaker.value, 'A');
    fake.finishCurrent();
    await fake.waitSpoken(2);
    expect(player.currentSpeaker.value, 'B');
    fake.finishCurrent();
    await fake.waitSpoken(3);
    fake.finishCurrent();
    await Future<void>.delayed(const Duration(milliseconds: 30));

    expect([for (final s in fake.spoken) s.text], ['a1', 'b1', 'a2']);
    expect([for (final s in fake.spoken) s.voice], ['Kyoko', 'Otoya', 'Kyoko']);
    expect(
      [for (final s in fake.spoken) s.pitch],
      [VoiceProfile.natural.pitch, VoiceProfile.calm.pitch, VoiceProfile.natural.pitch],
    );
    expect(player.state.value, DialoguePlayState.idle);
    expect(player.currentSpeaker.value, isNull);
  });

  test('1 người nói: mọi lượt cùng 1 giọng', () async {
    unawaited(player.play(turns('AAA')));
    for (var i = 1; i <= 3; i++) {
      await fake.waitSpoken(i);
      fake.finishCurrent();
    }
    await Future<void>.delayed(const Duration(milliseconds: 30));
    expect({for (final s in fake.spoken) s.voice}, {'Kyoko'});
  });

  test('3 người A→B→C→A: 3 giọng khác nhau, người A giữ nguyên giọng',
      () async {
    unawaited(player.play(turns('ABCA')));
    for (var i = 1; i <= 4; i++) {
      await fake.waitSpoken(i);
      fake.finishCurrent();
    }
    final v = [for (final s in fake.spoken) s.voice];
    expect(v.take(3).toSet().length, 3);
    expect(v[3], v[0]);
  });

  test('tạm dừng giữa B rồi tiếp tục: đọc lại đúng lượt B rồi sang A',
      () async {
    unawaited(player.play(turns('ABA')));
    await fake.waitSpoken(1);
    fake.finishCurrent();
    await fake.waitSpoken(2); // đang đọc B
    await player.pause();
    expect(player.state.value, DialoguePlayState.paused);
    expect(player.currentTurn.value, 1);
    expect(player.currentSpeaker.value, 'B');

    unawaited(player.resume());
    await fake.waitSpoken(3);
    expect(fake.spoken[2].text, fake.spoken[1].text); // đúng segment B
    expect(fake.spoken[2].voice, 'Otoya'); // đúng giọng B
    fake.finishCurrent();
    await fake.waitSpoken(4);
    expect(fake.spoken[3].voice, 'Kyoko'); // rồi tới A, không quay về đầu
    expect(fake.spoken[3].text, 'câu-A-2');
  });

  test('tốc độ 0.75× áp dụng cho mọi người nói', () async {
    await player.setSpeed(AudioPlaybackSpeed.x075);
    unawaited(player.play(turns('ABA')));
    for (var i = 1; i <= 3; i++) {
      await fake.waitSpoken(i);
      fake.finishCurrent();
    }
    // Tốc độ chọn nhân với hệ số rate của profile (A,B,A → Natural,Calm,Natural);
    // pitch không phụ thuộc tốc độ.
    expect(
      [for (final s in fake.spoken) s.rate],
      [
        kTtsNormalRate * 0.75 * VoiceProfile.natural.rate,
        kTtsNormalRate * 0.75 * VoiceProfile.calm.rate,
        kTtsNormalRate * 0.75 * VoiceProfile.natural.rate,
      ],
    );
    expect(
      [for (final s in fake.spoken) s.pitch],
      [VoiceProfile.natural.pitch, VoiceProfile.calm.pitch, VoiceProfile.natural.pitch],
    );
  });

  test('nghe lại giữa chừng: bắt đầu lại từ người đầu tiên', () async {
    final t = turns('ABA');
    unawaited(player.play(t));
    await fake.waitSpoken(1);
    fake.finishCurrent();
    await fake.waitSpoken(2); // đang ở B
    unawaited(player.play(t));
    await fake.waitSpoken(3);
    expect(fake.spoken[2].text, t[0].jp);
    expect(fake.spoken[2].voice, 'Kyoko');
    expect(player.currentTurn.value, 0);
  });

  test('chỉ đọc 1 lượt (nút loa từng dòng) rồi dừng', () async {
    unawaited(player.play(turns('ABA'), from: 1, single: true));
    await fake.waitSpoken(1);
    expect(fake.spoken.single.voice, 'Otoya');
    expect(fake.spoken.single.pitch, VoiceProfile.calm.pitch); // nghe lại B vẫn Calm
    fake.finishCurrent();
    await Future<void>.delayed(const Duration(milliseconds: 400));
    expect(fake.spoken.length, 1);
    expect(player.state.value, DialoguePlayState.idle);
  });
}
