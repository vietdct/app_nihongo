import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:go_router/go_router.dart';

import '../../../core/services/dialogue_player.dart'
    show speakerTransitionPause;
import '../../../core/services/jp_voice_prefs.dart';
import '../../../core/services/speaker_voices.dart';
import '../../../core/theme/app_theme.dart';
import '../../../domain/entities/listening_dialogue.dart';
import '../../../domain/services/quiz_generator.dart';
import '../../lesson/providers/level_providers.dart';
import 'exam_result_screen.dart';
import 'mini_test/mini_test_result_screen.dart';
import 'mini_test/models/mini_test_variant.dart';
import 'models/exam_review_answer.dart';
import 'providers/jlpt_exam_content_providers.dart';
import 'providers/jlpt_exam_session_providers.dart';

/// Màn làm bài "Thi thử JLPT" — khác `QuizScreen` (lib/features/quiz/quiz_screen.dart)
/// ở 3 điểm cốt lõi theo docs/JLPT_MOCK_EXAM_DESIGN.md §6: (1) KHÔNG hiện
/// đúng/sai ngay sau khi chọn đáp án, (2) đồng hồ đếm theo TỪNG SECTION
/// (hết giờ tự chuyển section kế) chứ không phải toàn bài, (3) chấm điểm 1
/// LẦN khi nộp bài. Vì khác biệt đủ lớn, đây là widget mới, không sửa
/// `QuizScreen`.
class ExamRunnerScreen extends ConsumerWidget {
  const ExamRunnerScreen({
    required this.levelId,
    required this.mode,
    this.overrideSections,
    super.key,
  });

  final String levelId;
  final String mode;

  /// Khi khác null, bỏ qua `examBlueprintProvider`/`examRunSectionsProvider`
  /// (tra `jlpt_exam_blueprints` theo levelId+mode) và dùng thẳng danh sách
  /// này — dành cho Mini Test (docs/JLPT_MINI_TEST_DESIGN.md §7, §13): Mini
  /// Test build đề ĐỘNG lúc runtime (`buildMiniTestRunSections`), không ghi
  /// vào bảng blueprint dùng chung nhiều người như Full Exam. Full Exam
  /// không truyền field này nên hành vi cũ giữ nguyên.
  final List<ExamRunSection>? overrideSections;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (overrideSections != null) {
      return Scaffold(
        backgroundColor: AppColors.canvas,
        body: SafeArea(
          child: overrideSections!.isEmpty
              ? const _EmptyExamMessage()
              : _ExamBody(
                  sections: overrideSections!,
                  blueprintId: null,
                  levelId: levelId,
                  mode: mode,
                ),
        ),
      );
    }

    final args = (levelId: levelId, mode: mode);
    final sectionsAsync = ref.watch(examRunSectionsProvider(args));
    final blueprint = ref.watch(examBlueprintProvider(args)).valueOrNull;

    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: SafeArea(
        child: sectionsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text('Không tải được đề thi: $error'),
            ),
          ),
          data: (sections) {
            if (sections.isEmpty) {
              return const _EmptyExamMessage();
            }
            return _ExamBody(
              sections: sections,
              blueprintId: blueprint?.id,
              levelId: levelId,
              mode: mode,
            );
          },
        ),
      ),
    );
  }
}

class _EmptyExamMessage extends StatelessWidget {
  const _EmptyExamMessage();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.hourglass_empty_rounded,
              size: 40,
              color: AppColors.inkFaint,
            ),
            const SizedBox(height: 12),
            const Text(
              'Chưa có đề cho cấp độ/chế độ này',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            const Text(
              'Đề đang được soạn thêm, quay lại sau nhé.',
              style: TextStyle(color: AppColors.inkSoft, fontSize: 13),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: () => Navigator.of(context).maybePop(),
              child: const Text('Quay lại'),
            ),
          ],
        ),
      ),
    );
  }
}

/// 1 câu trả lời tại chỗ (chưa gửi Supabase) — [selectedIndex] null nghĩa là
/// chưa trả lời câu này.
class _AnswerEntry {
  const _AnswerEntry({
    this.selectedIndex,
    this.flagged = false,
    this.bookmarked = false,
  });

  final int? selectedIndex;
  final bool flagged;
  final bool bookmarked;

  _AnswerEntry copyWith({
    int? selectedIndex,
    bool? flagged,
    bool? bookmarked,
  }) =>
      _AnswerEntry(
        selectedIndex: selectedIndex ?? this.selectedIndex,
        flagged: flagged ?? this.flagged,
        bookmarked: bookmarked ?? this.bookmarked,
      );
}

class _ExamBody extends ConsumerStatefulWidget {
  const _ExamBody({
    required this.sections,
    required this.blueprintId,
    required this.levelId,
    required this.mode,
  });

  final List<ExamRunSection> sections;
  final String? blueprintId;
  final String levelId;
  final String mode;

  @override
  ConsumerState<_ExamBody> createState() => _ExamBodyState();
}

class _ExamBodyState extends ConsumerState<_ExamBody> {
  String? _sessionId;
  int _sectionIndex = 0;
  int _questionIndex = 0;
  final Map<String, _AnswerEntry> _answers = {};
  Timer? _timer;
  int _secondsLeft = 0;
  bool _submitting = false;

  late final FlutterTts _tts;
  String? _lastSpokenKey;
  List<Map<String, String>> _japaneseVoices = [];
  Map<String, String>? _selectedVoice;
  AudioPlaybackSpeed _speed = AudioPlaybackSpeed.x100;

  /// Tăng mỗi khi cần huỷ 1 lượt đọc đang chạy dở (đổi câu/section). Vòng lặp
  /// trong [_speakListening] kiểm tra token này sau mỗi `await` — nếu đã đổi
  /// thì dừng ngay, không đọc tiếp lượt thoại kế. Bắt buộc phải có: gọi
  /// `_tts.stop()` khi đang `await _tts.speak(...)` (awaitSpeakCompletion)
  /// làm Future đó resolve ngay lập tức, nên nếu không chặn bằng token thì
  /// vòng lặp cũ vẫn chạy tiếp và tự phát đè câu thoại tiếp theo của câu CŨ.
  int _speakGeneration = 0;

  ExamRunSection get _currentSection => widget.sections[_sectionIndex];
  QuizQuestion get _currentQuestion =>
      _currentSection.questions[_questionIndex];
  String get _answerKey => '$_sectionIndex:$_questionIndex';
  _AnswerEntry get _currentEntry =>
      _answers[_answerKey] ?? const _AnswerEntry();

  @override
  void initState() {
    super.initState();
    _startSectionTimer();
    unawaited(_createSession());
    _tts = FlutterTts();
    unawaited(_loadTtsVoice());
  }

  /// Dùng chung khoá lưu giọng đọc với AI Kaiwa/Quiz (`jp_voice_prefs.dart`)
  /// — người dùng chọn giọng ở màn nào cũng áp dụng cho Nghe hiểu Mock Exam.
  Future<void> _loadTtsVoice() async {
    final cfg = await configureJpTts(_tts);
    final speed = await loadJpSpeechSpeed();
    if (!mounted) return;
    setState(() {
      _japaneseVoices = cfg.voices;
      _selectedVoice = cfg.saved;
      _speed = speed;
    });
  }

  /// Đổi giọng đọc — mở picker dùng chung với Kaiwa/Quiz, lưu lại lựa chọn
  /// (áp dụng cho lần nghe sau, không tự phát).
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
      onSpeedChanged: (s) => _speed = s,
    );
  }

  /// Đọc to 1 câu hỏi Nghe hiểu (Task 5 mở rộng): lần lượt từng lượt thoại,
  /// mỗi speaker 1 giọng riêng để nghe như người khác nhau (không có
  /// audio thu sẵn — xem docs/JLPT_MOCK_EXAM_DESIGN.md §9). Chỉ đọc hội thoại,
  /// không đọc câu hỏi/đáp án; chỉ chạy khi người dùng bấm "Nghe".
  Future<void> _speakListening(QuizQuestion question) async {
    final turns = question.dialogueTurns;
    if (turns == null) return;
    final generation = ++_speakGeneration;
    await applyIosTtsPlaybackCategory(_tts);
    await _tts.stop();
    // Mỗi nhân vật 1 giọng ja-JP thật khác nhau (chỉ tách bằng cao độ khi máy
    // thiếu giọng) — cùng bảng gán giọng với màn Nghe hiểu (`speaker_voices.dart`).
    final voices = assignSpeakerVoices(
      turns.speakerOrder,
      _japaneseVoices,
      _selectedVoice,
    );
    for (var i = 0; i < turns.length; i++) {
      if (!mounted || generation != _speakGeneration) return;
      final assigned = voices[turns[i].speaker];
      if (assigned?.voice != null) await _tts.setVoice(assigned!.voice!);
      await _tts.setPitch(assigned?.pitch ?? 1.0);
      await _tts.setSpeechRate(
        (_speed.ttsRate * (assigned?.rateFactor ?? 1.0)).clamp(0.1, 1.0),
      );
      await _tts.speak(prepareJpForSpeech(turns[i].jp));
      if (!mounted || generation != _speakGeneration) return;
      if (i + 1 < turns.length && turns[i + 1].speaker != turns[i].speaker) {
        await Future<void>.delayed(speakerTransitionPause);
      }
    }
    if (!mounted || generation != _speakGeneration) return;
    if (_selectedVoice != null) await _tts.setVoice(_selectedVoice!);
    await _tts.setPitch(1.0);
    await _tts.setSpeechRate(_speed.ttsRate);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _speakGeneration++;
    unawaited(_tts.stop());
    super.dispose();
  }

  Future<void> _createSession() async {
    final repo = ref.read(examSessionRepositoryProvider);
    if (repo == null) return;
    final id = await repo.createSession(
      levelId: widget.levelId,
      mode: widget.mode,
      blueprintId: widget.blueprintId,
    );
    if (!mounted) return;
    setState(() => _sessionId = id);
  }

  void _startSectionTimer() {
    _timer?.cancel();
    _secondsLeft = _currentSection.timeMinutes * 60;
    // timeMinutes <= 0 = "Không giới hạn" (Mini Test §4, JLPT_MINI_TEST_DESIGN.md)
    // — không chạy đếm ngược, tránh _secondsLeft<=1 tự nộp bài ngay lập tức
    // như thể "hết giờ" (bug thật gặp lúc verify Quick 5, không phải giả định).
    if (_currentSection.timeMinutes <= 0) return;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      if (_secondsLeft <= 1) {
        _timer?.cancel();
        setState(() => _secondsLeft = 0);
        _advanceSectionOrFinish();
        return;
      }
      setState(() => _secondsLeft--);
    });
  }

  void _selectOption(int index) {
    final entry = _currentEntry.copyWith(selectedIndex: index);
    setState(() => _answers[_answerKey] = entry);
    _persistAnswer(entry);
  }

  void _persistAnswer(_AnswerEntry entry) {
    final repo = ref.read(examSessionRepositoryProvider);
    final sessionId = _sessionId;
    if (repo == null || sessionId == null) return;
    final question = _currentQuestion;
    unawaited(
      repo.saveAnswer(
        sessionId: sessionId,
        sectionType: _currentSection.type,
        questionIndex: _questionIndex,
        questionSnapshot: quizQuestionToSnapshot(question),
        selectedIndex: entry.selectedIndex,
        isCorrect: entry.selectedIndex == null
            ? null
            : entry.selectedIndex == question.correctIndex,
        bookmarked: entry.bookmarked,
        flagged: entry.flagged,
      ),
    );
  }

  static const _sectionLabels = {
    'vocabulary': 'Từ vựng',
    'grammar': 'Ngữ pháp',
    'kanji': 'Kanji',
    'reading': 'Đọc hiểu',
    'listening': 'Nghe hiểu',
    'mixed': 'Tổng hợp',
  };

  /// Trong 1 section: tự do xem/sửa lại câu đã làm (đúng yêu cầu "cho xem
  /// lại sửa nếu làm sai"). Ở câu CUỐI section: bắt buộc xác nhận "Nộp
  /// phần" trước khi qua section kế — sau khi xác nhận sẽ KHÔNG lùi lại
  /// được section vừa nộp nữa (xem [_goPrev]), đúng cấu trúc JLPT thật:
  /// mỗi phần thi có giờ riêng, nộp phần nào xong thì chốt phần đó.
  Future<void> _goNext() async {
    if (_questionIndex < _currentSection.questions.length - 1) {
      setState(() => _questionIndex++);
      return;
    }
    final isLastSection = _sectionIndex == widget.sections.length - 1;
    final sectionLabel =
        _sectionLabels[_currentSection.type] ?? _currentSection.type;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(isLastSection ? 'Nộp bài thi?' : 'Nộp phần $sectionLabel?'),
        content: Text(
          isLastSection
              ? 'Bạn đã làm xong tất cả các phần. Nộp bài ngay?'
              : 'Sau khi qua phần tiếp theo, bạn sẽ KHÔNG thể quay lại sửa '
                  'câu trả lời của phần $sectionLabel nữa.',
        ),
        actions: [
          Row(
            children: [
              Expanded(
                child: FilledButton(
                  onPressed: () => Navigator.of(dialogContext).pop(true),
                  child: const Text('Nộp bài'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.of(dialogContext).pop(false),
                  child: const Text('Huỷ'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      _advanceSectionOrFinish();
    }
  }

  /// Cho phép thoát giữa chừng ở BẤT KỲ câu nào (không chỉ lúc nộp phần) —
  /// đánh dấu session 'abandoned' qua [ExamSessionRepository.abandonSession]
  /// (đã có sẵn ở backend, trước đây chưa nơi nào gọi tới) thay vì để session
  /// treo mãi ở trạng thái 'in_progress' trong Supabase.
  Future<void> _confirmExit() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Thoát bài thi?'),
        content: const Text(
          'Bài làm dở sẽ không được tính điểm. Bạn có chắc muốn thoát không?',
        ),
        actions: [
          Row(
            children: [
              Expanded(
                child: FilledButton(
                  onPressed: () => Navigator.of(dialogContext).pop(true),
                  child: const Text('Thoát'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.of(dialogContext).pop(false),
                  child: const Text('Tiếp tục làm bài'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    _timer?.cancel();
    _speakGeneration++;
    unawaited(_tts.stop());
    final repo = ref.read(examSessionRepositoryProvider);
    final sessionId = _sessionId;
    if (repo != null && sessionId != null) {
      unawaited(repo.abandonSession(sessionId));
    }
    if (mounted) Navigator.of(context).pop();
  }

  /// Chỉ lùi được TRONG section hiện tại — không cho quay lại section trước
  /// (đã nộp qua hộp thoại xác nhận ở [_goNext] hoặc do hết giờ).
  void _goPrev() {
    if (_questionIndex > 0) {
      setState(() => _questionIndex--);
    }
  }

  void _advanceSectionOrFinish() {
    if (_sectionIndex < widget.sections.length - 1) {
      setState(() {
        _sectionIndex++;
        _questionIndex = 0;
      });
      _startSectionTimer();
    } else {
      unawaited(_submit());
    }
  }

  /// Chấm điểm thô theo section (đúng/tổng) — TẠM, chưa phải thang điểm
  /// JLPT thật (Official Timing/thang điểm chính thức làm ở Task 7, xem
  /// docs/JLPT_MOCK_EXAM_DESIGN.md §10, §20). Ghi score vào
  /// `jlpt_exam_sessions` rồi điều hướng sang `ExamResultScreen`.
  Future<void> _submit() async {
    if (_submitting) return;
    setState(() => _submitting = true);
    _timer?.cancel();

    final score = <String, ExamSectionScore>{};
    final reviewSections = <ExamReviewSection>[];
    for (var s = 0; s < widget.sections.length; s++) {
      final section = widget.sections[s];
      var correct = 0;
      final answers = <ExamReviewAnswer>[];
      for (var q = 0; q < section.questions.length; q++) {
        final entry = _answers['$s:$q'];
        final question = section.questions[q];
        if (entry?.selectedIndex == question.correctIndex) {
          correct++;
        }
        answers.add(
          ExamReviewAnswer(
            question: question,
            selectedIndex: entry?.selectedIndex,
          ),
        );
      }
      score[section.type] =
          ExamSectionScore(correct: correct, total: section.questions.length);
      reviewSections.add(ExamReviewSection(type: section.type, answers: answers));
    }

    final repo = ref.read(examSessionRepositoryProvider);
    final sessionId = _sessionId;
    if (repo != null && sessionId != null) {
      await repo.submitSession(
        sessionId: sessionId,
        score: {
          for (final e in score.entries)
            e.key: {'correct': e.value.correct, 'total': e.value.total},
        },
      );
    }

    // Mini Test (docs/JLPT_MINI_TEST_DESIGN.md §1, §9): KHÔNG có PassFail/
    // scaledScore kiểu JLPT thật — 5-20 câu không đủ đại diện 1 đề JLPT, nên
    // rẽ sang MiniTestResultScreen thay vì ExamResultScreen (route khác
    // nhau dựa theo mode bắt đầu 'mini_'). `jlpt_exam_sessions`/`_answers`
    // vẫn ghi như trên — chỉ khác màn kết quả hiển thị.
    if (widget.mode.startsWith('mini_')) {
      final variant = MiniTestVariant.values.firstWhere(
        (v) => 'mini_${v.name}' == widget.mode,
        orElse: () => MiniTestVariant.quick5,
      );
      final totalQuestionCount =
          widget.sections.fold(0, (n, s) => n + s.questions.length);
      final sourceTypes = <String>{};
      for (final s in widget.sections) {
        for (final q in s.questions) {
          final t = q.sourceType;
          if (t != null) sourceTypes.add(t.name);
        }
      }

      if (!mounted) return;
      context.pushReplacement(
        '/review/jlpt-exam/${widget.levelId}/mini/result',
        extra: MiniTestResultArgs(
          levelId: widget.levelId,
          variant: variant,
          questionCount: totalQuestionCount,
          sources: sourceTypes.toList(),
          reviewSections: reviewSections,
        ),
      );
      return;
    }

    final levels = ref.read(jlptLevelsProvider).valueOrNull ?? [];
    var levelCode = '';
    for (final l in levels) {
      if (l.id == widget.levelId) {
        levelCode = l.code;
        break;
      }
    }

    if (!mounted) return;
    context.pushReplacement(
      '/review/jlpt-exam/result',
      extra: ExamResultArgs(
        score: score,
        levelCode: levelCode,
        reviewSections: reviewSections,
      ),
    );
  }

  Future<void> _openPalette() async {
    final target = await showModalBottomSheet<int>(
      context: context,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => _QuestionPaletteSheet(
        section: _currentSection,
        answers: _answers,
        sectionIndex: _sectionIndex,
        currentQuestionIndex: _questionIndex,
      ),
    );
    if (target != null && mounted) {
      setState(() => _questionIndex = target);
    }
  }

  @override
  Widget build(BuildContext context) {
    final question = _currentQuestion;
    final entry = _currentEntry;
    final isLastQuestionOfExam = _sectionIndex == widget.sections.length - 1 &&
        _questionIndex == _currentSection.questions.length - 1;

    // Âm thanh chỉ phát khi người dùng bấm "Nghe" — không tự phát khi vào câu.
    // Khi đổi câu (Next/Prev/nhảy từ Bảng câu hỏi) thì dừng ngay tiếng đang
    // đọc dở của câu cũ, kể cả khi sang câu không phải Nghe hiểu (VD Đọc hiểu);
    // so `_lastSpokenKey` với `_answerKey` bắt được mọi đường vào câu mà không
    // cần gắn hook riêng ở từng hàm điều hướng.
    if (_lastSpokenKey != _answerKey) {
      _lastSpokenKey = _answerKey;
      _speakGeneration++;
      unawaited(_tts.stop());
    }

    return Column(
      children: [
        _ExamHeader(
          sections: widget.sections,
          currentSectionIndex: _sectionIndex,
          secondsLeft: _secondsLeft,
          questionNumber: _questionIndex + 1,
          questionTotal: _currentSection.questions.length,
          flagged: entry.flagged,
          bookmarked: entry.bookmarked,
          onExit: _confirmExit,
          onToggleFlag: () {
            final updated = entry.copyWith(flagged: !entry.flagged);
            setState(() => _answers[_answerKey] = updated);
            _persistAnswer(updated);
          },
          onToggleBookmark: () {
            final updated = entry.copyWith(bookmarked: !entry.bookmarked);
            setState(() => _answers[_answerKey] = updated);
            _persistAnswer(updated);
          },
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
            child: Column(
              children: [
                if (question.readingPassageBodyJa != null) ...[
                  _ReadingPassageCard(
                    title: question.readingPassageTitle ?? '',
                    bodyJa: question.readingPassageBodyJa!,
                  ),
                  const SizedBox(height: 14),
                  Text(
                    question.promptVi,
                    textAlign: TextAlign.center,
                    style: AppFonts.zenMaruGothic(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: AppColors.ink,
                    ),
                  ),
                ] else if (question.dialogueTurns != null) ...[
                  Text(
                    question.promptVi,
                    textAlign: TextAlign.center,
                    style: AppFonts.zenMaruGothic(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: AppColors.ink,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Center(
                    child: Wrap(
                      alignment: WrapAlignment.center,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        TextButton.icon(
                          onPressed: () =>
                              unawaited(_speakListening(question)),
                          icon: const Icon(Icons.volume_up_rounded, size: 18),
                          label: const Text('Nghe'),
                        ),
                        IconButton(
                          onPressed: _openVoicePicker,
                          tooltip: 'Đổi giọng đọc',
                          icon: const Icon(
                            Icons.record_voice_over_outlined,
                            size: 20,
                            color: AppColors.inkFaint,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  _ListeningTranscriptReveal(
                    key: ValueKey('listening-$_answerKey'),
                    turns: question.dialogueTurns!,
                  ),
                ] else
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Text(
                      question.displayJp,
                      textAlign: TextAlign.center,
                      style: question.displayIsJapanese
                          ? AppFonts.zenMaruGothic(
                              fontSize: 24,
                              color: AppColors.ink,
                            )
                          : const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: AppColors.ink,
                            ),
                    ),
                  ),
                const SizedBox(height: 20),
                for (var i = 0; i < question.options.length; i++) ...[
                  if (i > 0) const SizedBox(height: 10),
                  _ExamOptionTile(
                    index: i,
                    label: question.options[i],
                    selected: entry.selectedIndex == i,
                    onTap: () => _selectOption(i),
                  ),
                ],
              ],
            ),
          ),
        ),
        _ExamBottomBar(
          canGoPrev: !_submitting && _questionIndex > 0,
          isLastQuestion: isLastQuestionOfExam,
          submitting: _submitting,
          onPrev: _goPrev,
          onNext: _submitting ? null : _goNext,
          onOpenPalette: _submitting ? null : _openPalette,
        ),
      ],
    );
  }
}

class _ExamHeader extends StatelessWidget {
  const _ExamHeader({
    required this.sections,
    required this.currentSectionIndex,
    required this.secondsLeft,
    required this.questionNumber,
    required this.questionTotal,
    required this.flagged,
    required this.bookmarked,
    required this.onExit,
    required this.onToggleFlag,
    required this.onToggleBookmark,
  });

  final List<ExamRunSection> sections;
  final int currentSectionIndex;
  final int secondsLeft;
  final int questionNumber;
  final int questionTotal;
  final bool flagged;
  final bool bookmarked;
  final VoidCallback onExit;
  final VoidCallback onToggleFlag;
  final VoidCallback onToggleBookmark;

  static const _sectionLabels = {
    'vocabulary': 'Từ vựng',
    'grammar': 'Ngữ pháp',
    'kanji': 'Kanji',
    'reading': 'Đọc hiểu',
    'listening': 'Nghe hiểu',
    'mixed': 'Tổng hợp',
  };

  @override
  Widget build(BuildContext context) {
    // timeMinutes <= 0 = "Không giới hạn" — ẩn đồng hồ thay vì hiện "00:00"
    // (dễ hiểu lầm là hết giờ). Xem _ExamBodyState._startSectionTimer.
    final unlimited = sections[currentSectionIndex].timeMinutes <= 0;
    final minutes = secondsLeft ~/ 60;
    final seconds = secondsLeft % 60;
    final timeLabel =
        '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    final lowOnTime = secondsLeft <= 120;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 6),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (unlimited)
                const Row(
                  children: [
                    Icon(
                      Icons.all_inclusive_rounded,
                      size: 18,
                      color: AppColors.inkSoft,
                    ),
                    SizedBox(width: 6),
                    Text(
                      'Không giới hạn',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                        color: AppColors.ink,
                      ),
                    ),
                  ],
                )
              else
                Row(
                  children: [
                    Icon(
                      Icons.timer_outlined,
                      size: 18,
                      color: lowOnTime ? AppColors.danger : AppColors.inkSoft,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      timeLabel,
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                        color: lowOnTime ? AppColors.danger : AppColors.ink,
                      ),
                    ),
                  ],
                ),
              Text(
                _sectionLabels[sections[currentSectionIndex].type] ??
                    sections[currentSectionIndex].type,
                style:
                    const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
              ),
              Row(
                children: [
                  for (var i = 0; i < sections.length; i++) ...[
                    if (i > 0) const SizedBox(width: 4),
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: i == currentSectionIndex
                            ? AppColors.indigo
                            : (i < currentSectionIndex
                                ? AppColors.moss
                                : AppColors.chip),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              IconButton(
                onPressed: onExit,
                tooltip: 'Thoát bài thi',
                icon: const Icon(
                  Icons.close_rounded,
                  color: AppColors.inkFaint,
                ),
              ),
              Expanded(
                child: Text(
                  'Câu $questionNumber/$questionTotal',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: AppColors.inkSoft,
                  ),
                ),
              ),
              IconButton(
                onPressed: onToggleBookmark,
                tooltip: bookmarked ? 'Bỏ đánh dấu' : 'Đánh dấu câu này',
                icon: Icon(
                  bookmarked ? Icons.bookmark : Icons.bookmark_outline,
                  color:
                      bookmarked ? AppColors.accentStrong : AppColors.inkFaint,
                ),
              ),
              IconButton(
                onPressed: onToggleFlag,
                tooltip: flagged ? 'Bỏ gắn cờ' : 'Gắn cờ để xem lại',
                icon: Icon(
                  flagged ? Icons.flag : Icons.outlined_flag,
                  color: flagged ? AppColors.danger : AppColors.inkFaint,
                ),
              ),
            ],
          ),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: questionNumber / questionTotal,
              minHeight: 6,
              backgroundColor: AppColors.chip,
              valueColor: const AlwaysStoppedAnimation(AppColors.indigo),
            ),
          ),
        ],
      ),
    );
  }
}

/// Bọc [_ListeningTranscriptCard] sau 1 lớp ẩn/hiện — mặc định ẨN, chỉ hiện
/// câu hỏi + đáp án để chọn, mô phỏng đúng thi nghe thật (nghe 1 lần rồi
/// chọn, không được đọc lại script trong lúc làm bài). Người học có thể bấm
/// mở ra xem lại nếu cần (luyện tập/kiểm tra), không ép buộc như thi thật.
/// State cục bộ, RESET về ẩn mỗi khi sang câu khác nhờ `Key` ở nơi gọi
/// (`ValueKey('listening-$_answerKey')`) — không lưu vào Supabase, không
/// ảnh hưởng chấm điểm.
class _ListeningTranscriptReveal extends StatefulWidget {
  const _ListeningTranscriptReveal({required this.turns, super.key});

  final List<ListeningTurn> turns;

  @override
  State<_ListeningTranscriptReveal> createState() =>
      _ListeningTranscriptRevealState();
}

class _ListeningTranscriptRevealState
    extends State<_ListeningTranscriptReveal> {
  bool _revealed = false;

  @override
  Widget build(BuildContext context) {
    if (!_revealed) {
      return InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => setState(() => _revealed = true),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.chip,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.border),
          ),
          child: const Column(
            children: [
              Icon(
                Icons.visibility_off_outlined,
                color: AppColors.inkFaint,
                size: 22,
              ),
              SizedBox(height: 8),
              Text(
                'Nội dung hội thoại đã ẩn — chọn đáp án như khi nghe thật',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.inkSoft,
                ),
              ),
              SizedBox(height: 6),
              Text(
                'Bấm để xem lại nội dung',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: AppColors.accentStrong,
                ),
              ),
            ],
          ),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _ListeningTranscriptCard(turns: widget.turns),
        const SizedBox(height: 8),
        Center(
          child: TextButton.icon(
            onPressed: () => setState(() => _revealed = false),
            icon: const Icon(Icons.visibility_off_outlined, size: 16),
            label: const Text('Ẩn nội dung'),
          ),
        ),
      ],
    );
  }
}

/// Transcript hội thoại nghe hiểu — hiện text, KHÔNG có nút phát âm thanh
/// (khác `_DialogueTranscript` ở `QuizScreen`): bảng `listening_dialogues`
/// chưa có `audio_url` thật, Exam Mode không bịa TTS giả làm "âm thanh thi
/// thật" (xem docs/JLPT_MOCK_EXAM_DESIGN.md §9) — người học đọc hội thoại
/// thay vì nghe, đúng bản chất MVP transcript-based. Mặc định ẨN cho tới khi
/// người học bấm mở (xem [_ListeningTranscriptReveal]).
class _ListeningTranscriptCard extends StatelessWidget {
  const _ListeningTranscriptCard({required this.turns});

  final List<ListeningTurn> turns;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
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
                          : AppColors.indigo,
                    ),
                  ),
                  TextSpan(text: turns[i].jp),
                ],
              ),
              style: AppFonts.zenMaruGothic(
                fontSize: 15.5,
                color: AppColors.ink,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Khung đoạn văn Đọc hiểu — hiện nguyên văn, KHÔNG dịch, KHÔNG tra từ điển
/// (Dictionary Disabled ở Exam Mode, xem docs/JLPT_MOCK_EXAM_DESIGN.md §8).
/// Luôn hiện sẵn cùng câu hỏi (khác Listening — đọc hiểu thật cho đọc lại
/// đoạn văn thoải mái, không mô phỏng "nghe 1 lần" như audio).
class _ReadingPassageCard extends StatelessWidget {
  const _ReadingPassageCard({required this.title, required this.bodyJa});

  final String title;
  final String bodyJa;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title.isNotEmpty) ...[
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 14,
                color: AppColors.indigo,
              ),
            ),
            const SizedBox(height: 8),
          ],
          Text(
            bodyJa,
            style: AppFonts.zenMaruGothic(fontSize: 16, color: AppColors.ink)
                .copyWith(height: 1.8),
          ),
        ],
      ),
    );
  }
}

/// Ô lựa chọn đáp án — KHÔNG hiện đúng/sai (khác `_OptionCard` ở `QuizScreen`),
/// chỉ có 2 trạng thái: chưa chọn / đã chọn.
class _ExamOptionTile extends StatelessWidget {
  const _ExamOptionTile({
    required this.index,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final int index;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: selected ? AppColors.indigoSoft : AppColors.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? AppColors.indigo : AppColors.border,
            width: selected ? 1.4 : 1.0,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 26,
              height: 26,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: selected ? AppColors.indigo : AppColors.chip,
              ),
              child: Text(
                String.fromCharCode(65 + index),
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                  color: selected ? Colors.white : AppColors.inkSoft,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(fontSize: 15, color: AppColors.ink),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExamBottomBar extends StatelessWidget {
  const _ExamBottomBar({
    required this.canGoPrev,
    required this.isLastQuestion,
    required this.submitting,
    required this.onPrev,
    required this.onNext,
    required this.onOpenPalette,
  });

  final bool canGoPrev;
  final bool isLastQuestion;
  final bool submitting;
  final VoidCallback onPrev;
  final VoidCallback? onNext;
  final VoidCallback? onOpenPalette;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 14),
      decoration: const BoxDecoration(
        color: AppColors.card,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          OutlinedButton(
            onPressed: canGoPrev ? onPrev : null,
            style: OutlinedButton.styleFrom(padding: const EdgeInsets.all(12)),
            child: const Icon(Icons.chevron_left_rounded),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: onOpenPalette,
              icon: const Icon(Icons.grid_view_rounded, size: 18),
              label: const Text('Bảng câu hỏi'),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: FilledButton.icon(
              onPressed: onNext,
              icon: submitting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation(Colors.white),
                      ),
                    )
                  : Icon(
                      isLastQuestion
                          ? Icons.check_rounded
                          : Icons.chevron_right_rounded,
                    ),
              label: Text(
                submitting
                    ? 'Đang nộp...'
                    : (isLastQuestion ? 'Nộp bài' : 'Sau'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Bottom sheet lưới nhảy câu (Task 4.4) — hiện đúng phần đang làm (JLPT
/// điều hướng tự do trong 1 section, không nhảy chéo section vì mỗi section
/// có đồng hồ riêng — xem docs/JLPT_MOCK_EXAM_DESIGN.md §7). Trả về index
/// câu được chọn qua `Navigator.pop`.
class _QuestionPaletteSheet extends StatelessWidget {
  const _QuestionPaletteSheet({
    required this.section,
    required this.answers,
    required this.sectionIndex,
    required this.currentQuestionIndex,
  });

  final ExamRunSection section;
  final Map<String, _AnswerEntry> answers;
  final int sectionIndex;
  final int currentQuestionIndex;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 14),
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(99),
              ),
            ),
            const Text(
              'Bảng câu hỏi',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
            ),
            const SizedBox(height: 12),
            const _PaletteLegend(),
            const SizedBox(height: 16),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: section.questions.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 5,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
              ),
              itemBuilder: (context, i) {
                final entry =
                    answers['$sectionIndex:$i'] ?? const _AnswerEntry();
                return _PaletteCell(
                  number: i + 1,
                  answered: entry.selectedIndex != null,
                  flagged: entry.flagged,
                  bookmarked: entry.bookmarked,
                  isCurrent: i == currentQuestionIndex,
                  onTap: () => Navigator.of(context).pop(i),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _PaletteLegend extends StatelessWidget {
  const _PaletteLegend();

  @override
  Widget build(BuildContext context) {
    Widget dot(Color color) => Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        );
    const labelStyle = TextStyle(fontSize: 11, color: AppColors.inkSoft);
    return Wrap(
      spacing: 14,
      runSpacing: 6,
      alignment: WrapAlignment.center,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            dot(AppColors.indigo),
            const SizedBox(width: 4),
            const Text('Đã làm', style: labelStyle),
          ],
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            dot(AppColors.chip),
            const SizedBox(width: 4),
            const Text('Chưa làm', style: labelStyle),
          ],
        ),
        const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.flag, size: 12, color: AppColors.danger),
            SizedBox(width: 4),
            Text('Đã đánh dấu', style: labelStyle),
          ],
        ),
      ],
    );
  }
}

class _PaletteCell extends StatelessWidget {
  const _PaletteCell({
    required this.number,
    required this.answered,
    required this.flagged,
    required this.bookmarked,
    required this.isCurrent,
    required this.onTap,
  });

  final int number;
  final bool answered;
  final bool flagged;
  final bool bookmarked;
  final bool isCurrent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Câu $number'
          '${answered ? ', đã làm' : ', chưa làm'}'
          '${flagged ? ', đã đánh dấu' : ''}'
          '${bookmarked ? ', đã lưu' : ''}',
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: answered ? AppColors.indigoSoft : AppColors.chip,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isCurrent
                  ? AppColors.indigo
                  : (flagged ? AppColors.danger : Colors.transparent),
              width: isCurrent ? 2 : 1.4,
            ),
          ),
          child: Stack(
            children: [
              Center(
                child: Text(
                  '$number',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                    color: answered ? AppColors.indigo : AppColors.inkSoft,
                  ),
                ),
              ),
              if (bookmarked)
                const Positioned(
                  top: 2,
                  right: 2,
                  child: Icon(
                    Icons.bookmark,
                    size: 10,
                    color: AppColors.accentStrong,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
