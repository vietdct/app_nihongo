import 'package:flutter/material.dart';

import '../../../core/services/dialogue_player.dart';
import '../../../core/theme/app_theme.dart';
import '../../../domain/entities/listening_dialogue.dart';
import '../../../domain/services/quiz_generator.dart';
import '../../../shared/dialogue_script_view.dart';

/// Bước nghe hiểu trong pha Practice — hội thoại thật (`ListeningDialogue`
/// qua `DialogueListeningGenerator`): nghe cả đoạn (mỗi nhân vật 1 giọng, có
/// tạm dừng), script bị che bằng ＊ và chỉ hiện từng lượt khi bấm nút mắt cuối
/// dòng (xem `DialogueListeningPanel`). Bấm "Kiểm tra" mới lộ đúng/sai và hiện
/// toàn bộ script — cùng nhịp thao tác với Grammar Practice.
class LessonListeningView extends StatefulWidget {
  const LessonListeningView({super.key, required this.question, required this.onDone});

  final QuizQuestion question;
  final VoidCallback onDone;

  @override
  State<LessonListeningView> createState() => _LessonListeningViewState();
}

class _LessonListeningViewState extends State<LessonListeningView> {
  final DialoguePlayer _player = DialoguePlayer();
  int? _selected;
  bool _checked = false;
  bool _wasCorrect = false;

  void _check() {
    setState(() {
      _checked = true;
      _wasCorrect = _selected == widget.question.correctIndex;
    });
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
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
                DialogueListeningPanel(
                  turns: turns,
                  player: _player,
                  revealAll: _checked,
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
