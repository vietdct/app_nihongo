import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';

import '../core/services/jp_voice_prefs.dart';
import '../core/theme/app_theme.dart';

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
  });

  final String text;
  final Color color;
  final double size;

  @override
  State<JpSpeakButton> createState() => _JpSpeakButtonState();
}

class _JpSpeakButtonState extends State<JpSpeakButton> {
  final _tts = FlutterTts()
    ..setLanguage('ja-JP')
    ..setVolume(1.0)
    ..setSpeechRate(0.45)
    ..awaitSpeakCompletion(true);
  bool _speaking = false;

  @override
  void initState() {
    super.initState();
    unawaited(_prepareVoice());
  }

  Future<void> _prepareVoice() async {
    await applyIosTtsPlaybackCategory(_tts);
    final voices = await loadJapaneseVoices(_tts);
    final saved = await loadSavedJpVoice(voices);
    if (saved != null) await _tts.setVoice(saved);
  }

  Future<void> _speak() async {
    if (widget.text.isEmpty || _speaking) return;
    setState(() => _speaking = true);
    await _tts.speak(widget.text);
    if (mounted) setState(() => _speaking = false);
  }

  @override
  void dispose() {
    unawaited(_tts.stop());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: _speak,
      tooltip: 'Nghe phát âm',
      icon: Icon(
        _speaking ? Icons.volume_up_rounded : Icons.volume_up_outlined,
        color: widget.color,
        size: widget.size,
      ),
    );
  }
}
