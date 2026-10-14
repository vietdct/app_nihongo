import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';

import '../core/services/dialogue_audio.dart';
import '../core/services/jp_voice_prefs.dart';
import '../core/theme/app_theme.dart';
import 'motion/playing_indicator.dart';
import 'motion/press_scale.dart';

/// Nút loa nhỏ đọc to 1 chuỗi tiếng Nhật — dùng ở các thẻ Lesson Understand
/// (từ vựng/kanji/ngữ pháp không có audio thu sẵn), cùng giọng đã lưu với AI
/// Kaiwa/Quiz (xem `jp_voice_prefs.dart`) để nhất quán trải nghiệm nghe toàn
/// app thay vì mỗi màn tự chọn giọng riêng.
class JpSpeakButton extends StatefulWidget {
  const JpSpeakButton({
    super.key,
    required this.text,
    this.color = AppColors.ink,
    this.size = 22,
    this.padding,
    this.constraints,
  });

  final String text;
  final Color color;
  final double size;
  final EdgeInsetsGeometry? padding;
  final BoxConstraints? constraints;

  @override
  State<JpSpeakButton> createState() => _JpSpeakButtonState();
}

class _JpSpeakButtonState extends State<JpSpeakButton> {
  final _tts = FlutterTts();
  final _audio = DialogueAudio();
  bool _speaking = false;

  @override
  void initState() {
    super.initState();
    unawaited(_prepareVoice());
  }

  Future<void> _prepareVoice() async {
    await configureJpTts(_tts);
  }

  Future<void> _speak() async {
    if (widget.text.isEmpty || _speaking) return;
    setState(() => _speaking = true);
    // finally: dù phát xong, bị dừng hay lỗi, trạng thái "đang phát" (và vòng
    // sóng) phải tắt — không kẹt ở đang phát.
    try {
      // Đọc tốc độ đang lưu (người dùng có thể vừa đổi bằng cách giữ nút loa).
      final speed = await loadJpSpeechSpeed();
      // Ưu tiên audio cloud tạo sẵn (cùng bộ với Luyện nói); chưa có → TTS máy.
      if (await _audio.playSentence(widget.text, speed.multiplier)) return;
      if (kDebugMode) debugPrint('[TTS] fallback giọng máy: "${widget.text}"');
      await _tts.setSpeechRate(speed.ttsRate);
      await _tts.speak(prepareJpForSpeech(widget.text));
    } catch (e) {
      // Lỗi phát (TTS/mạng): không làm vỡ màn học, chỉ tắt trạng thái đang phát.
      if (kDebugMode) debugPrint('[TTS] lỗi phát: $e');
    } finally {
      if (mounted) setState(() => _speaking = false);
    }
  }

  @override
  void dispose() {
    unawaited(_tts.stop());
    unawaited(_audio.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onLongPress: () => unawaited(showJpSpeedSheet(context)),
      // Vòng sóng chỉ chạy khi audio thật sự đang phát (cờ _speaking).
      child: PlayingRing(
        active: _speaking,
        color: AppColors.accent,
        child: PressScale(child: _button()),
      ),
    );
  }

  Widget _button() {
    return IconButton(
      onPressed: _speak,
      // Giữ nút để chỉnh tốc độ đọc (áp dụng cho mọi nút loa trong app).
      tooltip: 'Nghe phát âm · giữ để chỉnh tốc độ',
      padding: widget.padding ?? const EdgeInsets.all(8),
      constraints: widget.constraints,
      icon: Icon(
        _speaking ? Icons.volume_up_rounded : Icons.volume_up_outlined,
        color: widget.color,
        size: widget.size,
      ),
    );
  }
}
