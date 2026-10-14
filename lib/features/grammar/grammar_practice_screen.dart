import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../../domain/services/grammar_practice_generator.dart';
import '../../shared/motion/animated_progress_bar.dart';
import 'providers/grammar_practice_providers.dart';

/// Practice mở rộng — khác `/quiz/grammar` (trắc nghiệm chọn-phát-ăn-ngay):
/// ở đây bấm "Kiểm tra" mới lộ đúng/sai, đúng 3 kiểu bài (xem
/// `grammar_practice_generator.dart`): ghép câu kiểu Duolingo (tap từ theo
/// đúng thứ tự), điền từ vào chỗ trống, ghép câu ví dụ đúng với mẫu ngữ pháp.
class GrammarPracticeScreen extends ConsumerStatefulWidget {
  const GrammarPracticeScreen({super.key});

  @override
  ConsumerState<GrammarPracticeScreen> createState() =>
      _GrammarPracticeScreenState();
}

class _GrammarPracticeScreenState extends ConsumerState<GrammarPracticeScreen> {
  int _index = 0;
  int _correctCount = 0;
  bool _checked = false;
  bool _wasCorrect = false;

  // wordOrder state
  List<String> _picked = [];
  List<String> _remaining = [];

  // fillBlank/matchSentence state
  int? _selectedOption;

  void _tapRemaining(int i) {
    if (_checked) return;
    setState(() {
      _picked.add(_remaining.removeAt(i));
    });
  }

  void _tapPicked(int i) {
    if (_checked) return;
    setState(() {
      _remaining.add(_picked.removeAt(i));
    });
  }

  void _selectOption(int i) {
    if (_checked) return;
    setState(() => _selectedOption = i);
  }

  void _check(GrammarExercise ex) {
    final bool correct;
    switch (ex.type) {
      case GrammarExerciseType.wordOrder:
        correct = _picked.length == ex.source.practiceTokens.length &&
            List.generate(_picked.length, (i) => _picked[i] == ex.source.practiceTokens[i])
                .every((ok) => ok);
      case GrammarExerciseType.fillBlank:
      case GrammarExerciseType.matchSentence:
        correct = _selectedOption == ex.correctIndex;
    }
    setState(() {
      _checked = true;
      _wasCorrect = correct;
      if (correct) _correctCount++;
    });
  }

  void _next() {
    setState(() {
      _index++;
      _checked = false;
      _wasCorrect = false;
      _selectedOption = null;
      _picked = [];
      _remaining = [];
    });
  }

  bool _canCheck(GrammarExercise ex) {
    switch (ex.type) {
      case GrammarExerciseType.wordOrder:
        return _remaining.isEmpty && _picked.isNotEmpty;
      case GrammarExerciseType.fillBlank:
      case GrammarExerciseType.matchSentence:
        return _selectedOption != null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final sessionAsync = ref.watch(grammarPracticeSessionProvider);

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(title: const Text('Luyện tập ngữ pháp')),
      body: sessionAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Lỗi: $e')),
        data: (exercises) {
          if (exercises.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Chưa đủ dữ liệu để luyện tập ở cấp độ này.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.inkSoft),
                ),
              ),
            );
          }

          if (_index >= exercises.length) {
            return _SummaryPanel(
              correctCount: _correctCount,
              total: exercises.length,
            );
          }

          final ex = exercises[_index];
          if (_remaining.isEmpty && _picked.isEmpty && !_checked) {
            _remaining = List.of(ex.tiles);
          }

          return Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
            child: Column(
              children: [
                Text(
                  'Câu ${_index + 1} / ${exercises.length}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppColors.inkSoft,
                  ),
                ),
                const SizedBox(height: 6),
                AnimatedProgressBar(
                  value: (_index + 1) / exercises.length,
                  minHeight: 6,
                  backgroundColor: AppColors.chip,
                  color: AppColors.plum,
                ),
                const SizedBox(height: 24),
                Expanded(
                  child: SingleChildScrollView(
                    child: switch (ex.type) {
                      GrammarExerciseType.wordOrder => _WordOrderExercise(
                          exercise: ex,
                          picked: _picked,
                          remaining: _remaining,
                          checked: _checked,
                          onTapPicked: _tapPicked,
                          onTapRemaining: _tapRemaining,
                        ),
                      GrammarExerciseType.fillBlank => _ChoiceExercise(
                          prompt: ex.blankPrompt!,
                          isJapanesePrompt: true,
                          options: ex.options,
                          selected: _selectedOption,
                          checked: _checked,
                          correctIndex: ex.correctIndex,
                          onSelect: _selectOption,
                        ),
                      GrammarExerciseType.matchSentence => _ChoiceExercise(
                          prompt: ex.source.title,
                          isJapanesePrompt: false,
                          options: ex.options,
                          selected: _selectedOption,
                          checked: _checked,
                          correctIndex: ex.correctIndex,
                          onSelect: _selectOption,
                        ),
                    },
                  ),
                ),
                const SizedBox(height: 16),
                if (_checked)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: _wasCorrect ? AppColors.mossSoft : AppColors.dangerSoft,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(
                      _wasCorrect ? 'Chính xác!' : 'Chưa đúng — xem lại đáp án ở trên.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: _wasCorrect ? AppColors.moss : AppColors.danger,
                      ),
                    ),
                  ),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _checked
                        ? _next
                        : (_canCheck(ex) ? () => _check(ex) : null),
                    style: FilledButton.styleFrom(backgroundColor: AppColors.plum),
                    child: Text(_checked ? 'Tiếp tục' : 'Kiểm tra'),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _WordOrderExercise extends StatelessWidget {
  const _WordOrderExercise({
    required this.exercise,
    required this.picked,
    required this.remaining,
    required this.checked,
    required this.onTapPicked,
    required this.onTapRemaining,
  });

  final GrammarExercise exercise;
  final List<String> picked;
  final List<String> remaining;
  final bool checked;
  final ValueChanged<int> onTapPicked;
  final ValueChanged<int> onTapRemaining;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          exercise.source.title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 15,
            color: AppColors.plum,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Sắp xếp các từ thành câu đúng',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 12, color: AppColors.inkSoft),
        ),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          constraints: const BoxConstraints(minHeight: 64),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (var i = 0; i < picked.length; i++)
                _Tile(
                  text: picked[i],
                  filled: true,
                  onTap: () => onTapPicked(i),
                ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 8,
          runSpacing: 8,
          children: [
            for (var i = 0; i < remaining.length; i++)
              _Tile(
                text: remaining[i],
                filled: false,
                onTap: () => onTapRemaining(i),
              ),
          ],
        ),
        if (checked) ...[
          const SizedBox(height: 16),
          Text(
            'Đáp án đúng: ${exercise.source.practiceTokens.join('')}',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12.5, color: AppColors.inkSoft),
          ),
        ],
      ],
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({required this.text, required this.filled, required this.onTap});

  final String text;
  final bool filled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: filled ? AppColors.plumSoft : AppColors.chip,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          text,
          style: AppFonts.zenMaruGothic(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: AppColors.ink,
          ),
        ),
      ),
    );
  }
}

class _ChoiceExercise extends StatelessWidget {
  const _ChoiceExercise({
    required this.prompt,
    required this.isJapanesePrompt,
    required this.options,
    required this.selected,
    required this.checked,
    required this.correctIndex,
    required this.onSelect,
  });

  final String prompt;
  final bool isJapanesePrompt;
  final List<String> options;
  final int? selected;
  final bool checked;
  final int correctIndex;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.plumSoft,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            prompt,
            textAlign: TextAlign.center,
            style: isJapanesePrompt
                ? AppFonts.zenMaruGothic(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                  )
                : const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.plum,
                  ),
          ),
        ),
        const SizedBox(height: 20),
        for (var i = 0; i < options.length; i++) ...[
          if (i > 0) const SizedBox(height: 10),
          _OptionRow(
            text: options[i],
            selected: selected == i,
            isCorrect: checked && i == correctIndex,
            isWrongSelected: checked && selected == i && i != correctIndex,
            onTap: () => onSelect(i),
          ),
        ],
      ],
    );
  }
}

class _OptionRow extends StatelessWidget {
  const _OptionRow({
    required this.text,
    required this.selected,
    required this.isCorrect,
    required this.isWrongSelected,
    required this.onTap,
  });

  final String text;
  final bool selected;
  final bool isCorrect;
  final bool isWrongSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    Color border = AppColors.border;
    Color bg = AppColors.card;
    if (isCorrect) {
      border = AppColors.moss;
      bg = AppColors.mossSoft;
    } else if (isWrongSelected) {
      border = AppColors.danger;
      bg = AppColors.dangerSoft;
    } else if (selected) {
      border = AppColors.plum;
      bg = AppColors.plumSoft;
    }

    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: border, width: 1.5),
        ),
        child: Text(
          text,
          style: AppFonts.zenMaruGothic(
            fontSize: 14.5,
            fontWeight: FontWeight.w600,
            color: AppColors.ink,
          ),
        ),
      ),
    );
  }
}

class _SummaryPanel extends StatelessWidget {
  const _SummaryPanel({required this.correctCount, required this.total});

  final int correctCount;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle_rounded, color: AppColors.moss, size: 56),
            const SizedBox(height: 16),
            const Text(
              'Hoàn thành phiên luyện tập!',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
            ),
            const SizedBox(height: 8),
            Text(
              'Đúng $correctCount / $total câu',
              style: const TextStyle(color: AppColors.inkSoft),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () => context.go('/'),
              style: FilledButton.styleFrom(backgroundColor: AppColors.plum),
              child: const Text('Về trang chủ'),
            ),
          ],
        ),
      ),
    );
  }
}
