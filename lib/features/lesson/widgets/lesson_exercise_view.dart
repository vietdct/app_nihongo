import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../domain/services/grammar_practice_generator.dart';
import '../../../domain/services/quiz_generator.dart';
import '../lesson_runner_steps.dart';

/// Bước luyện tập trong pha Practice — 1 câu hỏi ôn nội dung bài
/// ([LessonQuizPracticeItem], từ `QuizGenerator`) hoặc 1 bài ngữ pháp
/// ([LessonGrammarPracticeItem], từ `GrammarPracticeGenerator`). Cùng nhịp
/// "chọn → Kiểm tra → lộ đúng/sai → Tiếp tục" như `GrammarPracticeScreen`
/// nhưng xây widget riêng (không import lớp private của màn đó) — mỗi bước
/// đã là 1 instance widget mới do `PageView.itemBuilder` cấp, nên state
/// picked/selected tự reset đúng theo từng câu mà không cần logic reset thủ
/// công như màn Practice độc lập (nơi 1 State tái dùng cho cả phiên).
class LessonExerciseView extends StatefulWidget {
  const LessonExerciseView({super.key, required this.item, required this.onDone});

  final LessonPracticeItem item;
  final VoidCallback onDone;

  @override
  State<LessonExerciseView> createState() => _LessonExerciseViewState();
}

class _LessonExerciseViewState extends State<LessonExerciseView> {
  bool _checked = false;
  bool _wasCorrect = false;
  int? _selected;
  final List<String> _picked = [];
  List<String> _remaining = [];

  @override
  void initState() {
    super.initState();
    final item = widget.item;
    if (item is LessonGrammarPracticeItem && item.exercise.type == GrammarExerciseType.wordOrder) {
      _remaining = List.of(item.exercise.tiles);
    }
  }

  bool get _isWordOrder {
    final item = widget.item;
    return item is LessonGrammarPracticeItem && item.exercise.type == GrammarExerciseType.wordOrder;
  }

  bool get _canCheck => _isWordOrder ? (_remaining.isEmpty && _picked.isNotEmpty) : _selected != null;

  void _check() {
    final item = widget.item;
    final bool correct;
    switch (item) {
      case LessonQuizPracticeItem(:final question):
        correct = _selected == question.correctIndex;
      case LessonGrammarPracticeItem(:final exercise):
        correct = switch (exercise.type) {
          GrammarExerciseType.wordOrder => _picked.length == exercise.source.practiceTokens.length &&
              List.generate(_picked.length, (i) => _picked[i] == exercise.source.practiceTokens[i]).every((ok) => ok),
          GrammarExerciseType.fillBlank || GrammarExerciseType.matchSentence => _selected == exercise.correctIndex,
        };
    }
    setState(() {
      _checked = true;
      _wasCorrect = correct;
    });
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(color: AppColors.mossSoft, borderRadius: BorderRadius.circular(100)),
                  child: const Text(
                    'Luyện tập',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.moss),
                  ),
                ),
                const SizedBox(height: 16),
                switch (item) {
                  LessonQuizPracticeItem(:final question) => _QuizChoiceCard(
                      question: question,
                      selected: _selected,
                      checked: _checked,
                      onSelect: (i) => setState(() => _selected = i),
                    ),
                  LessonGrammarPracticeItem(:final exercise) => switch (exercise.type) {
                      GrammarExerciseType.wordOrder => _WordOrderCard(
                          exercise: exercise,
                          picked: _picked,
                          remaining: _remaining,
                          checked: _checked,
                          onTapPicked: (i) => setState(() => _remaining.add(_picked.removeAt(i))),
                          onTapRemaining: (i) => setState(() => _picked.add(_remaining.removeAt(i))),
                        ),
                      GrammarExerciseType.fillBlank => _ChoiceCard(
                          prompt: exercise.blankPrompt!,
                          isJapanesePrompt: true,
                          options: exercise.options,
                          selected: _selected,
                          checked: _checked,
                          correctIndex: exercise.correctIndex,
                          onSelect: (i) => setState(() => _selected = i),
                        ),
                      GrammarExerciseType.matchSentence => _ChoiceCard(
                          prompt: exercise.source.title,
                          isJapanesePrompt: false,
                          options: exercise.options,
                          selected: _selected,
                          checked: _checked,
                          correctIndex: exercise.correctIndex,
                          onSelect: (i) => setState(() => _selected = i),
                        ),
                    },
                },
              ],
            ),
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
              _wasCorrect ? 'Chính xác!' : 'Chưa đúng — xem đáp án ở trên.',
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.w800, color: _wasCorrect ? AppColors.moss : AppColors.danger),
            ),
          ),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: _checked ? widget.onDone : (_canCheck ? _check : null),
            style: FilledButton.styleFrom(backgroundColor: AppColors.moss),
            child: Text(_checked ? 'Tiếp tục' : 'Kiểm tra'),
          ),
        ),
      ],
    );
  }
}

class _QuizChoiceCard extends StatelessWidget {
  const _QuizChoiceCard({required this.question, required this.selected, required this.checked, required this.onSelect});

  final QuizQuestion question;
  final int? selected;
  final bool checked;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final displayIsJapanese = question.displayIsJapanese;
    final options = question.options;
    final correctIndex = question.correctIndex;
    final readingFurigana = question.readingFurigana;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: AppColors.mossSoft, borderRadius: BorderRadius.circular(16)),
          child: Column(
            children: [
              Text(
                question.promptVi,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.moss),
              ),
              const SizedBox(height: 8),
              if (readingFurigana != null)
                Text(readingFurigana, style: AppFonts.zenMaruGothic(fontSize: 13, color: AppColors.inkSoft)),
              Text(
                question.displayJp,
                textAlign: TextAlign.center,
                style: displayIsJapanese
                    ? AppFonts.zenMaruGothic(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.ink)
                    : const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AppColors.ink),
              ),
            ],
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
            onTap: checked ? null : () => onSelect(i),
          ),
        ],
      ],
    );
  }
}

class _WordOrderCard extends StatelessWidget {
  const _WordOrderCard({
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
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: AppColors.moss),
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
          decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.border)),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [for (var i = 0; i < picked.length; i++) _Tile(text: picked[i], filled: true, onTap: () => onTapPicked(i))],
          ),
        ),
        const SizedBox(height: 20),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 8,
          runSpacing: 8,
          children: [for (var i = 0; i < remaining.length; i++) _Tile(text: remaining[i], filled: false, onTap: () => onTapRemaining(i))],
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
        decoration: BoxDecoration(color: filled ? AppColors.mossSoft : AppColors.chip, borderRadius: BorderRadius.circular(10)),
        child: Text(text, style: AppFonts.zenMaruGothic(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.ink)),
      ),
    );
  }
}

class _ChoiceCard extends StatelessWidget {
  const _ChoiceCard({
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
          decoration: BoxDecoration(color: AppColors.mossSoft, borderRadius: BorderRadius.circular(16)),
          child: Text(
            prompt,
            textAlign: TextAlign.center,
            style: isJapanesePrompt
                ? AppFonts.zenMaruGothic(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.ink)
                : const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.moss),
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
            onTap: checked ? null : () => onSelect(i),
          ),
        ],
      ],
    );
  }
}

class _OptionRow extends StatelessWidget {
  const _OptionRow({required this.text, required this.selected, required this.isCorrect, required this.isWrongSelected, required this.onTap});

  final String text;
  final bool selected;
  final bool isCorrect;
  final bool isWrongSelected;
  final VoidCallback? onTap;

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
      border = AppColors.moss;
      bg = AppColors.mossSoft;
    }

    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(14), border: Border.all(color: border, width: 1.5)),
        child: Text(text, style: AppFonts.zenMaruGothic(fontSize: 14.5, fontWeight: FontWeight.w600, color: AppColors.ink)),
      ),
    );
  }
}
