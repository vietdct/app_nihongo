import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Bucket Supabase Storage (public) chứa audio hội thoại tạo sẵn bằng cloud TTS
/// — xem `tool/generate_listening_audio.py`.
const listeningAudioBucket = 'listening-audio';

/// Số giọng cloud khác nhau (slot nhân vật 0,1,2 → 3 giọng; từ nhân vật thứ 4
/// quay vòng lại giọng đầu, giống `VoiceProfile.forSlot`).
const listeningAudioVoiceCount = 3;

/// FNV-1a 64-bit của UTF-8 [text] → 16 ký tự hex. PHẢI khớp với bản Python
/// trong `tool/generate_listening_audio.py` (cùng đầu vào → cùng tên file).
@visibleForTesting
String fnv1a64Hex(String text) {
  var h = 0xcbf29ce484222325;
  for (final b in utf8.encode(text)) {
    h = (h ^ b) * 0x100000001b3;
  }
  // BigInt: trên VM 64-bit `int.toUnsigned(64)` không đổi số âm (bit cao = 1).
  return BigInt.from(h).toUnsigned(64).toRadixString(16).padLeft(16, '0');
}

/// Đường dẫn file audio của 1 lượt thoại: theo giọng (slot nhân vật quy về
/// `slot % 3`) + hash nội dung, nên không cần id đoạn hội thoại và dùng chung
/// được cho Nghe hiểu, bài học IT lẫn đề thi.
String dialogueAudioPath(int slot, String jp) =>
    's${slot % listeningAudioVoiceCount}/${fnv1a64Hex(jp.trim())}.mp3';

/// Đường dẫn file audio của 1 câu mẫu đơn (Luyện nói/Shadowing): 1 giọng duy
/// nhất, theo hash nội dung câu.
String sentenceAudioPath(String jp) => 'm/${fnv1a64Hex(jp.trim())}.mp3';

/// Phát audio hội thoại tạo sẵn (giọng thần kinh khác nhau theo nhân vật). Mọi
/// lỗi (chưa có file, mất mạng, chưa khởi tạo Supabase) đều trả `false` để
/// người gọi quay về TTS của máy — không bao giờ ném lỗi.
class DialogueAudio {
  AudioPlayer? _player;
  final Map<String, bool> _exists = {};
  int _token = 0;

  AudioPlayer get _p => _player ??= AudioPlayer();

  String _urlFor(String path) => Supabase.instance.client.storage
      .from(listeningAudioBucket)
      .getPublicUrl(path);

  Future<bool> _check(String url) async {
    final cached = _exists[url];
    if (cached != null) return cached;
    final client = HttpClient()
      ..connectionTimeout = const Duration(seconds: 3);
    try {
      final req = await client.headUrl(Uri.parse(url));
      final res = await req.close().timeout(const Duration(seconds: 4));
      await res.drain<void>();
      return _exists[url] = res.statusCode == 200;
    } catch (_) {
      // Lỗi mạng không nhớ lại: lần sau thử tiếp.
      return false;
    } finally {
      client.close(force: true);
    }
  }

  /// Phát lượt thoại [jp] của nhân vật thứ [slot] với tốc độ [speed] (1.0 =
  /// gốc) và chờ phát xong. `false` = không phát được (người gọi dùng TTS).
  Future<bool> play(int slot, String jp, double speed) =>
      _playPath(dialogueAudioPath(slot, jp), speed);

  /// Phát câu mẫu đơn (Luyện nói) — xem [sentenceAudioPath].
  Future<bool> playSentence(String jp, double speed) =>
      _playPath(sentenceAudioPath(jp), speed);

  Future<bool> _playPath(String path, double speed) async {
    final token = ++_token;
    try {
      final url = _urlFor(path);
      final exists = await _check(url);
      if (kDebugMode) debugPrint('[TTS] audio exists=$exists $url');
      if (!exists || token != _token) return token != _token;
      final done = Completer<void>();
      final sub = _p.onPlayerComplete.listen((_) {
        if (!done.isCompleted) done.complete();
      });
      final stateSub = _p.onPlayerStateChanged.listen((s) {
        if (s == PlayerState.stopped && !done.isCompleted) done.complete();
      });
      try {
        await _p.setPlaybackRate(speed);
        await _p.play(UrlSource(url));
        await done.future.timeout(const Duration(seconds: 60));
      } finally {
        unawaited(sub.cancel());
        unawaited(stateSub.cancel());
      }
      return true;
    } catch (e) {
      if (kDebugMode) debugPrint('[TTS] audio fallback: $e');
      return false;
    }
  }

  Future<void> stop() async {
    _token++;
    try {
      await _player?.stop();
    } catch (_) {}
  }

  Future<void> dispose() async {
    _token++;
    try {
      await _player?.dispose();
    } catch (_) {}
  }
}
