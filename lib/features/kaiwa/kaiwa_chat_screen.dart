import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:speech_to_text/speech_to_text.dart';

import '../../core/theme/app_theme.dart';
import '../../domain/entities/kaiwa_message.dart';
import '../../domain/entities/kaiwa_persona.dart';
import '../../domain/entities/kaiwa_scenario.dart';
import '../lesson/providers/level_providers.dart';
import 'providers/kaiwa_chat_service.dart';

const _voiceNamePrefKey = 'kaiwa_tts_voice_name';
const _voiceLocalePrefKey = 'kaiwa_tts_voice_locale';

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
  const KaiwaChatScreen({super.key, required this.persona, required this.scenario});

  final KaiwaPersona persona;
  final KaiwaScenario scenario;

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
    WidgetsBinding.instance.addPostFrameCallback((_) => _startConversation());
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    _speech.stop();
    _tts.stop();
    super.dispose();
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
    if (wasListening) _speech.stop();
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
      );
      if (!mounted) return;
      setState(() {
        _conversationId = result.conversationId;
        _messages.add(result.aiMessage);
        _starting = false;
      });
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
      await _speech.stop();
      setState(() => _isListening = false);
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
          _applyingSpeechText = false;
        },
        listenOptions: SpeechListenOptions(localeId: 'ja_JP', partialResults: true),
      );
    } catch (e) {
      // listen() có thể throw đồng bộ (VD phiên trước chưa dọn xong) — trường
      // hợp này không đi qua onError của initialize(), phải tự bắt ở đây.
      if (!mounted) return;
      setState(() => _isListening = false);
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text('Lỗi ghi âm: $e')));
    }
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
                            onPressed: _startConversation,
                            child: const Text('Thử lại'),
                          ),
                        ],
                      ),
                    ),
                  )
                : Column(
                    children: [
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
                              onRetry: () => setState(() => _textController.text = _messages[i].contentJp),
                            );
                          },
                        ),
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
                        onMic: _toggleListening,
                        onSend: () => _send(),
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
    required this.onMic,
    required this.onSend,
  });

  final TextEditingController controller;
  final bool sending;
  final bool isListening;
  final bool speechAvailable;
  final bool ttsSpeaking;
  final bool isSpeechDraft;
  final bool speechLowConfidence;
  final VoidCallback onMic;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    final warnColor = speechLowConfidence ? AppColors.accent : AppColors.teal;
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
      decoration: const BoxDecoration(
        color: AppColors.card,
        border: Border(top: BorderSide(color: AppColors.border, width: 0.6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Nhắc rà lại câu vì STT hệ thống không biết ngữ cảnh hội thoại nên
          // hay đoán sai từ — đặc biệt khi confidence thấp thì cảnh báo rõ hơn.
          if (isSpeechDraft) ...[
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
          Row(
            children: [
              IconButton(
                tooltip: !speechAvailable
                    ? 'Không hỗ trợ giọng nói trên thiết bị này'
                    : ttsSpeaking
                        ? 'Đợi nhân vật đọc xong đã'
                        : (isListening ? 'Dừng ghi âm' : 'Nói bằng giọng nói'),
                icon: Icon(
                  isListening ? Icons.mic : Icons.mic_none,
                  color: isListening ? AppColors.accent : (speechAvailable && !ttsSpeaking ? AppColors.teal : AppColors.inkFaint),
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
              border: Border.all(color: AppColors.border, width: 0.6),
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
    required this.onRetry,
  });

  final KaiwaMessage message;
  final KaiwaPersona persona;
  final bool showTranslation;
  final bool showFurigana;
  final void Function(String text) onSpeak;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final isAi = message.role == KaiwaMessageRole.ai;
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
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: isAi ? AppColors.card : AppColors.teal,
                    borderRadius: BorderRadius.circular(16),
                    border: isAi ? Border.all(color: AppColors.border, width: 0.6) : null,
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
          if (!isAi && message.feedback != null && message.feedback!.hasContent) ...[
            const SizedBox(height: 6),
            _FeedbackCard(feedback: message.feedback!, onRetry: onRetry),
          ],
        ],
      ),
    );
  }
}

class _FeedbackCard extends StatelessWidget {
  const _FeedbackCard({required this.feedback, required this.onRetry});

  final KaiwaFeedback feedback;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 300),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: AppColors.tealSoft, borderRadius: BorderRadius.circular(14)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              for (var i = 0; i < 5; i++)
                Icon(i < feedback.rating ? Icons.star_rounded : Icons.star_border_rounded, size: 16, color: AppColors.teal),
              const Spacer(),
              InkWell(
                onTap: onRetry,
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  child: Text('Thử lại', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: AppColors.teal)),
                ),
              ),
            ],
          ),
          if (feedback.explanation.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(feedback.explanation, style: const TextStyle(fontSize: 12, color: AppColors.ink, height: 1.35)),
          ],
          if (feedback.commonMistake.isNotEmpty) ...[
            const SizedBox(height: 6),
            _FeedbackLine(icon: Icons.error_outline_rounded, text: feedback.commonMistake),
          ],
          if (feedback.betterPhrasing.isNotEmpty) ...[
            const SizedBox(height: 4),
            _FeedbackLine(icon: Icons.lightbulb_outline_rounded, text: feedback.betterPhrasing),
          ],
        ],
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
