import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:speech_to_text/speech_to_text.dart';

import '../../core/services/jp_voice_prefs.dart';
import '../../core/theme/app_theme.dart';
import '../../domain/entities/kaiwa_feedback_context.dart';
import '../../domain/entities/kaiwa_message.dart';
import '../../domain/entities/kaiwa_persona.dart';
import '../../domain/entities/kaiwa_scenario.dart';
import '../lesson/providers/level_providers.dart';
import 'kaiwa_summary_screen.dart';
import 'kaiwa_tutor_screen.dart';
import 'providers/kaiwa_chat_service.dart';
import 'providers/kaiwa_conversation_providers.dart';

// Dùng chung khoá lưu giọng đọc với Quiz/Nghe hiểu (lib/core/services/jp_voice_prefs.dart)
// — chọn giọng ở Kaiwa thì Quiz cũng đọc bằng giọng đó, không cần chọn lại.
const _voiceNamePrefKey = jpVoiceNamePrefKey;
const _voiceLocalePrefKey = jpVoiceLocalePrefKey;

// Hồ sơ pitch/tốc độ đọc theo persona.voiceStyle (cột voice_style trong bảng
// kaiwa_personas) — để mỗi nhân vật nghe khác nhau dù dùng chung 1 giọng
// engine của máy (đa số máy chỉ có 1 giọng ja-JP cài sẵn, không đổi được
// giọng thật). pitch mặc định của flutter_tts là 1.0, rate 0.42 như cũ.
const _voiceProfiles = <String, ({double pitch, double rate})>{
  'female_warm': (pitch: 1.05, rate: 0.40),
  'female_energetic': (pitch: 1.25, rate: 0.48),
  'female_bright': (pitch: 1.15, rate: 0.45),
  'female_elderly': (pitch: 0.95, rate: 0.32),
  'male_neutral': (pitch: 0.95, rate: 0.43),
  'male_firm': (pitch: 0.85, rate: 0.41),
  'male_stern': (pitch: 0.78, rate: 0.37),
};
const _defaultVoiceProfile = (pitch: 1.0, rate: 0.42);

class KaiwaChatScreen extends ConsumerStatefulWidget {
  const KaiwaChatScreen({
    super.key,
    required this.persona,
    required this.scenario,
    this.resumeConversationId,
    this.seedWord,
  });

  final KaiwaPersona persona;
  final KaiwaScenario scenario;

  /// Nếu có — mở lại hội thoại đã tồn tại (nạp lịch sử thật, không gọi AI,
  /// không tự đọc lại toàn bộ lịch sử) thay vì bắt đầu một hội thoại mới.
  final String? resumeConversationId;

  /// Từ vựng người dùng muốn luyện dùng trong hội thoại (VD từ thẻ "Từ vựng
  /// hôm nay" > "Dùng trong AI Kaiwa") — chỉ áp dụng khi bắt đầu hội thoại
  /// mới, gửi kèm cho AI qua `ai-kaiwa-chat` để chủ động dẫn dắt dùng từ này.
  final String? seedWord;

  @override
  ConsumerState<KaiwaChatScreen> createState() => _KaiwaChatScreenState();
}

class _KaiwaChatScreenState extends ConsumerState<KaiwaChatScreen> {
  final _textController = TextEditingController();
  final _scrollController = ScrollController();
  final _speech = SpeechToText();
  final _tts = FlutterTts();

  final List<KaiwaMessage> _messages = [];
  String? _conversationId;
  bool _starting = true;
  bool _sending = false;
  // Lạc quan = true (icon mic hiện sẵn, không xám) — quyền thật sự chỉ được
  // xin ở lần bấm mic đầu tiên (_ensureSpeechInitialized), không xin ngay khi
  // vừa vào màn hình để tránh 2 hộp thoại xin quyền hệ thống (mic + nhận diện
  // giọng nói) che màn hình và tranh audio session với TTS đang tự đọc lời chào.
  bool _speechAvailable = true;
  bool _speechInitStarted = false;
  bool _isListening = false;
  bool _showTranslation = false;
  bool _showFurigana = false;
  bool _autoSpeak = true;
  String? _error;

  // Cờ nhắc người dùng rà lại câu vừa nhận diện giọng nói trước khi gửi — STT
  // hệ thống (Apple/Android) không biết ngữ cảnh persona/scenario nên hay đoán
  // sai từ, đặc biệt phát âm chưa chuẩn. _applyingSpeechText để phân biệt lúc
  // tự set text (không tính là người dùng sửa) với lúc người dùng gõ tay thật.
  bool _isSpeechDraft = false;
  bool _speechLowConfidence = false;
  bool _applyingSpeechText = false;

  // Đếm giây khi đang ghi âm — chỉ để hiển thị (mm:ss) trên thanh ghi âm,
  // không ảnh hưởng logic nhận diện giọng nói.
  Timer? _recordingTimer;
  int _recordingSeconds = 0;

  // Bật/tắt thẻ xem trước "Gợi ý trả lời" — reset về false mỗi khi có lượt
  // hội thoại mới vì gợi ý cũ không còn khớp ngữ cảnh.
  bool _suggestionVisible = false;

  // Danh sách giọng đọc tiếng Nhật máy đã cài (qua flutter_tts.getVoices) —
  // chất lượng phụ thuộc engine/giọng có sẵn trên thiết bị, không phải do app
  // tự tổng hợp. Lựa chọn được lưu lại bằng SharedPreferences để dùng cho các
  // hội thoại Kaiwa sau, không phải chọn lại mỗi lần vào.
  List<Map<String, String>> _japaneseVoices = [];
  Map<String, String>? _selectedVoice;

  // Nhân vật AI đang đọc (TTS phát ra loa) — khi true, mic bị khoá và STT bị
  // bỏ qua kết quả, tránh trường hợp loa phát ra bị chính mic của máy bắt lại
  // rồi ghi nhầm lời AI thành lời người dùng vào khung chat.
  bool _ttsSpeaking = false;

  @override
  void initState() {
    super.initState();
    _textController.addListener(() {
      if (_applyingSpeechText || !_isSpeechDraft) return;
      setState(() {
        _isSpeechDraft = false;
        _speechLowConfidence = false;
      });
    });
    _tts.setLanguage('ja-JP');
    _tts.setVolume(1.0);
    _applyIosAudioCategory();
    final profile = _voiceProfiles[widget.persona.voiceStyle] ?? _defaultVoiceProfile;
    _tts.setPitch(profile.pitch);
    _tts.setSpeechRate(profile.rate);
    // 2 lớp chặn mic: (1) stop tường minh trước khi speak() ở _speak(), (2)
    // force-stop ngay khi native báo bắt đầu phát (ở đây) — phòng trường hợp
    // mic được bật đúng lúc callback bắt đầu phát chưa kịp tới.
    _tts.setStartHandler(_forceStopMicForTts);
    _tts.setCompletionHandler(() {
      if (mounted) setState(() => _ttsSpeaking = false);
    });
    _tts.setCancelHandler(() {
      if (mounted) setState(() => _ttsSpeaking = false);
    });
    _tts.setErrorHandler((msg) {
      debugPrint('Kaiwa: TTS lỗi: $msg');
      if (!mounted) return;
      setState(() => _ttsSpeaking = false);
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text('Lỗi đọc tiếng Nhật: $msg')));
    });
    _loadVoices();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final resumeId = widget.resumeConversationId;
      if (resumeId != null) {
        _resumeConversation(resumeId);
      } else {
        _startConversation();
      }
    });
  }

  @override
  void dispose() {
    _recordingTimer?.cancel();
    _textController.dispose();
    _scrollController.dispose();
    _speech.stop();
    _tts.stop();
    super.dispose();
  }

  KaiwaMessage? get _lastAiMessage {
    if (_messages.isEmpty) return null;
    final last = _messages.last;
    return last.role == KaiwaMessageRole.ai ? last : null;
  }

  void _startRecordingTimer() {
    _recordingTimer?.cancel();
    _recordingSeconds = 0;
    _recordingTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _recordingSeconds++);
    });
  }

  void _stopRecordingTimer() {
    _recordingTimer?.cancel();
    _recordingTimer = null;
  }

  void _useSuggestion(String jp) {
    setState(() {
      _textController.text = jp;
      _textController.selection = TextSelection.collapsed(offset: jp.length);
      _suggestionVisible = false;
      _isSpeechDraft = false;
      _speechLowConfidence = false;
    });
  }

  // Dùng chung cho mọi chỗ phát TTS (auto-speak, bấm icon loa nghe lại, nghe
  // thử giọng) — luôn ngắt mic trước khi phát.
  //
  // QUAN TRỌNG: speak() không được await trực tiếp — Future của nó có thể
  // treo vô thời hạn trên 1 số máy nếu callback hoàn thành của flutter_tts
  // không bắn ra được (hay gặp khi speak() bị stop() cắt ngang liền trước
  // đó), kéo theo cả hàm này bị kẹt và mic không bao giờ mở khoá lại. Thay
  // vào đó: bắn speak() không chờ, để các handler native (setStartHandler/
  // setCompletionHandler/...) tự cập nhật _ttsSpeaking theo thời gian thực,
  // cộng thêm 1 timer độc lập để tự mở khoá mic nếu chẳng may handler cũng
  // không bắn ra.
  Future<void> _speak(String text) async {
    if (text.isEmpty) return;
    _forceStopMicForTts();
    // speech_to_text tự cấu hình lại AVAudioSession mỗi khi mic được bật —
    // nếu bạn đã bấm mic dù chỉ 1 lần trước đó, session có thể bị ghi đè về
    // hướng chỉ ghi âm. Khẳng định lại category ngay trước mỗi lần phát thay
    // vì chỉ đặt 1 lần ở initState, để đảm bảo audio luôn ra được loa.
    await _applyIosAudioCategory();
    try {
      await _tts.stop().timeout(const Duration(seconds: 3));
    } catch (_) {
      // bỏ qua — vẫn tiếp tục phát câu mới dù stop() không phản hồi kịp
    }
    unawaited(_tts.speak(text));
    Future.delayed(const Duration(seconds: 20), () {
      if (mounted && _ttsSpeaking) setState(() => _ttsSpeaking = false);
    });
  }

  // Đọc lời thoại nhân vật ngay khi hiện lên, không cần chờ bấm icon loa.
  Future<void> _speakAi(String text) async {
    if (!_autoSpeak) return;
    await _speak(text);
  }

  // iOS: speech_to_text (ghi âm) và flutter_tts (phát tiếng) cùng tranh nhau
  // cấu hình AVAudioSession. Không khai báo rõ category, TTS dễ bị định
  // tuyến sang loa thoại (earpiece, gần như không nghe được) hoặc bị tắt
  // tiếng hẳn sau khi mic đã từng được cấp quyền/dùng — playAndRecord +
  // defaultToSpeaker buộc audio ra loa ngoài, allowBluetooth để vẫn hoạt
  // động khi đang kết nối tai nghe Bluetooth. Không có tác dụng trên Android
  // nhưng gọi an toàn, không lỗi. Bọc timeout ngắn để không chặn _speak() nếu
  // native phản hồi chậm.
  //
  // KHÔNG dùng mode voicePrompt — đây là chế độ Apple dành cho lời nhắc ngắn
  // (VD chỉ đường), hệ thống tự phát ở mức âm lượng nhỏ hơn media bình thường
  // dù người dùng đã vặn max volume. Bỏ qua tham số mode (dùng default) để
  // TTS phát ở mức âm lượng đầy đủ như media/spokenAudio.
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
      // bỏ qua trên Android hoặc nếu native phản hồi chậm — vẫn tiếp tục phát
    }
  }

  // Ngắt mic ngay lập tức nếu đang ghi — gọi trước khi phát TTS và ngay khi
  // native báo bắt đầu phát, đảm bảo mic không bao giờ mở trong lúc loa đang
  // phát tiếng AI, bất kể mic được bật từ trước hay callback native bị trễ.
  void _forceStopMicForTts() {
    if (!mounted) return;
    final wasListening = _isListening;
    if (wasListening) {
      _speech.stop();
      _stopRecordingTimer();
    }
    setState(() {
      _ttsSpeaking = true;
      if (wasListening) _isListening = false;
    });
  }

  Future<void> _loadVoices() async {
    try {
      final raw = await _tts.getVoices as List<dynamic>? ?? const [];
      final jp = raw
          .map((v) => Map<String, String>.from(v as Map))
          .where((v) => (v['locale'] ?? '').toLowerCase().startsWith('ja'))
          .toList()
        ..sort((a, b) => (a['name'] ?? '').compareTo(b['name'] ?? ''));

      final prefs = await SharedPreferences.getInstance();
      final savedName = prefs.getString(_voiceNamePrefKey);
      final savedLocale = prefs.getString(_voiceLocalePrefKey);
      Map<String, String>? saved;
      for (final v in jp) {
        if (v['name'] == savedName && v['locale'] == savedLocale) {
          saved = v;
          break;
        }
      }

      if (!mounted) return;
      setState(() {
        _japaneseVoices = jp;
        _selectedVoice = saved;
      });
      if (saved != null) await _tts.setVoice(saved);
    } catch (e) {
      debugPrint('Kaiwa: lỗi tải danh sách giọng đọc: $e');
    }
  }

  Future<void> _selectVoice(Map<String, String> voice) async {
    await _tts.setVoice(voice);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_voiceNamePrefKey, voice['name'] ?? '');
    await prefs.setString(_voiceLocalePrefKey, voice['locale'] ?? '');
    if (!mounted) return;
    setState(() => _selectedVoice = voice);
    unawaited(_speak('こんにちは、よろしくお願いします。'));
  }

  void _openVoicePicker() {
    if (_japaneseVoices.isEmpty) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(content: Text('Không tìm thấy giọng đọc tiếng Nhật nào trên máy.')));
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
                child: Text('Chọn giọng đọc tiếng Nhật', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.ink)),
              ),
              for (final voice in _japaneseVoices)
                RadioListTile<String>(
                  value: '${voice['name']}|${voice['locale']}',
                  // ignore: deprecated_member_use
                  groupValue: _selectedVoice == null ? null : '${_selectedVoice!['name']}|${_selectedVoice!['locale']}',
                  activeColor: AppColors.teal,
                  title: Text(voice['name'] ?? '', style: const TextStyle(fontSize: 13.5)),
                  subtitle: (voice['quality'] != null || voice['gender'] != null)
                      ? Text([voice['gender'], voice['quality']].where((e) => e != null && e.isNotEmpty).join(' · '), style: const TextStyle(fontSize: 11.5))
                      : null,
                  // ignore: deprecated_member_use
                  onChanged: (_) {
                    Navigator.of(sheetContext).pop();
                    _selectVoice(voice);
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _startConversation() async {
    final service = ref.read(kaiwaChatServiceProvider);
    if (service == null) return;
    setState(() {
      _starting = true;
      _error = null;
    });
    final levelCode = ref.read(selectedLevelCodeProvider);
    final levelId = ref.read(currentLevelIdProvider);
    try {
      final result = await service.startConversation(
        persona: widget.persona,
        scenario: widget.scenario,
        levelCode: levelCode,
        levelId: levelId,
        seedWord: widget.seedWord,
      );
      if (!mounted) return;
      setState(() {
        _conversationId = result.conversationId;
        _messages.add(result.aiMessage);
        _starting = false;
        _suggestionVisible = false;
      });
      // Dashboard Kaiwa (streak/"Tiếp tục hội thoại"/"Hội thoại gần đây") giữ
      // provider này sống suốt vòng đời tab — không invalidate thì màn đó vẫn
      // hiện số liệu cũ dù hội thoại mới đã tạo xong.
      ref.invalidate(kaiwaConversationsProvider);
      _scrollToBottom();
      unawaited(_speakAi(result.aiMessage.contentJp));
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _starting = false;
        _error = 'Không mở được hội thoại: $e';
      });
    }
  }

  Future<void> _resumeConversation(String conversationId) async {
    final service = ref.read(kaiwaChatServiceProvider);
    if (service == null) return;
    setState(() {
      _starting = true;
      _error = null;
    });
    try {
      final messages = await service.loadMessages(conversationId);
      if (!mounted) return;
      setState(() {
        _conversationId = conversationId;
        _messages
          ..clear()
          ..addAll(messages);
        _starting = false;
        _suggestionVisible = false;
      });
      _scrollToBottom();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _starting = false;
        _error = 'Không mở lại được hội thoại: $e';
      });
    }
  }

  void _retryStart() {
    final resumeId = widget.resumeConversationId;
    if (resumeId != null) {
      _resumeConversation(resumeId);
    } else {
      _startConversation();
    }
  }

  Future<void> _send([String? textOverride]) async {
    final text = (textOverride ?? _textController.text).trim();
    if (text.isEmpty || _sending || _conversationId == null) return;
    final service = ref.read(kaiwaChatServiceProvider);
    if (service == null) return;
    final levelCode = ref.read(selectedLevelCodeProvider);

    // Hiện ngay bong bóng của người dùng + xoá ô nhập trước khi mạng trả lời —
    // gọi AI + ghi DB mất vài giây, không nên để màn hình đứng im trong lúc đó.
    final historySnapshot = List<KaiwaMessage>.of(_messages);
    final optimisticId = 'pending-${DateTime.now().microsecondsSinceEpoch}';
    setState(() {
      _messages.add(KaiwaMessage(id: optimisticId, role: KaiwaMessageRole.user, contentJp: text));
      _sending = true;
      _textController.clear();
      _suggestionVisible = false;
    });
    _scrollToBottom();

    try {
      final result = await service.sendMessage(
        conversationId: _conversationId!,
        persona: widget.persona,
        scenario: widget.scenario,
        levelCode: levelCode,
        history: historySnapshot,
        text: text,
      );
      if (!mounted) return;
      setState(() {
        final idx = _messages.indexWhere((m) => m.id == optimisticId);
        if (idx != -1) {
          _messages[idx] = result.userMessage;
        } else {
          _messages.add(result.userMessage);
        }
        _messages.add(result.aiMessage);
        _sending = false;
      });
      ref.invalidate(kaiwaConversationsProvider);
      _scrollToBottom();
      unawaited(_speakAi(result.aiMessage.contentJp));
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _messages.removeWhere((m) => m.id == optimisticId);
        _sending = false;
        _textController.text = text;
      });
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text('Lỗi gửi tin nhắn: $e')));
    }
  }

  String _friendlySpeechError(String code) {
    switch (code) {
      case 'error_no_match':
      case 'error_speech_timeout':
        return 'Không nghe rõ, hãy thử lại và nói to hơn.';
      case 'error_insufficient_permissions':
        return 'Chưa cấp quyền micro — vào Cài đặt > Ứng dụng để bật.';
      case 'error_network':
      case 'error_network_timeout':
        return 'Lỗi mạng khi ghi âm, kiểm tra kết nối và thử lại.';
      default:
        return 'Lỗi ghi âm ($code), hãy thử lại.';
    }
  }

  // Chỉ xin quyền mic/nhận diện giọng nói ở lần bấm mic ĐẦU TIÊN — không xin
  // ngay khi vào màn hình (initState) để tránh hộp thoại hệ thống che màn
  // hình và giành audio session ngay lúc TTS đang tự đọc lời chào của AI.
  Future<bool> _ensureSpeechInitialized() async {
    if (_speechInitStarted) return _speechAvailable;
    _speechInitStarted = true;
    final ok = await _speech.initialize(
      onError: (error) {
        if (!mounted) return;
        setState(() => _isListening = false);
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(_friendlySpeechError(error.errorMsg))));
      },
      onStatus: (status) {
        if (!mounted) return;
        if (status == 'done' || status == 'notListening') {
          _stopRecordingTimer();
          setState(() => _isListening = false);
        }
      },
    );
    if (mounted) setState(() => _speechAvailable = ok);
    return ok;
  }

  Future<void> _toggleListening() async {
    if (_ttsSpeaking) return;
    if (_isListening) {
      _stopRecordingTimer();
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
    // hasPermission chỉ đúng nếu quyền đã bị từ chối trước đó — Android không
    // cho app tự bật lại hộp thoại hệ thống, phải hướng người dùng vào Cài đặt.
    if (!await _speech.hasPermission) {
      if (!mounted) return;
      const snackBar = SnackBar(
        duration: Duration(seconds: 6),
        content: Text(
          'Chưa có quyền micro. Vào Cài đặt điện thoại > Ứng dụng > Nihongo > Quyền > bật Micro, rồi thử lại.',
        ),
      );
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(snackBar);
      return;
    }
    setState(() {
      _isListening = true;
      _isSpeechDraft = false;
      _speechLowConfidence = false;
    });
    _startRecordingTimer();
    try {
      await _speech.listen(
        onResult: (result) {
          // An toàn thêm — nếu AI bắt đầu đọc đúng lúc kết quả STT đang bay về
          // (race condition hiếm) thì bỏ qua, không ghi đè vào khung chat.
          if (_ttsSpeaking) return;
          _applyingSpeechText = true;
          setState(() {
            _textController.text = result.recognizedWords;
            _textController.selection = TextSelection.collapsed(offset: _textController.text.length);
            _isSpeechDraft = result.recognizedWords.isNotEmpty;
            if (result.finalResult) {
              _isListening = false;
              _speechLowConfidence = result.hasConfidenceRating && !result.isConfident();
            }
          });
          if (result.finalResult) _stopRecordingTimer();
          _applyingSpeechText = false;
        },
        listenOptions: SpeechListenOptions(localeId: 'ja_JP', partialResults: true),
      );
    } catch (e) {
      // listen() có thể throw đồng bộ (VD phiên trước chưa dọn xong) — trường
      // hợp này không đi qua onError của initialize(), phải tự bắt ở đây.
      if (!mounted) return;
      _stopRecordingTimer();
      setState(() => _isListening = false);
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text('Lỗi ghi âm: $e')));
    }
  }

  // Nút thùng rác trên thanh ghi âm — huỷ hẳn, không giữ lại chữ đã nhận diện.
  Future<void> _cancelListening() async {
    _stopRecordingTimer();
    await _speech.stop();
    if (!mounted) return;
    setState(() {
      _isListening = false;
      _textController.clear();
      _isSpeechDraft = false;
      _speechLowConfidence = false;
    });
  }

  // Nút gửi trên thanh ghi âm — dừng ghi & gửi luôn phần đã nhận diện được,
  // không cần đợi finalResult (người dùng chủ động xác nhận là đủ rồi).
  Future<void> _sendFromRecording() async {
    _stopRecordingTimer();
    await _speech.stop();
    if (mounted) setState(() => _isListening = false);
    await _send();
  }

  // Bấm icon vàng cạnh bong bóng người dùng → hiện phân tích ngữ pháp + câu
  // đã sửa đúng, giống mẫu tham khảo (ảnh app Emma).
  void _showFeedbackSheet(KaiwaMessage message) {
    final feedback = message.feedback;
    if (feedback == null || !feedback.hasContent) return;
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) => _FeedbackSheet(
        original: message.contentJp,
        feedback: feedback,
        onRetry: () {
          Navigator.of(sheetContext).pop();
          setState(() => _textController.text = message.contentJp);
        },
        onAskMore: () {
          Navigator.of(sheetContext).pop();
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => KaiwaTutorScreen(
                turn: KaiwaFeedbackContext(
                  originalSentence: message.contentJp,
                  betterPhrasing: feedback.betterPhrasing,
                  explanation: feedback.explanation,
                  commonMistake: feedback.commonMistake,
                  grammarNote: feedback.grammar,
                  vocabularyNote: feedback.vocabulary,
                  politenessNote: feedback.politeness,
                  personaName: widget.persona.name,
                  scenarioTitle: widget.scenario.title,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // Kết thúc hội thoại hiện tại → xác nhận rồi sang màn tóm tắt thật (tính
  // từ đúng dữ liệu đã lưu của hội thoại này). "Kết thúc" không xoá gì cả —
  // vẫn mở lại được từ Dashboard/Lịch sử sau đó, chỉ là điểm dừng để xem lại.
  Future<void> _confirmEndConversation() async {
    final conversationId = _conversationId;
    if (conversationId == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Kết thúc hội thoại này?'),
        content: const Text('Bạn sẽ xem tóm tắt buổi hội thoại — vẫn có thể tiếp tục lại sau từ Dashboard.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(false), child: const Text('Huỷ')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.teal),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Kết thúc'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    _tts.stop();
    if (_isListening) await _speech.stop();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => KaiwaSummaryScreen(
          conversationId: conversationId,
          persona: widget.persona,
          scenario: widget.scenario,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: AppColors.teal,
              child: Text(widget.persona.glyph, style: AppFonts.zenMaruGothic(fontSize: 13, color: Colors.white)),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.persona.name, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.ink)),
                  Text(widget.scenario.title, style: const TextStyle(fontSize: 11, color: AppColors.inkSoft)),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: _autoSpeak ? 'Tắt tự động đọc' : 'Bật tự động đọc',
            icon: Icon(_autoSpeak ? Icons.volume_up_rounded : Icons.volume_off_rounded, color: _autoSpeak ? AppColors.teal : AppColors.inkFaint),
            onPressed: () {
              if (_autoSpeak) _tts.stop();
              setState(() => _autoSpeak = !_autoSpeak);
            },
          ),
          IconButton(
            tooltip: 'Chọn giọng đọc',
            icon: const Icon(Icons.record_voice_over_outlined, color: AppColors.inkFaint),
            onPressed: _openVoicePicker,
          ),
          IconButton(
            tooltip: _showFurigana ? 'Ẩn cách đọc hiragana' : 'Hiện cách đọc hiragana',
            icon: Icon(Icons.subtitles_outlined, color: _showFurigana ? AppColors.teal : AppColors.inkFaint),
            onPressed: () => setState(() => _showFurigana = !_showFurigana),
          ),
          IconButton(
            tooltip: _showTranslation ? 'Ẩn bản dịch' : 'Hiện bản dịch',
            icon: Icon(Icons.translate, color: _showTranslation ? AppColors.teal : AppColors.inkFaint),
            onPressed: () => setState(() => _showTranslation = !_showTranslation),
          ),
          PopupMenuButton<String>(
            tooltip: 'Thêm',
            icon: const Icon(Icons.more_vert, color: AppColors.inkFaint),
            onSelected: (value) {
              if (value == 'end') _confirmEndConversation();
            },
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'end', child: Text('Kết thúc hội thoại')),
            ],
          ),
        ],
      ),
      body: SafeArea(
        child: _starting
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(_error!, textAlign: TextAlign.center),
                          const SizedBox(height: 16),
                          FilledButton(
                            style: FilledButton.styleFrom(backgroundColor: AppColors.teal),
                            onPressed: _retryStart,
                            child: const Text('Thử lại'),
                          ),
                        ],
                      ),
                    ),
                  )
                : Column(
                    children: [
                      if (widget.seedWord != null)
                        Container(
                          width: double.infinity,
                          color: AppColors.tealSoft,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          child: Row(
                            children: [
                              const Icon(Icons.lightbulb_outline_rounded, size: 14, color: AppColors.teal),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  'Gợi ý: thử dùng từ "${widget.seedWord}" trong hội thoại này',
                                  style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: AppColors.teal),
                                ),
                              ),
                            ],
                          ),
                        ),
                      Expanded(
                        child: ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                          itemCount: _messages.length + (_sending ? 1 : 0),
                          itemBuilder: (context, i) {
                            if (i == _messages.length) {
                              return _TypingBubble(persona: widget.persona);
                            }
                            return _MessageBubble(
                              message: _messages[i],
                              persona: widget.persona,
                              showTranslation: _showTranslation,
                              showFurigana: _showFurigana,
                              onSpeak: (text) => _speak(text),
                              onShowFeedback: () => _showFeedbackSheet(_messages[i]),
                            );
                          },
                        ),
                      ),
                      _SuggestionBar(
                        suggestion: _lastAiMessage?.suggestedReplyJp,
                        translation: _lastAiMessage?.suggestedReplyVi,
                        visible: _suggestionVisible,
                        enabled: !_sending && !_isListening,
                        onToggle: () => setState(() => _suggestionVisible = !_suggestionVisible),
                        onUse: _useSuggestion,
                      ),
                      // _InputBar giữ nguyên vị trí trong cây widget dù đang gửi hay
                      // không — nếu chèn/xoá 1 widget khác kiểu ngay phía trên nó,
                      // Flutter sẽ huỷ và tạo lại TextField mỗi lần gửi tin, làm mất
                      // focus/bàn phím giữa lúc đang trò chuyện.
                      _InputBar(
                        key: const ValueKey('kaiwa-input-bar'),
                        controller: _textController,
                        sending: _sending,
                        isListening: _isListening,
                        speechAvailable: _speechAvailable,
                        ttsSpeaking: _ttsSpeaking,
                        isSpeechDraft: _isSpeechDraft,
                        speechLowConfidence: _speechLowConfidence,
                        recordingSeconds: _recordingSeconds,
                        onMic: _toggleListening,
                        onSend: () => _send(),
                        onCancelRecording: _cancelListening,
                        onSendRecording: _sendFromRecording,
                      ),
                    ],
                  ),
      ),
    );
  }
}

class _InputBar extends StatelessWidget {
  const _InputBar({
    super.key,
    required this.controller,
    required this.sending,
    required this.isListening,
    required this.speechAvailable,
    required this.ttsSpeaking,
    required this.isSpeechDraft,
    required this.speechLowConfidence,
    required this.recordingSeconds,
    required this.onMic,
    required this.onSend,
    required this.onCancelRecording,
    required this.onSendRecording,
  });

  final TextEditingController controller;
  final bool sending;
  final bool isListening;
  final bool speechAvailable;
  final bool ttsSpeaking;
  final bool isSpeechDraft;
  final bool speechLowConfidence;
  final int recordingSeconds;
  final VoidCallback onMic;
  final VoidCallback onSend;
  final VoidCallback onCancelRecording;
  final VoidCallback onSendRecording;

  @override
  Widget build(BuildContext context) {
    final warnColor = speechLowConfidence ? AppColors.accent : AppColors.teal;
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
      decoration: const BoxDecoration(
        color: AppColors.card,
        border: Border(top: BorderSide(color: AppColors.border, width: 1.0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Nhắc rà lại câu vì STT hệ thống không biết ngữ cảnh hội thoại nên
          // hay đoán sai từ — đặc biệt khi confidence thấp thì cảnh báo rõ hơn.
          if (isSpeechDraft && !isListening) ...[
            Padding(
              padding: const EdgeInsets.only(left: 44, bottom: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.hearing_outlined, size: 13, color: warnColor),
                  const SizedBox(width: 4),
                  Text(
                    speechLowConfidence
                        ? 'Nghe không rõ — kiểm tra kỹ trước khi gửi'
                        : 'Nhận diện giọng nói — kiểm tra trước khi gửi',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: warnColor),
                  ),
                ],
              ),
            ),
          ],
          if (isListening)
            _RecordingBar(
              seconds: recordingSeconds,
              onCancel: onCancelRecording,
              onPause: onMic,
              onSend: onSendRecording,
            )
          else
            Row(
              children: [
                IconButton(
                  tooltip: !speechAvailable
                      ? 'Không hỗ trợ giọng nói trên thiết bị này'
                      : ttsSpeaking
                          ? 'Đợi nhân vật đọc xong đã'
                          : 'Nói bằng giọng nói',
                  icon: Icon(
                    Icons.mic_none,
                    color: speechAvailable && !ttsSpeaking ? AppColors.teal : AppColors.inkFaint,
                  ),
                  onPressed: speechAvailable && !ttsSpeaking ? onMic : null,
                ),
                Expanded(
                  child: TextField(
                    controller: controller,
                    minLines: 1,
                    maxLines: 4,
                    decoration: InputDecoration(
                      hintText: 'Nhập hoặc nói câu tiếng Nhật...',
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      enabledBorder: isSpeechDraft
                          ? OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: warnColor, width: 1.2))
                          : null,
                      focusedBorder: isSpeechDraft
                          ? OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: warnColor, width: 1.6))
                          : null,
                    ),
                    onSubmitted: (_) => onSend(),
                  ),
                ),
                const SizedBox(width: 6),
                IconButton(
                  tooltip: 'Gửi',
                  icon: const Icon(Icons.send_rounded, color: AppColors.teal),
                  onPressed: sending ? null : onSend,
                ),
              ],
            ),
        ],
      ),
    );
  }
}

/// Thanh ghi âm thay cho ô nhập chữ khi đang nói — thùng rác (huỷ), nút tạm
/// dừng (dừng nhận diện, giữ lại chữ), waveform minh hoạ đang nghe, thời gian
/// đã ghi, và nút gửi luôn phần đã nhận diện được.
class _RecordingBar extends StatelessWidget {
  const _RecordingBar({
    required this.seconds,
    required this.onCancel,
    required this.onPause,
    required this.onSend,
  });

  final int seconds;
  final VoidCallback onCancel;
  final VoidCallback onPause;
  final VoidCallback onSend;

  String get _timeLabel {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          tooltip: 'Huỷ ghi âm',
          icon: const Icon(Icons.delete_outline_rounded, color: AppColors.inkFaint),
          onPressed: onCancel,
        ),
        InkWell(
          borderRadius: BorderRadius.circular(100),
          onTap: onPause,
          child: Container(
            width: 34,
            height: 34,
            decoration: const BoxDecoration(color: AppColors.teal, shape: BoxShape.circle),
            alignment: Alignment.center,
            child: const Icon(Icons.pause_rounded, color: Colors.white, size: 18),
          ),
        ),
        const SizedBox(width: 10),
        const Expanded(child: _RecordingWaveform()),
        const SizedBox(width: 8),
        Text(_timeLabel, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppColors.inkSoft)),
        const SizedBox(width: 8),
        InkWell(
          borderRadius: BorderRadius.circular(100),
          onTap: onSend,
          child: Container(
            width: 34,
            height: 34,
            decoration: const BoxDecoration(color: AppColors.teal, shape: BoxShape.circle),
            alignment: Alignment.center,
            child: const Icon(Icons.arrow_upward_rounded, color: Colors.white, size: 18),
          ),
        ),
      ],
    );
  }
}

/// Dãy cột nhấp nháy minh hoạ đang ghi âm — chỉ là hiệu ứng hình ảnh (không
/// đọc biên độ âm thanh thật từ mic, gói speech_to_text không lộ dữ liệu đó),
/// đổi ngẫu nhiên chiều cao mỗi 400ms để trông như đang "nghe".
class _RecordingWaveform extends StatefulWidget {
  const _RecordingWaveform();

  @override
  State<_RecordingWaveform> createState() => _RecordingWaveformState();
}

class _RecordingWaveformState extends State<_RecordingWaveform> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  final _random = Random();
  late List<double> _heights;

  @override
  void initState() {
    super.initState();
    _heights = _randomHeights();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 400))
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          setState(() => _heights = _randomHeights());
          _controller.forward(from: 0);
        }
      })
      ..forward();
  }

  List<double> _randomHeights() => List.generate(24, (_) => 0.25 + _random.nextDouble() * 0.75);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 22,
      child: Row(
        children: [
          for (final h in _heights)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 1),
                child: Container(
                  height: 22 * h,
                  decoration: BoxDecoration(color: AppColors.teal, borderRadius: BorderRadius.circular(2)),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Chip + thẻ xem trước "Gợi ý trả lời" — AI đã kèm sẵn 1 câu gợi ý mỗi lượt
/// nói (không tốn thêm lần gọi API nào), chip chỉ bật/tắt hiển thị. Bấm
/// "Dùng câu này" điền vào ô nhập để người học vẫn xem/sửa trước khi gửi,
/// không gửi thẳng — tránh biến hội thoại thành "AI tự nói chuyện với AI".
class _SuggestionBar extends StatelessWidget {
  const _SuggestionBar({
    required this.suggestion,
    required this.translation,
    required this.visible,
    required this.enabled,
    required this.onToggle,
    required this.onUse,
  });

  final String? suggestion;
  final String? translation;
  final bool visible;
  final bool enabled;
  final VoidCallback onToggle;
  final ValueChanged<String> onUse;

  @override
  Widget build(BuildContext context) {
    final text = suggestion?.trim() ?? '';
    if (text.isEmpty) return const SizedBox.shrink();
    return Container(
      color: AppColors.card,
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(100),
            onTap: enabled ? onToggle : null,
            child: Opacity(
              opacity: enabled ? 1 : 0.5,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: visible ? AppColors.teal : AppColors.tealSoft,
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.lightbulb_outline_rounded, size: 15, color: visible ? Colors.white : AppColors.teal),
                    const SizedBox(width: 5),
                    Text(
                      'Gợi ý trả lời',
                      style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: visible ? Colors.white : AppColors.teal),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (visible) ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: AppColors.tealSoft, borderRadius: BorderRadius.circular(14)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(text, style: AppFonts.zenMaruGothic(fontSize: 15, color: AppColors.ink, fontWeight: FontWeight.w600)),
                  if ((translation ?? '').trim().isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(translation!.trim(), style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: AppColors.inkSoft)),
                  ],
                  const SizedBox(height: 6),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => onUse(text),
                      style: TextButton.styleFrom(foregroundColor: AppColors.teal, padding: const EdgeInsets.symmetric(horizontal: 10)),
                      child: const Text('Dùng câu này', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _TypingBubble extends StatelessWidget {
  const _TypingBubble({required this.persona});

  final KaiwaPersona persona;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: AppColors.tealSoft,
            child: Text(persona.glyph, style: AppFonts.zenMaruGothic(fontSize: 11, color: AppColors.teal)),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border, width: 1.0),
            ),
            child: const SizedBox(
              height: 14,
              width: 14,
              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.teal),
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({
    required this.message,
    required this.persona,
    required this.showTranslation,
    required this.showFurigana,
    required this.onSpeak,
    required this.onShowFeedback,
  });

  final KaiwaMessage message;
  final KaiwaPersona persona;
  final bool showTranslation;
  final bool showFurigana;
  final void Function(String text) onSpeak;
  final VoidCallback onShowFeedback;

  @override
  Widget build(BuildContext context) {
    final isAi = message.role == KaiwaMessageRole.ai;
    final hasFeedback = !isAi && message.feedback != null && message.feedback!.hasContent;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: isAi ? CrossAxisAlignment.start : CrossAxisAlignment.end,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (isAi) ...[
                CircleAvatar(
                  radius: 14,
                  backgroundColor: AppColors.tealSoft,
                  child: Text(persona.glyph, style: AppFonts.zenMaruGothic(fontSize: 11, color: AppColors.teal)),
                ),
                const SizedBox(width: 8),
              ],
              if (hasFeedback) ...[
                _FeedbackIconButton(onTap: onShowFeedback),
                const SizedBox(width: 6),
              ],
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: isAi ? AppColors.card : AppColors.teal,
                    borderRadius: BorderRadius.circular(16),
                    border: isAi ? Border.all(color: AppColors.border, width: 1.0) : null,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        message.contentJp,
                        style: TextStyle(fontSize: 15, height: 1.4, color: isAi ? AppColors.ink : Colors.white, fontWeight: FontWeight.w600),
                      ),
                      if (showFurigana && (message.furigana?.isNotEmpty ?? false)) ...[
                        const SizedBox(height: 4),
                        Text(
                          message.furigana!,
                          style: TextStyle(fontSize: 11.5, color: isAi ? AppColors.inkSoft : Colors.white70),
                        ),
                      ],
                      if (showTranslation && (message.translationVi?.isNotEmpty ?? false)) ...[
                        const SizedBox(height: 4),
                        Text(
                          message.translationVi!,
                          style: TextStyle(fontSize: 12.5, fontStyle: FontStyle.italic, color: isAi ? AppColors.inkSoft : Colors.white70),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              if (isAi) ...[
                const SizedBox(width: 4),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Icons.volume_up_outlined, size: 18, color: AppColors.inkFaint),
                  onPressed: () => onSpeak(message.contentJp),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

/// Icon vàng cạnh bong bóng người dùng — bấm vào mở `_FeedbackSheet` phân
/// tích ngữ pháp, giống mẫu tham khảo (ảnh app Emma) thay vì hiện thẳng thẻ
/// feedback dưới mỗi tin nhắn như trước (chiếm chỗ, gây rối mắt khi hội thoại dài).
class _FeedbackIconButton extends StatelessWidget {
  const _FeedbackIconButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(100),
      onTap: onTap,
      child: Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(color: AppColors.accent.withValues(alpha: 0.16), shape: BoxShape.circle),
        alignment: Alignment.center,
        child: const Icon(Icons.priority_high_rounded, size: 15, color: AppColors.accent),
      ),
    );
  }
}

/// Bottom sheet phân tích ngữ pháp — câu gốc (gạch ngang) + câu đã sửa đúng
/// (nếu AI có gợi ý sửa khác câu gốc), giải thích ngắn, và phần "phân tích
/// chi tiết" mở rộng (điểm số + nhận xét từng mặt) giữ nguyên dữ liệu cũ của
/// `_FeedbackCard` nhưng ẩn mặc định để phần chính (câu sửa + giải thích)
/// không bị loãng.
class _FeedbackSheet extends StatefulWidget {
  const _FeedbackSheet({
    required this.original,
    required this.feedback,
    required this.onRetry,
    required this.onAskMore,
  });

  final String original;
  final KaiwaFeedback feedback;
  final VoidCallback onRetry;
  final VoidCallback onAskMore;

  @override
  State<_FeedbackSheet> createState() => _FeedbackSheetState();
}

class _FeedbackSheetState extends State<_FeedbackSheet> {
  bool _detailsVisible = false;

  @override
  Widget build(BuildContext context) {
    final feedback = widget.feedback;
    final corrected = feedback.betterPhrasing.trim();
    final hasCorrection = corrected.isNotEmpty && corrected != widget.original.trim();
    final details = <(String, String)>[
      ('Tự nhiên', feedback.naturalness),
      ('Ngữ pháp', feedback.grammar),
      ('Từ vựng', feedback.vocabulary),
      ('Lịch sự', feedback.politeness),
      ('Giống người Nhật', feedback.nativeLikeness),
    ].where((d) => d.$2.trim().isNotEmpty).toList();

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(18, 2, 18, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text('Phân tích ngữ pháp', style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.w700, color: AppColors.ink)),
                ),
                for (var i = 0; i < 5; i++)
                  Icon(i < feedback.rating ? Icons.star_rounded : Icons.star_border_rounded, size: 15, color: AppColors.teal),
                const SizedBox(width: 8),
                InkWell(
                  onTap: widget.onRetry,
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    child: Text('Thử lại', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.teal)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            _FeedbackTextRow(
              icon: Icons.close_rounded,
              iconColor: AppColors.danger,
              strikethrough: hasCorrection,
              highlighted: false,
              text: widget.original,
            ),
            if (hasCorrection) ...[
              const SizedBox(height: 8),
              _FeedbackTextRow(
                icon: Icons.check_rounded,
                iconColor: AppColors.moss,
                strikethrough: false,
                highlighted: true,
                text: corrected,
              ),
            ],
            if (feedback.explanation.isNotEmpty) ...[
              const SizedBox(height: 14),
              Text(feedback.explanation, style: const TextStyle(fontSize: 13, height: 1.45, color: AppColors.inkSoft)),
            ],
            if (feedback.commonMistake.isNotEmpty) ...[
              const SizedBox(height: 10),
              _FeedbackLine(icon: Icons.error_outline_rounded, text: feedback.commonMistake),
            ],
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: widget.onAskMore,
                style: OutlinedButton.styleFrom(foregroundColor: AppColors.teal, side: const BorderSide(color: AppColors.teal)),
                icon: const Icon(Icons.chat_bubble_outline_rounded, size: 16),
                label: const Text('Hỏi AI thêm về câu này'),
              ),
            ),
            if (details.isNotEmpty) ...[
              const SizedBox(height: 16),
              InkWell(
                borderRadius: BorderRadius.circular(100),
                onTap: () => setState(() => _detailsVisible = !_detailsVisible),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 11),
                  decoration: BoxDecoration(color: AppColors.tealSoft, borderRadius: BorderRadius.circular(100)),
                  alignment: Alignment.center,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.auto_awesome_rounded, size: 15, color: AppColors.teal),
                      const SizedBox(width: 6),
                      Text(
                        _detailsVisible ? 'Ẩn phân tích chi tiết' : 'Phân tích chi tiết',
                        style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.teal),
                      ),
                    ],
                  ),
                ),
              ),
              if (_detailsVisible) ...[
                const SizedBox(height: 10),
                for (final d in details) _FeedbackDetailRow(label: d.$1, text: d.$2),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

class _FeedbackTextRow extends StatelessWidget {
  const _FeedbackTextRow({
    required this.icon,
    required this.iconColor,
    required this.strikethrough,
    required this.highlighted,
    required this.text,
  });

  final IconData icon;
  final Color iconColor;
  final bool strikethrough;
  final bool highlighted;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 22,
          height: 22,
          margin: const EdgeInsets.only(top: 3),
          decoration: BoxDecoration(shape: BoxShape.circle, color: iconColor.withValues(alpha: 0.15)),
          alignment: Alignment.center,
          child: Icon(icon, size: 13, color: iconColor),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: highlighted ? AppColors.mossSoft : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              border: highlighted ? null : Border.all(color: AppColors.border, width: 1.2),
            ),
            child: Text(
              text,
              style: AppFonts.zenMaruGothic(
                fontSize: 14.5,
                color: AppColors.ink,
              ).copyWith(
                decoration: strikethrough ? TextDecoration.lineThrough : null,
                decorationColor: AppColors.inkFaint,
                decorationThickness: 1.4,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _FeedbackDetailRow extends StatelessWidget {
  const _FeedbackDetailRow({required this.label, required this.text});

  final String label;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(fontSize: 12, height: 1.4, color: AppColors.inkSoft),
          children: [
            TextSpan(text: '$label: ', style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.ink)),
            TextSpan(text: text),
          ],
        ),
      ),
    );
  }
}

class _FeedbackLine extends StatelessWidget {
  const _FeedbackLine({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 14, color: AppColors.teal),
        const SizedBox(width: 6),
        Expanded(child: Text(text, style: const TextStyle(fontSize: 11.5, color: AppColors.inkSoft, height: 1.3))),
      ],
    );
  }
}
