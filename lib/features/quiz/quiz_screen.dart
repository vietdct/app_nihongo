import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:go_router/go_router.dart';

import '../../core/services/jp_voice_prefs.dart';
import '../../core/theme/app_theme.dart';
import '../../domain/entities/listening_dialogue.dart';
import '../../domain/services/quiz_generator.dart';
import '../home/providers/mission_providers.dart';
import '../home/providers/profile_providers.dart';
import 'providers/quiz_providers.dart';
import 'widgets/countdown_ring.dart';

/// Màn quiz trắc nghiệm dùng chung cho cả 3 lối vào (theo bài học / theo
/// trình độ / nghe hiểu) — chỉ nhận [questions] đã resolve sẵn, không tự
/// watch provider bên trong để tách biệt UI/state khỏi nguồn dữ liệu.
///
/// Mọi câu hỏi đều được đọc bằng `flutter_tts` (đã dùng ở AI Kaiwa) khi vào
/// câu — giúp học phát âm ngay cả ở quiz chữ bình thường, không cần thêm dữ
/// liệu audio thật.
///
/// [listeningMode]: ẩn chữ Nhật cho tới khi trả lời — biến đúng bộ câu hỏi đó
/// thành bài luyện nghe thay vì luyện đọc.
class QuizScreen extends ConsumerStatefulWidget {
  const QuizScreen({
    super.key,
    required this.questions,
    required this.title,
    this.listeningMode = false,
  });

  final List<QuizQuestion> questions;
  final String title;
  final bool listeningMode;

  @override
  ConsumerState<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends ConsumerState<QuizScreen>
    with SingleTickerProviderStateMixin {
  static const _heartsMax = 5;
  static const _secondsPerQuestion = 15;
  static const _xpPerCorrect = 10;

  late final AnimationController _timerController;
  late final FlutterTts _tts;

  int _index = 0;
  int _hearts = _heartsMax;
  int _correctCount = 0;
  int? _selectedOption;
  bool _answered = false;
  bool _timedOut = false;
  int _combo = 0;
  int _bestCombo = 0;
  int? _lastXpGained;
  final Set<int> _hiddenOptions = {};
  bool _hintUsed = false;

  // Giọng đọc tiếng Nhật — dùng chung khoá lưu với AI Kaiwa (xem
  // jp_voice_prefs.dart), chọn giọng ở màn nào cũng áp dụng cho màn kia.
  List<Map<String, String>> _japaneseVoices = [];
  Map<String, String>? _selectedVoice;

  bool get _hasQuestions => widget.questions.isNotEmpty;
  bool get _isDone => _index >= widget.questions.length;

  @override
  void initState() {
    super.initState();
    _timerController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: _secondsPerQuestion),
    )..addStatusListener(_onTimerStatusChanged);
    _tts = FlutterTts()
      ..setLanguage('ja-JP')
      ..setVolume(1.0)
      ..setSpeechRate(0.45)
      ..awaitSpeakCompletion(true);
    unawaited(_loadVoices());
    if (_hasQuestions) _startTimerForCurrentQuestion();
  }

  Future<void> _loadVoices() async {
    final voices = await loadJapaneseVoices(_tts);
    final saved = await loadSavedJpVoice(voices);
    if (saved != null) await _tts.setVoice(saved);
    if (!mounted) return;
    setState(() {
      _japaneseVoices = voices;
      _selectedVoice = saved;
    });
  }

  Future<void> _selectVoice(Map<String, String> voice) async {
    await _tts.setVoice(voice);
    await saveJpVoice(voice);
    if (!mounted) return;
    setState(() => _selectedVoice = voice);
    unawaited(_speakCurrent());
  }

  void _openVoicePicker() {
    showJpVoicePicker(
      context: context,
      voices: _japaneseVoices,
      selected: _selectedVoice,
      onSelected: _selectVoice,
    );
  }

  @override
  void dispose() {
    _timerController.dispose();
    unawaited(_tts.stop());
    super.dispose();
  }

  /// Câu thường: đọc nguyên [QuizQuestion.displayJp] 1 lần. Hội thoại nghe
  /// hiểu (`dialogueTurns` khác null): đọc lần lượt từng lượt thoại, đổi cao
  /// độ giọng theo speaker để nghe như 2 người khác nhau — không có audio
  /// thu sẵn nên TTS là cách duy nhất tạo hiệu ứng "2 giọng".
  Future<void> _speakCurrent() async {
    if (!_hasQuestions || _isDone) return;
    final question = widget.questions[_index];
    final turns = question.dialogueTurns;
    // Câu đảo chiều (displayIsJapanese == false) hiện nghĩa tiếng Việt to
    // giữa màn — không đọc bằng giọng tiếng Nhật vì sẽ phát âm sai hoàn
    // toàn, không phải im lặng do lỗi.
    if (turns == null && !question.displayIsJapanese) return;
    await applyIosTtsPlaybackCategory(_tts);
    await _tts.stop();
    if (turns == null || turns.isEmpty) {
      await _tts.speak(question.displayJp);
      return;
    }
    for (final turn in turns) {
      if (!mounted || _index >= widget.questions.length) return;
      await _tts.setPitch(turn.speaker == 'A' ? 1.15 : 0.8);
      await _tts.speak(turn.jp);
    }
  }

  void _onTimerStatusChanged(AnimationStatus status) {
    if (status == AnimationStatus.dismissed && !_answered && !_isDone) {
      _onTimeUp();
    }
  }

  void _startTimerForCurrentQuestion() {
    setState(() {
      _selectedOption = null;
      _answered = false;
      _timedOut = false;
      _lastXpGained = null;
      _hiddenOptions.clear();
      _hintUsed = false;
    });
    _timerController.value = 1.0;
    _timerController.reverse(from: 1.0);
    unawaited(_speakCurrent());
  }

  void _onSelectOption(int optionIndex) {
    if (_answered) return;
    _timerController.stop();
    unawaited(_tts.stop());
    final question = widget.questions[_index];
    final isCorrect = optionIndex == question.correctIndex;
    setState(() {
      _selectedOption = optionIndex;
      _answered = true;
      _timedOut = false;
      if (isCorrect) {
        _correctCount++;
        _combo++;
        if (_combo > _bestCombo) _bestCombo = _combo;
        _lastXpGained = _xpPerCorrect;
      } else {
        _hearts = max(0, _hearts - 1);
        _combo = 0;
        _lastXpGained = null;
      }
    });
    if (isCorrect) {
      unawaited(ref.read(quizXpControllerProvider)?.addXp(_xpPerCorrect));
    }
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
      _hearts = max(0, _hearts - 1);
      _combo = 0;
      _lastXpGained = null;
    });
  }

  void _onContinue() {
    if (_index + 1 < widget.questions.length) {
      setState(() => _index++);
      _startTimerForCurrentQuestion();
    } else {
      _timerController.stop();
      setState(() => _index = widget.questions.length);
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
  }

  void _restart() {
    setState(() {
      _index = 0;
      _hearts = _heartsMax;
      _correctCount = 0;
      _combo = 0;
      _bestCombo = 0;
    });
    _startTimerForCurrentQuestion();
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
                      total: widget.questions.length,
                      heartsLeft: _hearts,
                      bestCombo: _bestCombo,
                      xpEarned: _correctCount * _xpPerCorrect,
                      onGoHome: _goHome,
                      onRestart: _restart,
                    )
                  : _buildQuizBody(context),
        ),
      ),
    );
  }

  Widget _buildQuizBody(BuildContext context) {
    final question = widget.questions[_index];
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
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(100),
                  child: LinearProgressIndicator(
                    value: _index / widget.questions.length,
                    minHeight: 9,
                    backgroundColor: AppColors.border,
                    valueColor: const AlwaysStoppedAnimation(AppColors.accent),
                  ),
                ),
              ),
              const SizedBox(width: 10),
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
            child: Center(
              child: SingleChildScrollView(
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
                        totalSeconds: _secondsPerQuestion,),
                    const SizedBox(height: 14),
                    if (widget.listeningMode && !_answered)
                      _ListenButton(onTap: () => unawaited(_speakCurrent()))
                    else if (question.dialogueTurns != null)
                      _DialogueTranscript(
                        turns: question.dialogueTurns!,
                        onReplay: () => unawaited(_speakCurrent()),
                      )
                    else ...[
                      if (question.displayIsJapanese) ...[
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
                    _OptionsList(
                      question: question,
                      selectedOption: _selectedOption,
                      answered: _answered,
                      hiddenOptions: _hiddenOptions,
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
                ),
              ),
            ),
          ),
          if (_answered) ...[
            const SizedBox(height: 14),
            _FeedbackPanel(
              isCorrect: !_timedOut && _selectedOption == question.correctIndex,
              timedOut: _timedOut,
              xpGained: _lastXpGained,
              combo: _combo,
              correctAnswerLabel: question.options[question.correctIndex],
              onContinue: _onContinue,
            ),
          ],
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
    );
  }
}

/// Nút phát/nghe lại âm thanh trong [QuizScreen.listeningMode] — thay cho
/// hiển thị chữ Nhật, buộc người học phải nghe thay vì đọc.
class _ListenButton extends StatelessWidget {
  const _ListenButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        InkWell(
          borderRadius: BorderRadius.circular(100),
          onTap: onTap,
          child: Container(
            width: 68,
            height: 68,
            decoration: const BoxDecoration(
                color: AppColors.accentSoft, shape: BoxShape.circle,),
            alignment: Alignment.center,
            child: const Icon(Icons.volume_up_rounded,
                size: 32, color: AppColors.accentStrong,),
          ),
        ),
        const SizedBox(height: 8),
        const Text('Chạm để nghe lại',
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: AppColors.inkSoft,),),
      ],
    );
  }
}

/// Bản chép lời hội thoại nghe hiểu — chỉ hiện sau khi trả lời (học từ
/// script thật), tô màu khác theo từng speaker để dễ theo dõi ai nói gì.
class _DialogueTranscript extends StatelessWidget {
  const _DialogueTranscript({required this.turns, required this.onReplay});

  final List<ListeningTurn> turns;
  final VoidCallback onReplay;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('NỘI DUNG ĐÃ NGHE',
                style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                    color: AppColors.inkFaint,
                    letterSpacing: 0.6,),),
            const SizedBox(width: 4),
            InkWell(
              borderRadius: BorderRadius.circular(100),
              onTap: onReplay,
              child: const Padding(
                padding: EdgeInsets.all(4),
                child: Icon(Icons.volume_up_rounded,
                    size: 18, color: AppColors.accentStrong,),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border, width: 0.6),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var i = 0; i < turns.length; i++) ...[
                if (i > 0) const SizedBox(height: 8),
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: '${turns[i].speaker}: ',
                        style: TextStyle(
                            fontWeight: FontWeight.w800,
                            color: turns[i].speaker == 'A'
                                ? AppColors.accentStrong
                                : AppColors.indigo,),
                      ),
                      TextSpan(text: turns[i].jp),
                    ],
                  ),
                  style: AppFonts.zenMaruGothic(
                      fontSize: 15.5, color: AppColors.ink,),
                ),
              ],
            ],
          ),
        ),
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
  });

  final QuizQuestion question;
  final int? selectedOption;
  final bool answered;
  final Set<int> hiddenOptions;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < question.options.length; i++) ...[
          if (i > 0) const SizedBox(height: 10),
          _OptionCard(
            index: i,
            label: question.options[i],
            state: _stateFor(i),
            onTap: (answered || hiddenOptions.contains(i))
                ? null
                : () => onSelect(i),
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
    return Opacity(
      opacity: opacity,
      child: InkWell(
        borderRadius: BorderRadius.circular(15),
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: border, width: 2),
          ),
          child: Row(
            children: [
              Container(
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
            ],
          ),
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
  });

  final bool isCorrect;
  final bool timedOut;
  final int? xpGained;
  final int combo;
  final String correctAnswerLabel;
  final VoidCallback onContinue;

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
    required this.onGoHome,
    required this.onRestart,
  });

  final int correctCount;
  final int total;
  final int heartsLeft;
  final int bestCombo;
  final int xpEarned;
  final VoidCallback onGoHome;
  final VoidCallback onRestart;

  @override
  State<_SummaryPanel> createState() => _SummaryPanelState();
}

class _SummaryPanelState extends State<_SummaryPanel>
    with SingleTickerProviderStateMixin {
  late final AnimationController _confettiController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2200),
  )..forward();

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Positioned.fill(child: _ConfettiOverlay(animation: _confettiController)),
        Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
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
                        value: '${widget.xpEarned}',
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
                const SizedBox(height: 26),
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

/// Confetti rơi 1 lần khi hoàn thành quiz — thuần hiệu ứng UI ăn mừng,
/// không mang ý nghĩa dữ liệu nào (không cần thêm package ngoài).
class _ConfettiOverlay extends StatelessWidget {
  const _ConfettiOverlay({required this.animation});

  final Animation<double> animation;

  static final _pieces = List.generate(18, (i) {
    final random = Random(i * 37 + 1);
    const colors = [
      AppColors.accent,
      AppColors.moss,
      AppColors.indigo,
      AppColors.plum,
      AppColors.teal,
    ];
    return _ConfettiPiece(
      dx: random.nextDouble(),
      delay: random.nextDouble() * 0.3,
      color: colors[i % colors.length],
      size: 6 + random.nextDouble() * 5,
      spin: random.nextBool(),
    );
  });

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: animation,
        builder: (context, _) {
          return LayoutBuilder(
            builder: (context, constraints) {
              return Stack(
                children: [
                  for (final piece in _pieces) _buildPiece(piece, constraints),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildPiece(_ConfettiPiece piece, BoxConstraints constraints) {
    final t = ((animation.value - piece.delay) / (1 - piece.delay)).clamp(0.0, 1.0);
    final top = t * (constraints.maxHeight + 40) - 20;
    final angle = (piece.spin ? t : -t) * 6.2;
    return Positioned(
      left: piece.dx * constraints.maxWidth,
      top: top,
      child: Opacity(
        opacity: (1 - t).clamp(0.0, 1.0),
        child: Transform.rotate(
          angle: angle,
          child: Container(
            width: piece.size,
            height: piece.size * 1.6,
            decoration: BoxDecoration(
                color: piece.color, borderRadius: BorderRadius.circular(2),),
          ),
        ),
      ),
    );
  }
}

class _ConfettiPiece {
  const _ConfettiPiece({
    required this.dx,
    required this.delay,
    required this.color,
    required this.size,
    required this.spin,
  });

  final double dx;
  final double delay;
  final Color color;
  final double size;
  final bool spin;
}

class _StatChip extends StatelessWidget {
  const _StatChip(
      {required this.value,
      required this.label,
      required this.bg,
      required this.fg,});

  final String value;
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
