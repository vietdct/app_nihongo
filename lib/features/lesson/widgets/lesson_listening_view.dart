import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../domain/entities/listening_dialogue.dart';
import '../../../domain/services/quiz_generator.dart';
import '../../../shared/jp_speak_button.dart';

/// Bước nghe hiểu trong pha Practice — hội thoại thật (`ListeningDialogue`
/// qua `DialogueListeningGenerator`) ẩn transcript mặc định để khuyến khích
/// nghe trước khi đọc (đúng kỹ năng cần luyện), người học có thể bấm loa
/// từng lượt thoại hoặc "Hiện hội thoại" để đọc lại bất cứ lúc nào. Bấm
/// "Kiểm tra" mới lộ đúng/sai — cùng nhịp thao tác với Grammar Practice để
/// nhất quán cảm giác luyện tập trong toàn app.
class LessonListeningView extends StatefulWidget {
  const LessonListeningView({super.key, required this.question, required this.onDone});

  final QuizQuestion question;
  final VoidCallback onDone;

  @override
  State<LessonListeningView> createState() => _LessonListeningViewState();
}

class _LessonListeningViewState extends State<LessonListeningView> {
  bool _revealed = false;
  int? _selected;
  bool _checked = false;
  bool _wasCorrect = false;

  void _check() {
    setState(() {
      _checked = true;
      _wasCorrect = _selected == widget.question.correctIndex;
      _revealed = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final q = widget.question;
    final turns = q.dialogueTurns ?? const <ListeningTurn>[];

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
                    'Nghe hiểu',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.moss),
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (var i = 0; i < turns.length; i++) ...[
                        if (i > 0) const SizedBox(height: 10),
                        _TurnRow(turn: turns[i], revealed: _revealed),
                      ],
                      if (turns.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Center(
                          child: TextButton.icon(
                            onPressed: () => setState(() => _revealed = !_revealed),
                            icon: Icon(_revealed ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 18),
                            label: Text(_revealed ? 'Ẩn hội thoại' : 'Hiện hội thoại'),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(color: AppColors.mossSoft, borderRadius: BorderRadius.circular(16)),
                  child: Text(
                    q.promptVi,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w700, color: AppColors.ink),
                  ),
                ),
                const SizedBox(height: 16),
                for (var i = 0; i < q.options.length; i++) ...[
                  if (i > 0) const SizedBox(height: 10),
                  _OptionRow(
                    text: q.options[i],
                    selected: _selected == i,
                    isCorrect: _checked && i == q.correctIndex,
                    isWrongSelected: _checked && _selected == i && i != q.correctIndex,
                    onTap: _checked ? null : () => setState(() => _selected = i),
                  ),
                ],
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
              _wasCorrect ? 'Chính xác!' : 'Chưa đúng — xem lại hội thoại ở trên.',
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.w800, color: _wasCorrect ? AppColors.moss : AppColors.danger),
            ),
          ),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: _checked ? widget.onDone : (_selected != null ? _check : null),
            style: FilledButton.styleFrom(backgroundColor: AppColors.moss),
            child: Text(_checked ? 'Tiếp tục' : 'Kiểm tra'),
          ),
        ),
      ],
    );
  }
}

class _TurnRow extends StatelessWidget {
  const _TurnRow({required this.turn, required this.revealed});

  final ListeningTurn turn;
  final bool revealed;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: 54,
          child: Text(
            turn.speaker,
            style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: AppColors.inkFaint),
          ),
        ),
        Expanded(
          child: Text(
            revealed ? turn.jp : '・・・・・・',
            style: AppFonts.zenMaruGothic(fontSize: 15, color: revealed ? AppColors.ink : AppColors.inkFaint),
          ),
        ),
        JpSpeakButton(text: turn.jp, color: AppColors.moss, size: 20),
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
        child: Text(text, style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w600, color: AppColors.ink)),
      ),
    );
  }
}
