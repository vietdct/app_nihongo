import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

import '../../domain/entities/listening_dialogue.dart';
import 'dialogue_audio.dart';
import 'jp_voice_prefs.dart';
import 'speaker_voices.dart';

enum DialoguePlayState { idle, playing, paused }

/// Nghỉ ngắn khi đổi người nói (giữa 2 lượt thoại của 2 nhân vật khác nhau).
const speakerTransitionPause = Duration(milliseconds: 300);

/// Đọc 1 đoạn hội thoại bằng TTS của máy (flutter_tts → AVSpeechSynthesizer /
/// Android TextToSpeech): mỗi lượt thoại là 1 segment, đọc lần lượt; mỗi nhân
/// vật 1 giọng ja-JP thật khác nhau (xem `assignSpeakerVoices`), chỉ khi máy
/// thiếu giọng mới tách bằng cao độ. 1 người nói → 1 giọng. Hỗ trợ tạm
/// dừng/tiếp tục: TTS không có "resume" chung cho mọi nền tảng nên tạm dừng =
/// dừng ngay và nhớ segment đang đọc, tiếp tục = đọc lại segment đó từ đầu rồi
/// đọc tiếp các segment sau (không quay về đầu đoạn hội thoại).
class DialoguePlayer {
  DialoguePlayer({DialogueAudio? audio}) : _audio = audio ?? DialogueAudio() {
    _ready = _init().catchError((Object e) {
      if (kDebugMode) debugPrint('[TTS] init failed: $e');
    });
  }

  final FlutterTts _tts = FlutterTts();

  /// Audio hội thoại tạo sẵn (cloud TTS, mỗi nhân vật 1 giọng thần kinh khác
  /// nhau); chưa có file hoặc mất mạng thì quay về TTS của máy.
  final DialogueAudio _audio;

  /// Tốc độ đọc (lưu chung toàn app, xem `jp_voice_prefs.dart`) — áp dụng cho
  /// mọi nhân vật; đổi giữa chừng thì có hiệu lực từ segment kế tiếp.
  final ValueNotifier<AudioPlaybackSpeed> speed =
      ValueNotifier(AudioPlaybackSpeed.x100);

  /// Trạng thái phát chung của cả đoạn hội thoại.
  final ValueNotifier<DialoguePlayState> state =
      ValueNotifier(DialoguePlayState.idle);

  /// Chỉ số segment (lượt thoại) đang đọc; null khi không phát. Giữ nguyên
  /// khi tạm dừng để UI biết đang dừng ở đâu.
  final ValueNotifier<int?> currentTurn = ValueNotifier(null);

  /// Nhân vật đang nói (theo [currentTurn]); null khi không phát.
  final ValueNotifier<String?> currentSpeaker = ValueNotifier(null);

  late final Future<void> _ready;
  List<Map<String, String>> _voices = const [];
  Map<String, String>? _savedVoice;
  Map<String, SpeakerVoice> _speakerVoices = const {};

  List<ListeningTurn> _turns = const [];
  int _next = 0;
  bool _single = false;
  int _generation = 0;
  bool _disposed = false;

  Future<void> _init() async {
    await _tts.setLanguage('ja-JP');
    await _tts.setVolume(1.0);
    await _tts.awaitSpeakCompletion(true);
    if (!_disposed) speed.value = await loadJpSpeechSpeed();
    await applyIosTtsPlaybackCategory(_tts);
    _voices = await loadJapaneseVoices(_tts);
    _savedVoice = await loadSavedJpVoice(_voices);
    if (kDebugMode) {
      debugPrint('[TTS] Japanese voices available: ${_voices.length}');
      for (var i = 0; i < _voices.length; i++) {
        debugPrint('[TTS]  ${i + 1}. ${_voices[i]}');
      }
      if (_voices.length < 2) {
        debugPrint('[TTS] Device provides only ${_voices.length} Japanese voice(s).');
      }
    }
  }

  /// Giọng đang gán cho từng nhân vật của đoạn hội thoại hiện tại (để test/UI).
  Map<String, SpeakerVoice> get speakerVoices => _speakerVoices;

  Future<void> setSpeed(AudioPlaybackSpeed value) async {
    speed.value = value;
    await saveJpSpeechSpeed(value);
  }

  /// Phát từ lượt [from]. [single]: chỉ đọc đúng 1 lượt đó (nút loa từng dòng).
  Future<void> play(
    List<ListeningTurn> turns, {
    int from = 0,
    bool single = false,
  }) async {
    _turns = turns;
    _next = from.clamp(0, turns.length);
    _single = single;
    await _run();
  }

  Future<void> pause() async {
    if (state.value != DialoguePlayState.playing) return;
    _generation++;
    await _tts.stop();
    await _audio.stop();
    if (!_disposed) state.value = DialoguePlayState.paused;
  }

  Future<void> resume() async {
    if (state.value != DialoguePlayState.paused) return;
    await _run();
  }

  Future<void> stop() async {
    _generation++;
    _next = 0;
    await _tts.stop();
    await _audio.stop();
    if (_disposed) return;
    currentTurn.value = null;
    currentSpeaker.value = null;
    state.value = DialoguePlayState.idle;
  }

  Future<void> _run() async {
    final gen = ++_generation;
    await _ready;
    if (gen != _generation || _disposed) return;
    await _tts.stop();
    await _audio.stop();
    if (gen != _generation || _disposed) return;
    _speakerVoices =
        assignSpeakerVoices(_turns.speakerOrder, _voices, _savedVoice);
    state.value = DialoguePlayState.playing;
    while (_next < _turns.length) {
      final i = _next;
      currentTurn.value = i;
      currentSpeaker.value = _turns[i].speaker;
      await _speakTurn(i);
      // Tạm dừng/dừng/phát lại làm đổi thế hệ → thoát, giữ nguyên _next.
      if (gen != _generation || _disposed) return;
      _next = i + 1;
      if (_single) break;
      // Đổi người nói → nghỉ ngắn cho tự nhiên; có thể bị tạm dừng giữa chừng
      // (khi đó _next đã trỏ tới segment của người kế tiếp).
      if (_next < _turns.length && _turns[_next].speaker != _turns[i].speaker) {
        await Future<void>.delayed(speakerTransitionPause);
        if (gen != _generation || _disposed) return;
      }
    }
    if (gen == _generation && !_disposed) {
      _next = 0;
      currentTurn.value = null;
      currentSpeaker.value = null;
      state.value = DialoguePlayState.idle;
    }
  }

  Future<void> _speakTurn(int index) async {
    final turn = _turns[index];
    final slot = _turns.speakerOrder.indexOf(turn.speaker);
    if (await _audio.play(slot, turn.jp, speed.value.multiplier)) return;
    final assigned = _speakerVoices[turn.speaker];
    final rate =
        (speed.value.ttsRate * (assigned?.rateFactor ?? 1.0)).clamp(0.1, 1.0);
    await _tts.setSpeechRate(rate);
    Object? setVoiceResult;
    if (assigned?.voice != null) {
      setVoiceResult = await _tts.setVoice(assigned!.voice!);
    }
    await _tts.setPitch(assigned?.pitch ?? 1.0);
    if (kDebugMode) {
      debugPrint('[TTS] speaker=${turn.speaker} voice=${assigned?.voice} '
          'setVoice=$setVoiceResult pitch=${assigned?.pitch} rate=$rate');
    }
    await _tts.speak(prepareJpForSpeech(turn.jp));
  }

  void dispose() {
    _disposed = true;
    _generation++;
    _tts.stop().catchError((Object _) {});
    unawaited(_audio.dispose());
    state.dispose();
    currentTurn.dispose();
    currentSpeaker.dispose();
    speed.dispose();
  }
}
