import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:speech_to_text/speech_to_text.dart';

import '../../core/services/jp_voice_prefs.dart';
import '../../core/theme/app_theme.dart';
import '../../domain/entities/grammar_point.dart';
import '../../domain/services/audio_silence_detector.dart';
import '../../domain/services/shadowing_scorer.dart';
import 'providers/kaiwa_pronunciation_service.dart';
import 'providers/kaiwa_shadowing_providers.dart';

/// Luyện phát âm kiểu Shadowing: nghe câu mẫu (TTS) → lặp lại (mic) → chấm
/// bằng độ khớp văn bản thuần (`computeShadowingScore`, không gọi AI, miễn
/// phí, chấm ngay lập tức). Câu luyện lấy từ `example_jp` thật của ngữ pháp
/// đang học.
///
/// Ngoài ra có thêm mục "Xin AI nhận xét phát âm" (opt-in, tốn token) — ghi
/// âm thật qua `record` rồi gửi cho Gemini nghe (`ai-pronunciation-feedback`
/// edge function), trả về nhận xét CHỦ QUAN chứ không phải điểm phoneme khoa
/// học (app chưa tích hợp dịch vụ chấm phát âm chuyên dụng như Azure
/// Pronunciation Assessment) — luôn hiển thị rõ đây là cảm nhận của AI.
///
/// Trước khi gọi AI, bản ghi được lọc qua `analyzeWavSilence` (RMS trên PCM
/// 16-bit) — nếu rõ ràng im lặng thì trả kết quả "chưa nghe rõ" ngay tại
/// máy, không tốn phí gọi Gemini. Lớp lọc này chỉ bắt được im lặng thật,
/// KHÔNG bắt được tiếng ồn/tiếng bíp có năng lượng nhưng không phải giọng
/// nói — case đó vẫn cần Gemini nghe thật (đây là lý do model dùng cho
/// function này đã đổi sang `gemini-3.1-pro-preview`, xem comment trong
/// `ai-pronunciation-feedback/index.ts`).
class KaiwaShadowingScreen extends ConsumerStatefulWidget {
  const KaiwaShadowingScreen({super.key});

  @override
  ConsumerState<KaiwaShadowingScreen> createState() => _KaiwaShadowingScreenState();
}

class _KaiwaShadowingScreenState extends ConsumerState<KaiwaShadowingScreen> {
  final _tts = FlutterTts();
  final _speech = SpeechToText();
  final _recorder = AudioRecorder();

  int _index = 0;
  final List<int> _scores = [];
  String? _recognizedText;
  int? _currentScore;

  bool _speechAvailable = true;
  bool _speechInitStarted = false;
  bool _isListening = false;
  bool _ttsSpeaking = false;

  List<Map<String, String>> _japaneseVoices = [];
  Map<String, String>? _selectedVoice;

  // Ghi âm gửi AI (Gemini) nhận xét phát âm — riêng biệt với `_speech` ở
  // trên vì speech_to_text không cho lấy lại file audio thô đã nghe.
  Timer? _aiAutoStopTimer;
  String? _aiRecordingPath;
  bool _aiRecording = false;
  bool _aiLoading = false;
  PronunciationFeedback? _aiFeedback;
  String? _aiError;

  static const _aiMaxRecordDuration = Duration(seconds: 8);

  @override
  void initState() {
    super.initState();
    _tts.setLanguage('ja-JP');
    _tts.setVolume(1.0);
    _tts.setPitch(1.0);
    _tts.setSpeechRate(0.42);
    _applyIosAudioCategory();
    _tts.setStartHandler(_forceStopMicForTts);
    _tts.setCompletionHandler(() {
      if (mounted) setState(() => _ttsSpeaking = false);
    });
    _tts.setCancelHandler(() {
      if (mounted) setState(() => _ttsSpeaking = false);
    });
    _tts.setErrorHandler((msg) {
      if (!mounted) return;
      setState(() => _ttsSpeaking = false);
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text('Lỗi đọc tiếng Nhật: $msg')));
    });
    _loadVoices();
  }

  @override
  void dispose() {
    _speech.stop();
    _tts.stop();
    _aiAutoStopTimer?.cancel();
    _recorder.dispose();
    super.dispose();
  }

  Future<void> _loadVoices() async {
    try {
      final voices = await loadJapaneseVoices(_tts);
      final saved = await loadSavedJpVoice(voices);
      if (!mounted) return;
      setState(() {
        _japaneseVoices = voices;
        _selectedVoice = saved;
      });
      if (saved != null) await _tts.setVoice(saved);
    } catch (_) {
      // bỏ qua — vẫn phát được bằng giọng mặc định của máy
    }
  }

  Future<void> _applyIosAudioCategory() async {
    try {
      await _tts
          .setIosAudioCategory(
            IosTextToSpeechAudioCategory.playAndRecord,
            [
              IosTextToSpeechAudioCategoryOptions.defaultToSpeaker,
              IosTextToSpeechAudioCategoryOptions.allowBluetooth,
              IosTextToSpeechAudioCategoryOptions.mixWithOthers,
            ],
          )
          .timeout(const Duration(seconds: 2));
    } catch (_) {
      // bỏ qua trên Android hoặc nếu native phản hồi chậm
    }
  }

  void _forceStopMicForTts() {
    if (!mounted) return;
    final wasListening = _isListening;
    if (wasListening) _speech.stop();
    setState(() {
      _ttsSpeaking = true;
      if (wasListening) _isListening = false;
    });
  }

  Future<void> _speak(String text) async {
    if (text.isEmpty) return;
    _forceStopMicForTts();
    await _applyIosAudioCategory();
    try {
      await _tts.stop().timeout(const Duration(seconds: 3));
    } catch (_) {
      // bỏ qua — vẫn tiếp tục phát
    }
    unawaited(_tts.speak(text));
    Future.delayed(const Duration(seconds: 20), () {
      if (mounted && _ttsSpeaking) setState(() => _ttsSpeaking = false);
    });
  }

  Future<bool> _ensureSpeechInitialized() async {
    if (_speechInitStarted) return _speechAvailable;
    _speechInitStarted = true;
    final ok = await _speech.initialize(
      onError: (error) {
        if (!mounted) return;
        setState(() => _isListening = false);
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text('Lỗi ghi âm (${error.errorMsg}), hãy thử lại.')));
      },
      onStatus: (status) {
        if (!mounted) return;
        if (status == 'done' || status == 'notListening') {
          setState(() => _isListening = false);
        }
      },
    );
    if (mounted) setState(() => _speechAvailable = ok);
    return ok;
  }

  Future<void> _toggleListening(String targetJp) async {
    if (_ttsSpeaking || _aiRecording) return;
    if (_isListening) {
      await _speech.stop();
      if (mounted) setState(() => _isListening = false);
      return;
    }
    if (!await _ensureSpeechInitialized()) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(content: Text('Thiết bị không hỗ trợ nhận diện giọng nói.')));
      return;
    }
    if (!await _speech.hasPermission) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            duration: Duration(seconds: 6),
            content: Text('Chưa có quyền micro. Vào Cài đặt > Ứng dụng > Nihongo > Quyền > bật Micro.'),
          ),
        );
      return;
    }
    setState(() {
      _isListening = true;
      _recognizedText = null;
      _currentScore = null;
    });
    try {
      await _speech.listen(
        onResult: (result) {
          if (_ttsSpeaking) return;
          if (result.finalResult) {
            _scoreAttempt(targetJp, result.recognizedWords);
          }
        },
        listenOptions: SpeechListenOptions(localeId: 'ja_JP', partialResults: false),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isListening = false);
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text('Lỗi ghi âm: $e')));
    }
  }

  void _scoreAttempt(String targetJp, String recognized) {
    final score = computeShadowingScore(targetJp, recognized);
    if (!mounted) return;
    setState(() {
      _isListening = false;
      _recognizedText = recognized;
      _currentScore = score;
    });
  }

  void _retrySentence() {
    setState(() {
      _recognizedText = null;
      _currentScore = null;
      _aiFeedback = null;
      _aiError = null;
    });
  }

  void _nextSentence() {
    setState(() {
      _scores.add(_currentScore ?? 0);
      _recognizedText = null;
      _currentScore = null;
      _aiFeedback = null;
      _aiError = null;
      _index++;
    });
  }

  Future<void> _toggleAiRecording(String targetJp) async {
    if (_aiRecording) {
      await _stopAiRecordingAndAssess(targetJp);
      return;
    }
    if (_ttsSpeaking || _isListening || _aiLoading) return;
    setState(() {
      _aiFeedback = null;
      _aiError = null;
    });
    if (!await _recorder.hasPermission()) {
      if (!mounted) return;
      setState(() => _aiError = 'Chưa có quyền micro. Vào Cài đặt > Ứng dụng > Nihongo > Quyền > bật Micro.');
      return;
    }
    final dir = await getTemporaryDirectory();
    final path = '${dir.path}/shadowing_ai_${DateTime.now().millisecondsSinceEpoch}.wav';
    try {
      await _recorder.start(const RecordConfig(encoder: AudioEncoder.wav), path: path);
    } catch (e) {
      if (!mounted) return;
      setState(() => _aiError = 'Không mở được micro: $e');
      return;
    }
    _aiRecordingPath = path;
    if (!mounted) return;
    setState(() => _aiRecording = true);
    _aiAutoStopTimer?.cancel();
    _aiAutoStopTimer = Timer(_aiMaxRecordDuration, () {
      if (_aiRecording) _stopAiRecordingAndAssess(targetJp);
    });
  }

  Future<void> _stopAiRecordingAndAssess(String targetJp) async {
    _aiAutoStopTimer?.cancel();
    final stoppedPath = await _recorder.stop();
    if (!mounted) return;
    setState(() {
      _aiRecording = false;
      _aiLoading = true;
    });
    final filePath = stoppedPath ?? _aiRecordingPath;
    try {
      if (filePath == null) throw Exception('Không ghi âm được, vui lòng thử lại.');
      final file = File(filePath);
      final bytes = await file.readAsBytes();
      if (bytes.isEmpty) throw Exception('Không ghi âm được, vui lòng thử lại.');

      // Chặn cục bộ trước khi tốn phí gọi AI — chỉ bắt được im lặng thật
      // (RMS thấp), KHÔNG bắt được tiếng ồn/tiếng bíp có năng lượng nhưng
      // không phải giọng nói, case đó vẫn cần Gemini nghe thật mới biết.
      final silence = analyzeWavSilence(bytes);
      if (silence.isSilent) {
        try {
          await file.delete();
        } catch (_) {
          // bỏ qua — file tạm, không ảnh hưởng chức năng
        }
        if (!mounted) return;
        setState(() {
          _aiLoading = false;
          _aiFeedback = const PronunciationFeedback(
            heardText: '',
            impression: PronunciationImpression.chuaRo,
            comment: 'Không phát hiện giọng nói trong bản ghi. Hãy ghi âm gần mic hơn và nói to hơn nhé.',
            isLocalOnly: true,
          );
        });
        return;
      }

      final service = ref.read(kaiwaPronunciationServiceProvider);
      if (service == null) throw Exception('Bạn cần đăng nhập để dùng tính năng này.');
      final feedback = await service.assess(targetJp: targetJp, audioBytes: bytes, mimeType: 'audio/wav');
      try {
        await file.delete();
      } catch (_) {
        // bỏ qua — file tạm, không ảnh hưởng chức năng
      }
      if (!mounted) return;
      setState(() {
        _aiFeedback = feedback;
        _aiLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _aiLoading = false;
        _aiError = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  void _openVoicePicker() {
    showJpVoicePicker(
      context: context,
      voices: _japaneseVoices,
      selected: _selectedVoice,
      onSelected: (voice) async {
        await _tts.setVoice(voice);
        await saveJpVoice(voice);
        if (mounted) setState(() => _selectedVoice = voice);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final sessionAsync = ref.watch(kaiwaShadowingSessionProvider);
    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        title: const Text('Luyện phát âm'),
        actions: [
          IconButton(
            tooltip: 'Chọn giọng đọc',
            icon: const Icon(Icons.record_voice_over_outlined, color: AppColors.inkFaint),
            onPressed: _openVoicePicker,
          ),
        ],
      ),
      body: sessionAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Lỗi: $e')),
        data: (session) {
          if (session.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Chưa có câu ví dụ nào để luyện phát âm ở cấp độ này.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.inkSoft),
                ),
              ),
            );
          }
          if (_index >= session.length) {
            return _SessionSummary(scores: _scores);
          }

          final current = session[_index];
          return Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            child: Column(
              children: [
                Text(
                  'Câu ${_index + 1}/${session.length}',
                  style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.inkSoft),
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: SingleChildScrollView(
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _ShadowingCard(
                            grammar: current,
                            isListening: _isListening,
                            ttsSpeaking: _ttsSpeaking,
                            speechAvailable: _speechAvailable && !_aiRecording,
                            recognizedText: _recognizedText,
                            score: _currentScore,
                            onListen: () => _speak(current.exampleJp!),
                            onToggleRecord: () => _toggleListening(current.exampleJp!),
                          ),
                          if (_currentScore != null)
                            _AiPronunciationSection(
                              recording: _aiRecording,
                              loading: _aiLoading,
                              feedback: _aiFeedback,
                              errorText: _aiError,
                              enabled: !_isListening && !_ttsSpeaking,
                              onToggleRecord: () => _toggleAiRecording(current.exampleJp!),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                if (_currentScore != null)
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _retrySentence,
                          style: OutlinedButton.styleFrom(foregroundColor: AppColors.teal, minimumSize: const Size.fromHeight(50)),
                          child: const Text('Thử lại câu này'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: FilledButton(
                          onPressed: _nextSentence,
                          style: FilledButton.styleFrom(backgroundColor: AppColors.teal, minimumSize: const Size.fromHeight(50)),
                          child: Text(_index == session.length - 1 ? 'Xem kết quả' : 'Câu tiếp theo'),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ShadowingCard extends StatelessWidget {
  const _ShadowingCard({
    required this.grammar,
    required this.isListening,
    required this.ttsSpeaking,
    required this.speechAvailable,
    required this.recognizedText,
    required this.score,
    required this.onListen,
    required this.onToggleRecord,
  });

  final GrammarPoint grammar;
  final bool isListening;
  final bool ttsSpeaking;
  final bool speechAvailable;
  final String? recognizedText;
  final int? score;
  final VoidCallback onListen;
  final VoidCallback onToggleRecord;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxWidth: 420),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 18, offset: const Offset(0, 8))],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(grammar.title, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: AppColors.inkFaint)),
          const SizedBox(height: 10),
          Text(
            grammar.exampleJp ?? '',
            textAlign: TextAlign.center,
            style: AppFonts.zenMaruGothic(fontSize: 22, color: AppColors.ink, fontWeight: FontWeight.w700),
          ),
          if ((grammar.exampleVi ?? '').isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              grammar.exampleVi!,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12.5, color: AppColors.inkSoft, fontStyle: FontStyle.italic),
            ),
          ],
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _RoundIconButton(
                icon: ttsSpeaking ? Icons.volume_up_rounded : Icons.volume_up_outlined,
                color: AppColors.teal,
                onTap: ttsSpeaking ? null : onListen,
                tooltip: 'Nghe mẫu',
              ),
              const SizedBox(width: 20),
              _RoundIconButton(
                icon: isListening ? Icons.stop_rounded : Icons.mic_none_rounded,
                color: isListening ? AppColors.danger : AppColors.accent,
                large: true,
                onTap: (speechAvailable && !ttsSpeaking) ? onToggleRecord : null,
                tooltip: isListening ? 'Dừng ghi âm' : 'Lặp lại câu này',
              ),
            ],
          ),
          if (isListening) ...[
            const SizedBox(height: 14),
            const Text('Đang nghe...', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.accent)),
          ],
          if (score != null) ...[
            const SizedBox(height: 20),
            _ScoreBadge(score: score!),
            const SizedBox(height: 10),
            Text(
              recognizedText!.isEmpty ? '(không nghe rõ)' : recognizedText!,
              textAlign: TextAlign.center,
              style: AppFonts.zenMaruGothic(fontSize: 15, color: AppColors.inkSoft),
            ),
          ],
        ],
      ),
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  const _RoundIconButton({required this.icon, required this.color, required this.onTap, required this.tooltip, this.large = false});

  final IconData icon;
  final Color color;
  final VoidCallback? onTap;
  final String tooltip;
  final bool large;

  @override
  Widget build(BuildContext context) {
    final size = large ? 68.0 : 52.0;
    final enabled = onTap != null;
    return Tooltip(
      message: tooltip,
      child: InkWell(
        borderRadius: BorderRadius.circular(100),
        onTap: onTap,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: enabled ? color.withValues(alpha: 0.14) : AppColors.chip,
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Icon(icon, color: enabled ? color : AppColors.inkFaint, size: large ? 30 : 24),
        ),
      ),
    );
  }
}

class _ScoreBadge extends StatelessWidget {
  const _ScoreBadge({required this.score});

  final int score;

  (Color, String) get _style {
    if (score >= 90) return (AppColors.moss, 'Xuất sắc, giống hệt!');
    if (score >= 70) return (AppColors.teal, 'Khá tốt');
    if (score >= 40) return (AppColors.accent, 'Cần luyện thêm');
    return (AppColors.danger, 'Nghe chưa rõ, thử lại nhé');
  }

  @override
  Widget build(BuildContext context) {
    final (color, label) = _style;
    return Column(
      children: [
        Text('$score', style: TextStyle(fontSize: 34, fontWeight: FontWeight.w900, color: color)),
        Text(label, style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: color)),
      ],
    );
  }
}

class _SessionSummary extends StatelessWidget {
  const _SessionSummary({required this.scores});

  final List<int> scores;

  @override
  Widget build(BuildContext context) {
    final avg = scores.isEmpty ? 0 : (scores.reduce((a, b) => a + b) / scores.length).round();
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle_rounded, color: AppColors.moss, size: 56),
            const SizedBox(height: 16),
            const Text('Hoàn thành buổi luyện!', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.ink)),
            const SizedBox(height: 8),
            Text(
              scores.isEmpty ? 'Bạn chưa luyện câu nào.' : 'Điểm trung bình: $avg/100 · ${scores.length} câu đã luyện',
              style: const TextStyle(fontSize: 13.5, color: AppColors.inkSoft),
            ),
            const SizedBox(height: 20),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: AppColors.teal),
              onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
              child: const Text('Về trang chủ Kaiwa'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Nút "Xin AI nhận xét phát âm" (opt-in, tốn token Gemini) + trạng thái ghi
/// âm/đang chờ AI. Chỉ hiện sau khi đã có điểm chấm miễn phí (`_currentScore
/// != null`) — luyện trước, xin AI nhận xét sâu hơn sau, giống pattern "Hỏi
/// AI thêm" ở Kaiwa Tutor.
class _AiPronunciationSection extends StatelessWidget {
  const _AiPronunciationSection({
    required this.recording,
    required this.loading,
    required this.feedback,
    required this.errorText,
    required this.enabled,
    required this.onToggleRecord,
  });

  final bool recording;
  final bool loading;
  final PronunciationFeedback? feedback;
  final String? errorText;
  final bool enabled;
  final VoidCallback onToggleRecord;

  @override
  Widget build(BuildContext context) {
    if (feedback != null) {
      return _AiFeedbackCard(feedback: feedback!);
    }
    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: Column(
        children: [
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: (enabled || recording) ? onToggleRecord : null,
              icon: loading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Icon(recording ? Icons.stop_circle_outlined : Icons.auto_awesome_outlined),
              label: Text(
                loading
                    ? 'AI đang nghe...'
                    : (recording ? 'Dừng & gửi cho AI' : 'Xin AI nhận xét phát âm'),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: recording ? AppColors.danger : AppColors.indigo,
                minimumSize: const Size.fromHeight(44),
              ),
            ),
          ),
          if (errorText != null) ...[
            const SizedBox(height: 6),
            Text(
              errorText!,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, color: AppColors.danger),
            ),
          ],
        ],
      ),
    );
  }
}

class _AiFeedbackCard extends StatelessWidget {
  const _AiFeedbackCard({required this.feedback});

  final PronunciationFeedback feedback;

  (Color, String) get _style {
    switch (feedback.impression) {
      case PronunciationImpression.ratTot:
        return (AppColors.moss, 'Rất tốt');
      case PronunciationImpression.khaTot:
        return (AppColors.teal, 'Khá tốt');
      case PronunciationImpression.canLuyenThem:
        return (AppColors.accent, 'Cần luyện thêm');
      case PronunciationImpression.chuaRo:
        return (AppColors.danger, 'Chưa nghe rõ');
    }
  }

  @override
  Widget build(BuildContext context) {
    final (color, label) = _style;
    // Kết quả chặn cục bộ (im lặng, phát hiện trước khi gọi AI) — không phải
    // AI đã thực sự nghe, phải ghi rõ khác để không đánh lừa người dùng.
    final headerIcon = feedback.isLocalOnly ? Icons.mic_off_outlined : Icons.auto_awesome_outlined;
    final headerText = feedback.isLocalOnly ? 'Chưa phát hiện giọng nói · $label' : 'Nhận xét từ AI · $label';
    final disclaimer = feedback.isLocalOnly
        ? 'Bản ghi được kiểm tra trực tiếp trên máy (không phát hiện âm thanh), chưa gửi lên AI nên không tốn phí.'
        : 'Đây là cảm nhận chủ quan của AI khi nghe audio, không phải điểm đo phát âm khoa học.';
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(headerIcon, size: 16, color: color),
              const SizedBox(width: 6),
              Text(
                headerText,
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: color),
              ),
            ],
          ),
          if (feedback.heardText.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'AI nghe được: ${feedback.heardText}',
              style: AppFonts.zenMaruGothic(fontSize: 13.5, color: AppColors.ink),
            ),
          ],
          const SizedBox(height: 6),
          Text(feedback.comment, style: const TextStyle(fontSize: 12.5, color: AppColors.inkSoft)),
          const SizedBox(height: 8),
          Text(
            disclaimer,
            style: const TextStyle(fontSize: 10.5, color: AppColors.inkFaint, fontStyle: FontStyle.italic),
          ),
        ],
      ),
    );
  }
}
