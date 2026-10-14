import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:go_router/go_router.dart';

import '../../core/services/dialogue_audio.dart';
import '../../core/services/dialogue_player.dart';
import '../../core/services/jp_voice_prefs.dart';
import '../../core/theme/app_motion.dart';
import '../../core/theme/app_theme.dart';
import '../../domain/entities/lesson.dart' show LessonItemType;
import '../../domain/services/quiz_generator.dart';
import '../../shared/motion/animated_count.dart';
import '../../shared/motion/animated_progress_bar.dart';
import '../../shared/motion/confetti_burst.dart';
import '../../shared/motion/answer_feedback.dart';
import '../../shared/motion/enter_transition.dart';
import '../../shared/motion/playing_indicator.dart';
import '../../shared/motion/press_scale.dart';
import '../home/providers/mission_providers.dart';
import '../home/providers/profile_providers.dart';
import 'providers/quiz_providers.dart';
import 'widgets/countdown_ring.dart';
import 'widgets/listening_question_body.dart';

/// Màn quiz trắc nghiệm dùng chung cho cả 3 lối vào (theo bài học / theo
/// trình độ / nghe hiểu) — chỉ nhận [questions] đã resolve sẵn, không tự
/// watch provider bên trong để tách biệt UI/state khỏi nguồn dữ liệu.
///
/// Không tự phát âm ở bất kỳ thời điểm nào (vào câu, chọn đáp án, mở script,
/// xem kết quả): chỉ nút loa/Play do người dùng bấm mới đọc, và chỉ đọc đúng
/// nội dung gắn với nút đó.
///
/// [listeningMode]: ẩn chữ Nhật cho tới khi trả lời — biến đúng bộ câu hỏi đó
/// thành bài luyện nghe thay vì luyện đọc.
///
/// [timedMode]: thêm 1 đồng hồ đếm ngược cho TOÀN BÀI (khác đồng hồ
/// [_secondsPerQuestion] mỗi câu vốn luôn bật) — hết giờ toàn bài thì kết
/// thúc quiz ngay dù đang ở câu nào, xem `docs/MIXED_QUIZ_DESIGN.md` §4.
///
/// [survivalMode]: dừng quiz ngay sau khi người dùng bấm "Tiếp tục" ở câu
/// đầu tiên trả lời sai/hết giờ, không đợi hết tim hay hết câu — khác chế
/// độ mặc định (chơi hết [_heartsMax] tim).
class QuizScreen extends ConsumerStatefulWidget {
  const QuizScreen({
    super.key,
    required this.questions,
    required this.title,
    this.listeningMode = false,
    this.timedMode = false,
    this.survivalMode = false,
  });

  final List<QuizQuestion> questions;
  final String title;
  final bool listeningMode;
  final bool timedMode;
  final bool survivalMode;

  @override
  ConsumerState<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends ConsumerState<QuizScreen>
    with SingleTickerProviderStateMixin {
  static const _heartsMax = 5;
  static const _secondsPerQuestion = 15;
  static const _xpPerCorrect = 10;

  /// Ngân sách giây/câu khi tính giờ TOÀN BÀI ([QuizScreen.timedMode]) — rộng
  /// rãi hơn hạn 15s/câu bắt buộc (`_secondsPerQuestion`) vì đây là tổng cho
  /// cả bài, người chơi có thể trả lời nhanh câu này để bù giờ cho câu khó
  /// hơn, không phải hạn cứng từng câu.
  static const _wholeQuizSecondsPerQuestion = 20;

  late final AnimationController _timerController;
  late final FlutterTts _tts;
  final DialoguePlayer _player = DialoguePlayer();

  /// Audio cloud tạo sẵn (giọng tự nhiên) cho câu đơn; chưa có file → TTS máy.
  final DialogueAudio _audio = DialogueAudio();

  /// Đang đọc 1 câu đơn (không phải hội thoại) — để nút nghe đổi thành tạm dừng.
  bool _speakingSingle = false;
  AudioPlaybackSpeed _speed = AudioPlaybackSpeed.x100;
  int _singleToken = 0;

  /// Nghe hiểu hội thoại: người học đã bấm "Scriptを見る" ở câu hiện tại chưa.
  /// Luôn về false khi sang câu mới ([_startTimerForCurrentQuestion]) — cùng
  /// với [_answered] quyết định [ListeningPhase], nên script không thể lộ ra
  /// khi đang nghe dù widget bị rebuild.
  bool _scriptOpen = false;
  final ScrollController _listeningScroll = ScrollController();
  /// Cuộn thân câu hỏi thường + khoá thẻ đáp án đúng: khung phản hồi hiện ra
  /// làm vùng cuộn thấp lại, đáp án đúng có thể bị đẩy khỏi màn hình.
  final ScrollController _bodyScroll = ScrollController();
  final GlobalKey _correctOptionKey = GlobalKey();
  Timer? _revealTimer;
  Timer? _wholeQuizTimer;
  int? _wholeQuizSecondsLeft;

  int _index = 0;
  int _hearts = _heartsMax;
  int _correctCount = 0;
  /// Số câu THẬT SỰ đã tới (không phải luôn bằng `questions.length`) — chế
  /// độ sinh tồn/tính giờ toàn bài có thể kết thúc sớm giữa chừng, xem
  /// [_finishQuiz]. Dùng làm mẫu số ở `_SummaryPanel` thay vì
  /// `widget.questions.length` để không hiện sai kiểu "3/20" (ngầm hiểu đã
  /// làm hết 20 câu) khi thực ra mới tới câu 3 thì dừng.
  int _attemptedCount = 0;
  int? _selectedOption;
  bool _answered = false;
  bool _timedOut = false;
  bool _isCorrect = false;
  int _combo = 0;
  int _bestCombo = 0;
  int? _lastXpGained;
  final Set<int> _hiddenOptions = {};
  bool _hintUsed = false;

  DateTime? _startedAt;
  Duration _elapsed = Duration.zero;

  /// Câu sai/hết giờ thật trong phiên — nguồn cho phần "Câu sai"/"Điểm yếu
  /// theo nhóm" ở `_SummaryPanel` (Task 9, `docs/MIXED_QUIZ_DESIGN.md` §5).
  /// Chỉ sống trong bộ nhớ phiên hiện tại, không ghi vào `review_mistakes`
  /// — Result Page chỉ hiện lại + dẫn link tới Sổ tay lỗi/Smart Review có
  /// sẵn, không tự thêm nguồn ghi dữ liệu mới ngoài phạm vi yêu cầu.
  final List<_QuizMistake> _mistakes = [];

  // Giọng đọc tiếng Nhật — dùng chung khoá lưu với AI Kaiwa (xem
  // jp_voice_prefs.dart), chọn giọng ở màn nào cũng áp dụng cho màn kia.
  List<Map<String, String>> _japaneseVoices = [];
  Map<String, String>? _selectedVoice;

  bool get _hasQuestions => widget.questions.isNotEmpty;
  bool get _isDone => _index >= widget.questions.length;

  @override
  void initState() {
    super.initState();
    _startedAt = DateTime.now();
    _timerController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: _secondsPerQuestion),
    )..addStatusListener(_onTimerStatusChanged);
    _tts = FlutterTts();
    _player.state.addListener(_onPlayerStateChanged);
    unawaited(_loadVoices());
    if (_hasQuestions) _startTimerForCurrentQuestion();
    if (widget.timedMode && _hasQuestions) _startWholeQuizTimer();
  }

  void _startWholeQuizTimer() {
    _wholeQuizSecondsLeft =
        widget.questions.length * _wholeQuizSecondsPerQuestion;
    _wholeQuizTimer?.cancel();
    _wholeQuizTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted || _isDone) {
        timer.cancel();
        return;
      }
      final left = (_wholeQuizSecondsLeft ?? 1) - 1;
      if (left <= 0) {
        timer.cancel();
        setState(() => _wholeQuizSecondsLeft = 0);
        _finishQuiz();
        return;
      }
      setState(() => _wholeQuizSecondsLeft = left);
    });
  }

  Future<void> _loadVoices() async {
    final cfg = await configureJpTts(_tts);
    final speed = await loadJpSpeechSpeed();
    if (!mounted) return;
    setState(() {
      _japaneseVoices = cfg.voices;
      _selectedVoice = cfg.saved;
      _speed = speed;
    });
  }

  Future<void> _selectVoice(Map<String, String> voice) async {
    await _tts.setVoice(voice);
    await saveJpVoice(voice);
    if (!mounted) return;
    setState(() => _selectedVoice = voice);
  }

  void _openVoicePicker() {
    showJpVoicePicker(
      context: context,
      voices: _japaneseVoices,
      selected: _selectedVoice,
      onSelected: _selectVoice,
      speed: _speed,
      onSpeedChanged: (s) {
        _speed = s;
        // Nghe hiểu hội thoại dùng DialoguePlayer riêng; câu đơn đọc ở lần sau.
        unawaited(_player.setSpeed(s));
      },
    );
  }

  @override
  void dispose() {
    _timerController.dispose();
    _wholeQuizTimer?.cancel();
    _revealTimer?.cancel();
    unawaited(_tts.stop());
    unawaited(_audio.dispose());
    _player.state.removeListener(_onPlayerStateChanged);
    _player.dispose();
    _listeningScroll.dispose();
    _bodyScroll.dispose();
    super.dispose();
  }

  /// Âm thanh chỉ phát khi người dùng chủ động bấm nút loa/Play — không bao
  /// giờ tự phát khi vào câu, chọn đáp án, mở script hay xem kết quả.
  void _stopAudio() {
    unawaited(_tts.stop());
    unawaited(_audio.stop());
    unawaited(_player.stop());
  }

  Future<void> _speakCurrent() async {
    if (!_hasQuestions || _isDone) return;
    final question = widget.questions[_index];
    final turns = question.dialogueTurns;
    // Câu đảo chiều (displayIsJapanese == false) hiện nghĩa tiếng Việt to
    // giữa màn — không đọc bằng giọng tiếng Nhật vì sẽ phát âm sai hoàn
    // toàn, không phải im lặng do lỗi.
    if (turns == null && !question.displayIsJapanese) return;
    // Câu điền chỗ trống chưa trả lời: đọc sẽ vô nghĩa/lộ đáp án.
    if (turns == null && question.hasBlank && !_answered) return;
    _runTimerIfWaitingForAudio();
    await applyIosTtsPlaybackCategory(_tts);
    await _tts.stop();
    await _audio.stop();
    if (turns == null || turns.isEmpty) {
      final token = ++_singleToken;
      if (mounted) setState(() => _speakingSingle = true);
      final jp = question.spokenJp;
      // Ưu tiên file cloud tạo sẵn (cùng bộ với nút loa ở màn Từ vựng/Ngữ
      // pháp); không có file hoặc mất mạng thì mới dùng giọng máy.
      final played = await _audio.playSentence(jp, _speed.multiplier);
      if (!played && mounted && token == _singleToken) {
        await _tts.setSpeechRate(_speed.ttsRate);
        await _tts.speak(prepareJpForSpeech(jp));
      }
      if (mounted && token == _singleToken) {
        setState(() => _speakingSingle = false);
      }
      return;
    }
    // Hội thoại: mỗi nhân vật 1 giọng, có tạm dừng — xem [DialoguePlayer].
    await _player.play(turns);
  }

  /// Nút nghe của câu đơn: đang đọc thì bấm để dừng, không thì đọc.
  void _toggleSingleAudio() {
    if (_speakingSingle) {
      _singleToken++;
      setState(() => _speakingSingle = false);
      unawaited(_tts.stop());
      unawaited(_audio.stop());
    } else {
      unawaited(_speakCurrent());
    }
  }

  void _onTimerStatusChanged(AnimationStatus status) {
    if (status == AnimationStatus.dismissed && !_answered && !_isDone) {
      _onTimeUp();
    }
  }

  bool _isListeningQuestion(QuizQuestion q) =>
      q.dialogueTurns != null && q.dialogueTurns!.isNotEmpty;

  /// Hạn thời gian của câu hiện tại. Hội thoại nghe hiểu dài hơn nhiều so với
  /// 15s của câu thường nên cộng thêm theo độ dài script (tối đa 3 phút) —
  /// nếu không thì hết giờ trước khi kịp nghe xong.
  int get _secondsForCurrent {
    if (!_hasQuestions || _isDone) return _secondsPerQuestion;
    final q = widget.questions[_index];
    if (!_isListeningQuestion(q)) return _secondsPerQuestion;
    final chars = q.dialogueTurns!.fold<int>(0, (n, t) => n + t.jp.length);
    return (20 + chars * 0.2).round().clamp(30, 180);
  }

  ListeningPhase get _listeningPhase {
    if (!_answered) return ListeningPhase.listening;
    if (_scriptOpen) return ListeningPhase.reviewing;
    return _timedOut ? ListeningPhase.timeout : ListeningPhase.answered;
  }

  /// Câu nghe (hội thoại, hoặc chế độ nghe) chỉ bắt đầu đếm giờ khi người học
  /// bấm Play lần đầu — không thì thời gian trôi trước khi họ kịp nghe.
  bool _timerWaitsForAudio(QuizQuestion q) =>
      widget.listeningMode || _isListeningQuestion(q);

  bool _timerStarted = false;

  void _runTimerIfWaitingForAudio() {
    if (_timerStarted || _answered || !_hasQuestions || _isDone) return;
    if (!_timerWaitsForAudio(widget.questions[_index])) return;
    _timerStarted = true;
    _timerController.reverse(from: 1.0);
  }

  void _onPlayerStateChanged() {
    if (_player.state.value != DialoguePlayState.idle) {
      _runTimerIfWaitingForAudio();
    }
  }

  void _startTimerForCurrentQuestion() {
    _timerController.duration = Duration(seconds: _secondsForCurrent);
    setState(() {
      _scriptOpen = false;
      _selectedOption = null;
      _answered = false;
      _timedOut = false;
      _isCorrect = false;
      _lastXpGained = null;
      _hiddenOptions.clear();
      _hintUsed = false;
    });
    _timerController.value = 1.0;
    _timerStarted = false;
    if (!_timerWaitsForAudio(widget.questions[_index])) {
      _timerStarted = true;
      _timerController.reverse(from: 1.0);
    }
  }

  void _onSelectOption(int optionIndex) {
    if (_answered) return;
    _timerController.stop();
    _stopAudio();
    final question = widget.questions[_index];
    _selectedOption = optionIndex;
    _recordAnswer(
      optionIndex == question.correctIndex,
      givenAnswerLabel: question.options[optionIndex],
    );
  }

  /// Chấm câu hỏi gõ đáp án (Typing/Translation) — song song với
  /// [_onSelectOption] nhưng so khớp bằng [isTypedAnswerCorrect] thay vì
  /// index, vì không có danh sách lựa chọn để chọn theo vị trí.
  void _onSubmitTyped(String rawText) {
    if (_answered) return;
    final question = widget.questions[_index];
    final mode = question.typedAnswerMode;
    if (mode == null) return;
    _timerController.stop();
    _stopAudio();
    _recordAnswer(
      isTypedAnswerCorrect(rawText, question.typedAcceptedAnswers, mode),
      givenAnswerLabel: rawText.trim(),
    );
  }

  /// Chấm câu hỏi Ghép câu (Sentence Ordering) — song song với
  /// [_onSelectOption]/[_onSubmitTyped] nhưng so bằng [isOrderCorrect] (so
  /// đúng thứ tự từng phần tử) thay vì index hay chuỗi gõ tay.
  void _onSubmitOrder(List<String> sequence) {
    if (_answered) return;
    final question = widget.questions[_index];
    if (question.orderTiles == null) return;
    _timerController.stop();
    _stopAudio();
    _recordAnswer(
      isOrderCorrect(sequence, question.orderCorrectSequence),
      givenAnswerLabel: sequence.join(''),
    );
  }

  /// Ghi nhận kết quả 1 câu — dùng chung cho cả 3 luồng chấm (chọn/gõ/ghép)
  /// ở trên, vì logic cập nhật điểm/tim/combo/XP giống hệt nhau, chỉ khác
  /// cách tính [isCorrect]. Gom về 1 chỗ để [QuizScreen.survivalMode] (dừng
  /// ngay khi sai) chỉ cần đọc đúng 1 field [_isCorrect] ở [_onContinue],
  /// không phải lặp lại điều kiện dừng ở cả 3 nơi. [givenAnswerLabel]: đáp
  /// án người dùng đã chọn/gõ/ghép — chỉ dùng khi sai, để hiện ở "Câu sai"
  /// trong `_SummaryPanel` (Task 9).
  void _recordAnswer(bool isCorrect, {String? givenAnswerLabel}) {
    setState(() {
      _answered = true;
      _timedOut = false;
      _isCorrect = isCorrect;
      if (isCorrect) {
        _correctCount++;
        _combo++;
        if (_combo > _bestCombo) _bestCombo = _combo;
        _lastXpGained = _xpPerCorrect;
      } else {
        _hearts = max(0, _hearts - 1);
        _combo = 0;
        _lastXpGained = null;
        _mistakes.add(_QuizMistake(
          question: widget.questions[_index],
          givenAnswerLabel: givenAnswerLabel ?? '(không trả lời)',
        ),);
      }
    });
    _revealCorrectOption();
    if (isCorrect) {
      unawaited(ref.read(quizXpControllerProvider)?.addXp(_xpPerCorrect));
    }
  }

  /// Sau khi khung phản hồi mở xong (đổi kích thước), cuộn tối thiểu để thẻ
  /// đáp án đúng nằm trong vùng nhìn. Chỉ cuộn khi cần; chỉ áp dụng cho thân
  /// câu hỏi thường (Nghe hiểu có `_listeningScroll` riêng).
  void _revealCorrectOption() {
    _revealTimer?.cancel();
    final index = _index;
    final wait = AppMotion.reduced(context)
        ? Duration.zero
        : AppMotion.standard + const Duration(milliseconds: 40);
    _revealTimer = Timer(wait, () {
      if (!mounted || !_answered || _index != index) return;
      final target = _correctOptionKey.currentContext;
      if (target == null) return;
      unawaited(Scrollable.ensureVisible(
        target,
        duration: AppMotion.resolve(context, AppMotion.standard),
        curve: AppMotion.curveSmooth,
        alignmentPolicy: ScrollPositionAlignmentPolicy.keepVisibleAtEnd,
      ),);
    });
  }

  /// Loại bỏ ngẫu nhiên 1 đáp án sai chưa bị ẩn — chỉ dùng được 1 lần/câu,
  /// không xoá khỏi list (chỉ disable) để không lệch index các đáp án còn lại.
  void _useHint() {
    if (_hintUsed || _answered) return;
    final question = widget.questions[_index];
    final wrongIndices = [
      for (var i = 0; i < question.options.length; i++)
        if (i != question.correctIndex && !_hiddenOptions.contains(i)) i,
    ];
    if (wrongIndices.isEmpty) return;
    wrongIndices.shuffle();
    setState(() {
      _hiddenOptions.add(wrongIndices.first);
      _hintUsed = true;
    });
  }

  void _onTimeUp() {
    if (_answered) return;
    setState(() {
      _answered = true;
      _timedOut = true;
      _selectedOption = null;
      _isCorrect = false;
      _hearts = max(0, _hearts - 1);
      _combo = 0;
      _lastXpGained = null;
      _mistakes.add(_QuizMistake(
        question: widget.questions[_index],
        givenAnswerLabel: 'Hết giờ',
      ),);
    });
    _revealCorrectOption();
    final question = widget.questions[_index];
    if (_isListeningQuestion(question)) {
      _stopAudio();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !_answered || !_timedOut) return;
        unawaited(showListeningTimeoutSheet(
          context,
          correctLetter: String.fromCharCode(65 + question.correctIndex),
          correctLabel: question.options[question.correctIndex],
          onShowScript: _openScript,
          onContinue: _onContinue,
        ),);
      });
    }
  }

  void _openScript() {
    setState(() => _scriptOpen = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_listeningScroll.hasClients) return;
      _listeningScroll.animateTo(
        _listeningScroll.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  void _onContinue() {
    // Chế độ sinh tồn: sai/hết giờ câu đầu tiên là dừng ngay, không đợi hết
    // tim hay hết câu — kiểm tra trước tiên vì nó có thể áp dụng bất kể còn
    // câu nào phía sau hay không.
    if (widget.survivalMode && !_isCorrect) {
      _finishQuiz();
      return;
    }
    if (_index + 1 < widget.questions.length) {
      setState(() => _index++);
      _startTimerForCurrentQuestion();
    } else {
      _finishQuiz();
    }
  }

  void _finishQuiz() {
    _timerController.stop();
    _wholeQuizTimer?.cancel();
    final attempted = _index + 1;
    final elapsed =
        _startedAt == null ? Duration.zero : DateTime.now().difference(_startedAt!);
    setState(() {
      _attemptedCount = attempted;
      _elapsed = elapsed;
      _index = widget.questions.length;
    });
    ref.invalidate(profileProvider);
    // Chờ ghi xong mốc hoàn thành rồi mới invalidate mission — invalidate
    // ngay (không chờ) sẽ đọc lại trước khi ghi xong, mission vẫn hiện chưa
    // xong dù vừa hoàn thành quiz.
    unawaited(
      ref.read(quizXpControllerProvider)?.markQuizCompletedToday().then((_) {
        if (mounted) ref.invalidate(dailyMissionStatusProvider);
      }),
    );
  }

  void _restart() {
    setState(() {
      _index = 0;
      _hearts = _heartsMax;
      _correctCount = 0;
      _attemptedCount = 0;
      _combo = 0;
      _bestCombo = 0;
      _mistakes.clear();
      _startedAt = DateTime.now();
      _elapsed = Duration.zero;
    });
    _startTimerForCurrentQuestion();
    if (widget.timedMode) _startWholeQuizTimer();
  }

  void _goHome() => context.go('/');

  /// Thoát khỏi màn quiz — quay lại đúng màn đã điều hướng tới đây (VD màn
  /// chọn loại quiz, hoặc chi tiết bài học) thay vì luôn nhảy thẳng về Home,
  /// vì mọi lối vào quiz đều dùng `push` (còn trong Navigator stack).
  void _exitQuiz() {
    if (context.canPop()) {
      context.pop();
    } else {
      _goHome();
    }
  }

  Future<void> _onBackPressed() async {
    final hasProgress = !_isDone && (_index > 0 || _answered);
    if (!hasProgress) {
      _exitQuiz();
      return;
    }
    final shouldExit = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Thoát bài kiểm tra?'),
        content: const Text('Tiến độ sẽ không được lưu.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Huỷ'),),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Thoát'),),
        ],
      ),
    );
    if (shouldExit == true) _exitQuiz();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope<void>(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _onBackPressed();
      },
      child: Scaffold(
        backgroundColor: AppColors.canvas,
        body: SafeArea(
          child: !_hasQuestions
              ? _EmptyPanel(onGoHome: _goHome)
              : _isDone
                  ? _SummaryPanel(
                      correctCount: _correctCount,
                      total: _attemptedCount,
                      heartsLeft: _hearts,
                      bestCombo: _bestCombo,
                      xpEarned: _correctCount * _xpPerCorrect,
                      elapsed: _elapsed,
                      mistakes: _mistakes,
                      onGoHome: _goHome,
                      onRestart: _restart,
                    )
                  : _buildQuizBody(context),
        ),
      ),
    );
  }

  /// Khung phản hồi hiện/ẩn có đổi kích thước mượt; tắt khi giảm chuyển động.
  Widget _withSizeTransition(BuildContext context, Widget child) {
    if (AppMotion.reduced(context)) return child;
    return AnimatedSize(
      duration: AppMotion.standard,
      curve: AppMotion.curveSmooth,
      alignment: Alignment.topCenter,
      child: child,
    );
  }

  Widget _buildListeningBody(QuizQuestion question) {
    return EnterTransition(
      key: ValueKey(_index),
      offset: Offset.zero,
      child: ListeningQuestionBody(
      title: widget.title,
      index: _index,
      total: widget.questions.length,
      hearts: _hearts,
      timerController: _timerController,
      timerSeconds: _secondsForCurrent,
      question: question,
      player: _player,
      phase: _listeningPhase,
      selectedOption: _selectedOption,
      hiddenOptions: _hiddenOptions,
      hintUsed: _hintUsed,
      isCorrect: !_timedOut && _isCorrect,
      timedOut: _timedOut,
      xpGained: _lastXpGained,
      combo: _combo,
      scrollController: _listeningScroll,
      onClose: _onBackPressed,
      onVoicePicker: _openVoicePicker,
      onSelect: _onSelectOption,
      onHint: _useHint,
      onShowScript: _openScript,
      onContinue: _onContinue,
    ),
    );
  }

  Widget _buildQuizBody(BuildContext context) {
    final question = widget.questions[_index];
    if (_isListeningQuestion(question)) return _buildListeningBody(question);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            widget.title,
            style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.inkSoft,),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              InkWell(
                borderRadius: BorderRadius.circular(100),
                onTap: _onBackPressed,
                child: const Padding(
                  padding: EdgeInsets.all(6),
                  child: Icon(Icons.close_rounded,
                      color: AppColors.inkFaint, size: 20,),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: AnimatedProgressBar(
                  value: _index / widget.questions.length,
                  minHeight: 9,
                  backgroundColor: AppColors.border,
                  color: AppColors.accent,
                ),
              ),
              const SizedBox(width: 10),
              if (widget.timedMode && _wholeQuizSecondsLeft != null) ...[
                _WholeQuizTimerChip(secondsLeft: _wholeQuizSecondsLeft!),
                const SizedBox(width: 8),
              ],
              _HeartsRow(hearts: _hearts, max: _heartsMax),
              InkWell(
                borderRadius: BorderRadius.circular(100),
                onTap: _openVoicePicker,
                child: const Padding(
                  padding: EdgeInsets.only(left: 6),
                  child: Icon(Icons.record_voice_over_outlined,
                      color: AppColors.inkFaint, size: 20,),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Expanded(
            child: EnterTransition(
              key: ValueKey(_index),
              child: Center(
                child: SingleChildScrollView(
                  controller: _bodyScroll,
                  child: Column(
                    children: [
                      Text(
                        'CÂU ${_index + 1}/${widget.questions.length} · ${question.promptVi}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                          color: AppColors.inkFaint,
                          letterSpacing: 0.6,
                        ),
                      ),
                      const SizedBox(height: 16),
                      CountdownRing(
                          controller: _timerController,
                          totalSeconds: _secondsForCurrent,),
                      const SizedBox(height: 14),
                      if (widget.listeningMode && !_answered)
                        _ListenButton(
                          onTap: _toggleSingleAudio,
                          playing: _speakingSingle,
                        )
                      else ...[
                        if (question.displayIsJapanese &&
                            (!question.hasBlank || _answered)) ...[
                          _AudioPlayButton(
                              onTap: () => unawaited(_speakCurrent()),),
                          const SizedBox(height: 14),
                        ],
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: AppColors.card,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Text(question.displayJp,
                              textAlign: TextAlign.center,
                              style: question.displayIsJapanese
                                  ? AppFonts.zenMaruGothic(
                                      fontSize: widget.listeningMode ? 20 : 26,
                                      color: AppColors.ink,)
                                  : const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.ink,),),
                        ),
                        if (question.displayIsJapanese &&
                            question.readingFurigana != null) ...[
                          const SizedBox(height: 6),
                          Text(
                            question.readingFurigana!,
                            style: AppFonts.zenMaruGothic(
                                fontSize: 13,
                                color: AppColors.inkSoft,
                                fontWeight: FontWeight.w500,),
                          ),
                        ],
                      ],
                      const SizedBox(height: 26),
                      if (question.typedAnswerMode != null)
                        _TypedAnswerField(
                          key: ValueKey(_index),
                          answered: _answered,
                          isCorrect: _isCorrect,
                          onSubmit: _onSubmitTyped,
                        )
                      else if (question.orderTiles != null)
                        _TileOrderField(
                          key: ValueKey(_index),
                          tiles: question.orderTiles!,
                          answered: _answered,
                          isCorrect: _isCorrect,
                          onSubmit: _onSubmitOrder,
                        )
                      else ...[
                        _OptionsList(
                          question: question,
                          selectedOption: _selectedOption,
                          answered: _answered,
                          hiddenOptions: _hiddenOptions,
                          correctKey: _correctOptionKey,
                          onSelect: _onSelectOption,
                        ),
                        if (!_answered) ...[
                          const SizedBox(height: 12),
                          _HintButton(
                            used: _hintUsed,
                            onTap: _hintUsed ? null : _useHint,
                          ),
                        ],
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
          _withSizeTransition(
            context,
            _answered
                ? Padding(
                    padding: const EdgeInsets.only(top: 14),
                    child: EnterTransition(
                      key: ValueKey('feedback-$_index'),
                      offset: const Offset(0, 0.08),
                      child: _FeedbackPanel(
              isCorrect: !_timedOut && _isCorrect,
              timedOut: _timedOut,
              xpGained: _lastXpGained,
              combo: _combo,
              correctAnswerLabel: question.options[question.correctIndex],
              onContinue: _onContinue,
              explanation: question.explanationVi,
              sourceNote: question.sourceNote,
            ),
                    ),
                  )
                : const SizedBox(width: double.infinity),
          ),
        ],
      ),
    );
  }
}

/// 1 câu trả lời sai/hết giờ thật trong phiên — dữ liệu cho phần "Câu
/// sai"/"Điểm yếu theo nhóm" ở `_SummaryPanel` (Task 9).
class _QuizMistake {
  const _QuizMistake({required this.question, required this.givenAnswerLabel});

  final QuizQuestion question;
  final String givenAnswerLabel;
}

/// Đồng hồ đếm ngược TOÀN BÀI ([QuizScreen.timedMode]) — hiện mm:ss, đổi màu
/// cảnh báo khi còn dưới 30s để người dùng biết sắp hết giờ cả bài (khác
/// [CountdownRing] vốn chỉ đếm 1 câu).
class _WholeQuizTimerChip extends StatelessWidget {
  const _WholeQuizTimerChip({required this.secondsLeft});

  final int secondsLeft;

  @override
  Widget build(BuildContext context) {
    final minutes = secondsLeft ~/ 60;
    final seconds = secondsLeft % 60;
    final label = '$minutes:${seconds.toString().padLeft(2, '0')}';
    final urgent = secondsLeft <= 30;
    final color = urgent ? AppColors.danger : AppColors.inkSoft;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: urgent ? AppColors.dangerSoft : AppColors.chip,
        borderRadius: BorderRadius.circular(100),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.timer_outlined, size: 13, color: color),
          const SizedBox(width: 3),
          Text(label,
              style: TextStyle(
                  fontSize: 11.5, fontWeight: FontWeight.w800, color: color,),),
        ],
      ),
    );
  }
}

class _HeartsRow extends StatelessWidget {
  const _HeartsRow({required this.hearts, required this.max});

  final int hearts;
  final int max;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < max; i++)
          Padding(
            padding: const EdgeInsets.only(left: 2),
            child: Icon(
              i < hearts
                  ? Icons.favorite_rounded
                  : Icons.favorite_border_rounded,
              size: 16,
              color: i < hearts ? AppColors.danger : AppColors.border,
            ),
          ),
      ],
    );
  }
}

/// Nút tròn phát âm chính của mỗi câu (không phải chế độ nghe hiểu) — đặt
/// nổi bật phía trên câu hỏi thay vì icon nhỏ nằm cạnh chữ, giống mockup.
class _AudioPlayButton extends StatelessWidget {
  const _AudioPlayButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: PressScale(
        child: InkWell(
        borderRadius: BorderRadius.circular(100),
        onTap: onTap,
        child: Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.accent, Color(0xFFFFB020)],
            ),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppColors.accent.withValues(alpha: 0.35),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: const Icon(Icons.volume_up_rounded,
              size: 24, color: Colors.white,),
        ),
      ),
      ),
    );
  }
}

/// Nút phát/nghe lại âm thanh trong [QuizScreen.listeningMode] — thay cho
/// hiển thị chữ Nhật, buộc người học phải nghe thay vì đọc.
class _ListenButton extends StatelessWidget {
  const _ListenButton({required this.onTap, required this.playing});

  final VoidCallback onTap;
  final bool playing;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        PlayingRing(
          active: playing,
          color: AppColors.accent,
          child: PressScale(
            child: InkWell(
              borderRadius: BorderRadius.circular(100),
              onTap: onTap,
              child: Container(
                width: 68,
                height: 68,
                decoration: const BoxDecoration(
                    color: AppColors.accentSoft, shape: BoxShape.circle,),
                alignment: Alignment.center,
                child: SwapIcon(
                  icon: playing ? Icons.pause_rounded : Icons.volume_up_rounded,
                  size: 32,
                  color: AppColors.accentStrong,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(playing ? 'Chạm để tạm dừng' : 'Chạm để nghe lại',
            textAlign: TextAlign.center,
            style: const TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: AppColors.inkSoft,),),
      ],
    );
  }
}

enum _OptionState { idle, correct, wrong, disabled, hidden }

class _OptionsList extends StatelessWidget {
  const _OptionsList({
    required this.question,
    required this.selectedOption,
    required this.answered,
    required this.hiddenOptions,
    required this.onSelect,
    this.correctKey,
  });

  final QuizQuestion question;
  final int? selectedOption;
  final bool answered;
  final Set<int> hiddenOptions;
  final ValueChanged<int> onSelect;
  final GlobalKey? correctKey;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < question.options.length; i++) ...[
          if (i > 0) const SizedBox(height: 10),
          KeyedSubtree(
            key: i == question.correctIndex ? correctKey : null,
            child: _OptionCard(
              index: i,
              label: question.options[i],
              state: _stateFor(i),
              onTap: (answered || hiddenOptions.contains(i))
                  ? null
                  : () => onSelect(i),
            ),
          ),
        ],
      ],
    );
  }

  _OptionState _stateFor(int i) {
    if (!answered) {
      return hiddenOptions.contains(i) ? _OptionState.hidden : _OptionState.idle;
    }
    if (i == question.correctIndex) return _OptionState.correct;
    if (i == selectedOption) return _OptionState.wrong;
    return _OptionState.disabled;
  }
}

class _OptionCard extends StatelessWidget {
  const _OptionCard({
    required this.index,
    required this.label,
    required this.state,
    required this.onTap,
  });

  final int index;
  final String label;
  final _OptionState state;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final (Color bg, Color border, Color fg, Color numBg) = switch (state) {
      _OptionState.idle => (
          AppColors.card,
          AppColors.border,
          AppColors.ink,
          AppColors.chip
        ),
      _OptionState.correct => (
          AppColors.mossSoft,
          AppColors.moss,
          AppColors.moss,
          AppColors.moss
        ),
      _OptionState.wrong => (
          AppColors.dangerSoft,
          AppColors.danger,
          AppColors.danger,
          AppColors.danger
        ),
      _OptionState.disabled => (
          AppColors.card,
          AppColors.border,
          AppColors.inkFaint,
          AppColors.chip
        ),
      _OptionState.hidden => (
          AppColors.card,
          AppColors.border,
          AppColors.inkFaint,
          AppColors.chip
        ),
    };
    final numFg = switch (state) {
      _OptionState.correct || _OptionState.wrong => Colors.white,
      _ => AppColors.inkSoft,
    };
    final opacity = switch (state) {
      _OptionState.disabled => 0.55,
      _OptionState.hidden => 0.32,
      _ => 1.0,
    };
    final fast = AppMotion.resolve(context, AppMotion.fast);
    return AnswerOptionFrame(
      opacity: opacity,
      wrong: state == _OptionState.wrong,
      pressable: onTap != null,
      child: InkWell(
        borderRadius: BorderRadius.circular(15),
        onTap: onTap,
        child: AnimatedContainer(
          duration: fast,
          curve: AppMotion.curveChange,
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: border, width: 2),
          ),
          child: Row(
            children: [
              AnimatedContainer(
                duration: fast,
                curve: AppMotion.curveChange,
                width: 26,
                height: 26,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: numBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${index + 1}',
                  style: TextStyle(
                      fontWeight: FontWeight.w800, fontSize: 12, color: numFg,),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(label,
                    style: TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 14, color: fg,),),
              ),
              if (state == _OptionState.correct ||
                  state == _OptionState.wrong) ...[
                const SizedBox(width: 8),
                AnswerResultIcon(correct: state == _OptionState.correct),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Ô nhập chữ cho câu hỏi Typing/Translation (`typedAnswerMode != null`) —
/// thay cho [_OptionsList] vì không có sẵn danh sách lựa chọn. `key` phía
/// gọi luôn là `ValueKey(index câu hỏi)` để widget bị tạo lại hoàn toàn khi
/// sang câu mới, tự xoá trắng ô nhập thay vì phải tự đồng bộ qua
/// `didUpdateWidget`.
class _TypedAnswerField extends StatefulWidget {
  const _TypedAnswerField({
    super.key,
    required this.answered,
    required this.isCorrect,
    required this.onSubmit,
  });

  final bool answered;
  final bool isCorrect;
  final ValueChanged<String> onSubmit;

  @override
  State<_TypedAnswerField> createState() => _TypedAnswerFieldState();
}

class _TypedAnswerFieldState extends State<_TypedAnswerField> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    if (widget.answered || _controller.text.trim().isEmpty) return;
    widget.onSubmit(_controller.text);
  }

  @override
  Widget build(BuildContext context) {
    final borderColor = !widget.answered
        ? AppColors.border
        : (widget.isCorrect ? AppColors.moss : AppColors.danger);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _controller,
          enabled: !widget.answered,
          autofocus: true,
          textAlign: TextAlign.center,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _submit(),
          style: const TextStyle(
              fontWeight: FontWeight.w700, fontSize: 16, color: AppColors.ink,),
          decoration: InputDecoration(
            hintText: 'Gõ đáp án...',
            filled: true,
            fillColor: AppColors.card,
            contentPadding:
                const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: BorderSide(color: borderColor, width: 2),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: BorderSide(color: borderColor, width: 2),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: BorderSide(color: borderColor, width: 2),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: BorderSide(color: borderColor, width: 2),
            ),
          ),
        ),
        if (!widget.answered) ...[
          const SizedBox(height: 12),
          FilledButton(
            onPressed: _submit,
            child: const Text('Kiểm tra'),
          ),
        ],
      ],
    );
  }
}

/// Ô ghép câu (tap-to-order) cho câu hỏi Sentence Ordering
/// (`orderTiles != null`) — chạm từ ở khu "Từ có sẵn" để thêm vào "Câu trả
/// lời", chạm lại trong "Câu trả lời" để rút ra. Theo dõi bằng index vào
/// [tiles] (không phải giá trị chuỗi) để không nhầm khi có 2 tile trùng chữ
/// (VD trợ từ lặp lại trong 1 câu). `key` phía gọi luôn là
/// `ValueKey(index câu hỏi)` giống [_TypedAnswerField] để tự tạo lại khi
/// sang câu mới.
class _TileOrderField extends StatefulWidget {
  const _TileOrderField({
    super.key,
    required this.tiles,
    required this.answered,
    required this.isCorrect,
    required this.onSubmit,
  });

  final List<String> tiles;
  final bool answered;
  final bool isCorrect;
  final ValueChanged<List<String>> onSubmit;

  @override
  State<_TileOrderField> createState() => _TileOrderFieldState();
}

class _TileOrderFieldState extends State<_TileOrderField> {
  final List<int> _selected = [];

  void _pick(int tileIndex) {
    if (widget.answered) return;
    setState(() => _selected.add(tileIndex));
  }

  void _unpick(int position) {
    if (widget.answered) return;
    setState(() => _selected.removeAt(position));
  }

  void _submit() {
    if (widget.answered || _selected.length != widget.tiles.length) return;
    widget.onSubmit([for (final i in _selected) widget.tiles[i]]);
  }

  @override
  Widget build(BuildContext context) {
    final answerBorderColor = !widget.answered
        ? AppColors.border
        : (widget.isCorrect ? AppColors.moss : AppColors.danger);
    final availableIndices = [
      for (var i = 0; i < widget.tiles.length; i++)
        if (!_selected.contains(i)) i,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          width: double.infinity,
          constraints: const BoxConstraints(minHeight: 56),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: answerBorderColor, width: 2),
          ),
          child: _selected.isEmpty
              ? const Text(
                  'Chạm từ bên dưới để ghép câu...',
                  style: TextStyle(fontSize: 13, color: AppColors.inkFaint),
                )
              : Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (var i = 0; i < _selected.length; i++)
                      _Tile(
                        label: widget.tiles[_selected[i]],
                        onTap: widget.answered ? null : () => _unpick(i),
                      ),
                  ],
                ),
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final i in availableIndices)
              _Tile(
                label: widget.tiles[i],
                onTap: widget.answered ? null : () => _pick(i),
                filled: false,
              ),
          ],
        ),
        if (!widget.answered) ...[
          const SizedBox(height: 12),
          FilledButton(
            onPressed:
                _selected.length == widget.tiles.length ? _submit : null,
            child: const Text('Kiểm tra'),
          ),
        ],
      ],
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({required this.label, required this.onTap, this.filled = true});

  final String label;
  final VoidCallback? onTap;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: filled ? AppColors.chip : AppColors.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border, width: 1.4),
        ),
        child: Text(
          label,
          style: AppFonts.zenMaruGothic(
              fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.ink,),
        ),
      ),
    );
  }
}

/// Loại 1 đáp án sai — cơ chế hint thật (không có nội dung gợi ý nào trong
/// [QuizQuestion] để hiện, nên dùng loại-trừ thay vì bịa ra 1 câu gợi ý giả).
class _HintButton extends StatelessWidget {
  const _HintButton({required this.used, required this.onTap});

  final bool used;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final color = used ? AppColors.inkFaint : AppColors.accentStrong;
    return TextButton.icon(
      onPressed: onTap,
      icon: Icon(Icons.lightbulb_outline_rounded, size: 16, color: color),
      label: Text(
        used ? 'Đã dùng gợi ý' : 'Gợi ý: loại 1 đáp án sai',
        style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: color),
      ),
    );
  }
}

/// Bảng phản hồi sau khi trả lời — 1 khối màu trọn vẹn (icon tròn + tiêu đề +
/// phụ đề + chip thưởng/đáp án đúng + nút tiếp tục cùng tông màu), thay cho
/// dòng chữ phẳng + nút cam rời trước đây, theo đúng bố cục mockup.
class _FeedbackPanel extends StatelessWidget {
  const _FeedbackPanel({
    required this.isCorrect,
    required this.timedOut,
    required this.xpGained,
    required this.combo,
    required this.correctAnswerLabel,
    required this.onContinue,
    this.explanation,
    this.sourceNote,
  });

  final bool isCorrect;
  final bool timedOut;
  final int? xpGained;
  final int combo;
  final String correctAnswerLabel;
  final VoidCallback onContinue;

  /// Lời giải + nguồn câu hỏi (nếu dữ liệu có) — chỉ hiện sau khi đã trả lời.
  final String? explanation;
  final String? sourceNote;

  @override
  Widget build(BuildContext context) {
    final color = isCorrect ? AppColors.moss : AppColors.danger;
    final bg = isCorrect ? AppColors.mossSoft : AppColors.dangerSoft;
    final title = timedOut
        ? 'Hết giờ!'
        : (isCorrect ? 'Chính xác!' : 'Chưa đúng rồi!');
    final subtitle = timedOut
        ? 'Nhanh tay hơn ở câu tiếp theo nhé'
        : (isCorrect ? 'Làm tốt lắm!' : 'Xem đáp án đúng bên dưới nhé');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                alignment: Alignment.center,
                child: Icon(
                  isCorrect ? Icons.check_rounded : Icons.close_rounded,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                            color: color,),),
                    const SizedBox(height: 2),
                    Text(subtitle,
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.inkSoft,),),
                  ],
                ),
              ),
            ],
          ),
          if (isCorrect && (xpGained != null || combo >= 2)) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                if (xpGained != null)
                  _Badge(
                    text: '+$xpGained XP',
                    bg: const Color(0xFFFFF3C4),
                    fg: const Color(0xFFB8860B),
                  ),
                if (xpGained != null && combo >= 2) const SizedBox(width: 8),
                if (combo >= 2)
                  _Badge(
                    text: 'Combo x$combo',
                    bg: AppColors.indigoSoft,
                    fg: AppColors.indigo,
                  ),
              ],
            ),
          ],
          if (!isCorrect) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.card.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Đáp án đúng:',
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.inkSoft,),),
                  const SizedBox(height: 2),
                  Text(correctAnswerLabel,
                      style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: AppColors.ink,),),
                ],
              ),
            ),
          ],
          if ((explanation ?? '').trim().isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              key: const ValueKey('quiz-explanation'),
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.card.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Giải thích:',
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.inkSoft,),),
                  const SizedBox(height: 2),
                  Text(explanation!.trim(),
                      style: const TextStyle(
                          fontSize: 13,
                          height: 1.4,
                          color: AppColors.ink,),),
                  if ((sourceNote ?? '').isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(sourceNote!,
                        style: const TextStyle(
                            fontSize: 11, color: AppColors.inkSoft,),),
                  ],
                ],
              ),
            ),
          ],
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: onContinue,
              style: FilledButton.styleFrom(backgroundColor: color),
              child: const Text('Tiếp tục'),
            ),
          ),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.text, required this.bg, required this.fg});

  final String text;
  final Color bg;
  final Color fg;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(100)),
      child: Text(text,
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: fg),),
    );
  }
}

class _EmptyPanel extends StatelessWidget {
  const _EmptyPanel({required this.onGoHome});

  final VoidCallback onGoHome;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.quiz_outlined,
                size: 40, color: AppColors.inkFaint,),
            const SizedBox(height: 14),
            const Text(
              'Chưa đủ nội dung để tạo câu hỏi cho phần này.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.inkSoft, fontSize: 14),
            ),
            const SizedBox(height: 20),
            FilledButton(
                onPressed: onGoHome, child: const Text('Về trang chủ'),),
          ],
        ),
      ),
    );
  }
}

class _SummaryPanel extends StatefulWidget {
  const _SummaryPanel({
    required this.correctCount,
    required this.total,
    required this.heartsLeft,
    required this.bestCombo,
    required this.xpEarned,
    required this.elapsed,
    required this.mistakes,
    required this.onGoHome,
    required this.onRestart,
  });

  final int correctCount;
  final int total;
  final int heartsLeft;
  final int bestCombo;
  final int xpEarned;
  final Duration elapsed;

  /// Task 9 (`docs/MIXED_QUIZ_DESIGN.md` §5) — Score/Accuracy/Time đã có sẵn
  /// từ các field trên; [mistakes] là dữ liệu thêm cho phần "Câu sai"/"Điểm
  /// yếu theo nhóm" + gợi ý rule-based (không AI). Rỗng thì ẩn hẳn 2 phần đó
  /// (honest-empty, không hiện khối rỗng vô nghĩa khi làm đúng hết).
  final List<_QuizMistake> mistakes;

  final VoidCallback onGoHome;
  final VoidCallback onRestart;

  @override
  State<_SummaryPanel> createState() => _SummaryPanelState();
}

class _SummaryPanelState extends State<_SummaryPanel> {
  @override
  Widget build(BuildContext context) {
    final accuracy =
        widget.total == 0 ? 0.0 : widget.correctCount / widget.total * 100;
    final minutes = widget.elapsed.inSeconds ~/ 60;
    final seconds = widget.elapsed.inSeconds % 60;
    final timeLabel = '$minutes:${seconds.toString().padLeft(2, '0')}';

    return Stack(
      alignment: Alignment.center,
      children: [
        const Positioned.fill(child: ConfettiBurst()),
        SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.emoji_events_rounded,
                    size: 56, color: AppColors.accent,),
                const SizedBox(height: 16),
                const Text(
                  'Hoàn thành bài kiểm tra!',
                  style: TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                      color: AppColors.ink,),
                ),
                const SizedBox(height: 20),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _StatChip(
                        value: '${widget.correctCount}/${widget.total}',
                        label: 'Câu đúng',
                        bg: AppColors.mossSoft,
                        fg: AppColors.moss,),
                    _StatChip(
                        value: '${accuracy.round()}%',
                        label: 'Độ chính xác',
                        bg: AppColors.indigoSoft,
                        fg: AppColors.indigo,),
                    _StatChip(
                        value: timeLabel,
                        label: 'Thời gian',
                        bg: AppColors.chip,
                        fg: AppColors.inkSoft,),
                    _StatChip(
                        value: '${widget.xpEarned}',
                        // XP của phiên này đếm từ 0 → số đã nhận (chỉ hiển
                        // thị; việc cộng XP đã xảy ra từng câu ở _recordAnswer).
                        countTo: widget.xpEarned,
                        label: 'XP',
                        bg: const Color(0xFFFFF1CE),
                        fg: const Color(0xFFB4790A),),
                    if (widget.bestCombo >= 2)
                      _StatChip(
                          value: 'x${widget.bestCombo}',
                          label: 'Best Combo',
                          bg: AppColors.indigoSoft,
                          fg: AppColors.indigo,),
                    _StatChip(
                        value: '${widget.heartsLeft}',
                        label: 'Tim còn lại',
                        bg: AppColors.dangerSoft,
                        fg: AppColors.danger,),
                  ],
                ),
                if (widget.mistakes.isNotEmpty) ...[
                  const SizedBox(height: 22),
                  _WeakAreasSection(mistakes: widget.mistakes),
                  const SizedBox(height: 14),
                  _MistakesSection(mistakes: widget.mistakes),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => context.push('/review/mistakes'),
                          child: const Text('Sổ tay lỗi'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => context.push('/review/smart'),
                          child: const Text('Ôn thông minh'),
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 22),
                FilledButton(
                    onPressed: widget.onGoHome,
                    child: const Text('Về trang chủ'),),
                const SizedBox(height: 10),
                TextButton(
                    onPressed: widget.onRestart,
                    child: const Text('Làm lại',
                        style: TextStyle(color: AppColors.inkSoft),),),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

String _sourceGroupLabel(LessonItemType? type) => switch (type) {
      LessonItemType.vocabulary => 'Từ vựng',
      LessonItemType.kanji => 'Kanji',
      LessonItemType.grammar => 'Ngữ pháp',
      null => 'Khác (nghe/hội thoại)',
    };

/// "Điểm yếu theo nhóm" — gộp [mistakes] theo `sourceType`, kèm 1 câu nhận
/// xét rule-based từ chính số liệu này (VD "sai nhiều nhất ở Ngữ pháp —
/// 4/6 câu") thay cho văn bản AI sinh, đúng quyết định thiết kế
/// `docs/MIXED_QUIZ_DESIGN.md` §5.
class _WeakAreasSection extends StatelessWidget {
  const _WeakAreasSection({required this.mistakes});

  final List<_QuizMistake> mistakes;

  @override
  Widget build(BuildContext context) {
    final counts = <LessonItemType?, int>{};
    for (final m in mistakes) {
      counts[m.question.sourceType] = (counts[m.question.sourceType] ?? 0) + 1;
    }
    final entries = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final worst = entries.first;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('ĐIỂM YẾU THEO NHÓM',
              style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w800,
                  color: AppColors.inkFaint,
                  letterSpacing: 0.6,),),
          const SizedBox(height: 8),
          Text(
            'Bạn sai nhiều nhất ở ${_sourceGroupLabel(worst.key)} — ${worst.value}/${mistakes.length} câu.',
            style: const TextStyle(
                fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.ink,),
          ),
          const SizedBox(height: 10),
          for (final e in entries)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  Expanded(
                    child: Text(_sourceGroupLabel(e.key),
                        style: const TextStyle(
                            fontSize: 12.5, color: AppColors.inkSoft,),),
                  ),
                  Text('${e.value}',
                      style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w800,
                          color: AppColors.ink,),),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// Danh sách "câu sai + đáp án đúng" thật (Task 9 §5) — không giới hạn số
/// lượng hiện (trang đã cuộn được), không tóm tắt/diễn giải lại bằng AI.
class _MistakesSection extends StatelessWidget {
  const _MistakesSection({required this.mistakes});

  final List<_QuizMistake> mistakes;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('CÂU SAI (${mistakes.length})',
              style: const TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w800,
                  color: AppColors.inkFaint,
                  letterSpacing: 0.6,),),
          const SizedBox(height: 10),
          for (var i = 0; i < mistakes.length; i++) ...[
            if (i > 0) const Divider(height: 18, color: AppColors.border),
            _MistakeRow(mistake: mistakes[i]),
          ],
        ],
      ),
    );
  }
}

class _MistakeRow extends StatelessWidget {
  const _MistakeRow({required this.mistake});

  final _QuizMistake mistake;

  @override
  Widget build(BuildContext context) {
    final q = mistake.question;
    final correctLabel = q.options.isNotEmpty ? q.options[q.correctIndex] : '';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(q.displayJp,
            textAlign: TextAlign.left,
            style: const TextStyle(
                fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.ink,),),
        const SizedBox(height: 4),
        Text('Bạn: ${mistake.givenAnswerLabel}',
            style: const TextStyle(fontSize: 12, color: AppColors.danger),),
        Text('Đúng: $correctLabel',
            style: const TextStyle(fontSize: 12, color: AppColors.moss),),
      ],
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip(
      {required this.value,
      required this.label,
      required this.bg,
      required this.fg,
      this.countTo,});

  final String value;
  final int? countTo;
  final String label;
  final Color bg;
  final Color fg;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(14)),
      child: Column(
        children: [
          if (countTo != null)
            AnimatedCount(
              value: countTo,
              from: 0,
              popOnIncrease: false,
              style: TextStyle(
                  fontWeight: FontWeight.w800, fontSize: 16, color: fg,),
            )
          else
            Text(value,
                style: TextStyle(
                    fontWeight: FontWeight.w800, fontSize: 16, color: fg,),),
          Text(label,
              style: TextStyle(
                  fontWeight: FontWeight.w700, fontSize: 9.5, color: fg,),),
        ],
      ),
    );
  }
}
