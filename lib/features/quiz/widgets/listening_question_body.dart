import 'package:flutter/material.dart';

import '../../../core/services/dialogue_player.dart';
import '../../../core/theme/app_theme.dart';
import '../../../domain/services/quiz_generator.dart';
import '../../../shared/dialogue_script_view.dart';

/// Giai đoạn của 1 câu Nghe hiểu — nguồn DUY NHẤT quyết định có dựng Script
/// hay không (xem [showScript]). Được suy ra từ state của `QuizScreen`
/// (đã trả lời? hết giờ? người học đã bấm xem script?) nên rebuild/xoay màn
/// hình không thể làm script tự lộ ra ở giai đoạn [listening].
enum ListeningPhase {
  /// Đang nghe/chọn đáp án — Script KHÔNG được dựng trong widget tree.
  listening,

  /// Đã trả lời, script vẫn ẩn (chỉ hiện nút "Scriptを見る").
  answered,

  /// Hết giờ, script vẫn ẩn cho tới khi người học chủ động xem.
  timeout,

  /// Đã trả lời/hết giờ và người học bấm xem — hiện thẻ Script đầy đủ.
  reviewing;

  bool get isAnswered => this != listening;
  bool get showScript => this == reviewing;
}

/// Câu hỏi Nghe hiểu hội thoại: header gọn → câu hỏi → nghe → đáp án →
/// kết quả → script (chỉ sau khi trả lời). Không tự giữ state, mọi thứ do
/// `QuizScreen` truyền vào.
class ListeningQuestionBody extends StatelessWidget {
  const ListeningQuestionBody({
    super.key,
    required this.title,
    required this.index,
    required this.total,
    required this.hearts,
    required this.timerController,
    required this.timerSeconds,
    required this.question,
    required this.player,
    required this.phase,
    required this.selectedOption,
    required this.hiddenOptions,
    required this.hintUsed,
    required this.isCorrect,
    required this.timedOut,
    required this.xpGained,
    required this.combo,
    required this.scrollController,
    required this.onClose,
    required this.onVoicePicker,
    required this.onSelect,
    required this.onHint,
    required this.onShowScript,
    required this.onContinue,
  });

  final String title;
  final int index;
  final int total;
  final int hearts;
  final AnimationController timerController;
  final int timerSeconds;
  final QuizQuestion question;
  final DialoguePlayer player;
  final ListeningPhase phase;
  final int? selectedOption;
  final Set<int> hiddenOptions;
  final bool hintUsed;
  final bool isCorrect;
  final bool timedOut;
  final int? xpGained;
  final int combo;
  final ScrollController scrollController;
  final VoidCallback onClose;
  final VoidCallback onVoicePicker;
  final ValueChanged<int> onSelect;
  final VoidCallback onHint;
  final VoidCallback onShowScript;
  final VoidCallback onContinue;

  /// Đề bài kết thúc bằng 「か。」 thì đổi thành 「か？」 cho dễ đọc là câu hỏi.
  static String questionText(String raw) =>
      raw.endsWith('か。') ? '${raw.substring(0, raw.length - 1)}？' : raw;

  @override
  Widget build(BuildContext context) {
    final turns = question.dialogueTurns ?? const [];
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Header(
            title: title,
            index: index,
            total: total,
            hearts: hearts,
            answered: phase.isAnswered,
            timerController: timerController,
            timerSeconds: timerSeconds,
            onClose: onClose,
            onVoicePicker: onVoicePicker,
          ),
          Expanded(
            child: SingleChildScrollView(
              controller: scrollController,
              padding: const EdgeInsets.only(top: 22, bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 340),
                      child: Text(
                        questionText(question.promptVi),
                        textAlign: TextAlign.center,
                        style: AppFonts.zenMaruGothic(
                          fontSize: 19,
                          fontWeight: FontWeight.w600,
                          color: AppColors.ink,
                        ).copyWith(height: 1.65),
                      ),
                    ),
                  ),
                  const SizedBox(height: 22),
                  DialogueAudioControls(turns: turns, player: player),
                  const SizedBox(height: 24),
                  for (var i = 0; i < question.options.length; i++) ...[
                    if (i > 0) const SizedBox(height: 10),
                    _OptionCard(
                      letter: String.fromCharCode(65 + i),
                      text: question.options[i],
                      state: _stateFor(i),
                      onTap: (phase.isAnswered || hiddenOptions.contains(i))
                          ? null
                          : () => onSelect(i),
                    ),
                  ],
                  if (!phase.isAnswered) ...[
                    const SizedBox(height: 8),
                    Center(
                      child: TextButton.icon(
                        onPressed: hintUsed ? null : onHint,
                        icon: const Icon(
                          Icons.lightbulb_outline_rounded,
                          size: 18,
                        ),
                        label: Text(hintUsed ? 'Đã dùng gợi ý' : 'Gợi ý 50:50'),
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  // Script: dựng có điều kiện theo phase — ở giai đoạn nghe
                  // chỉ có placeholder, không có ký tự tiếng Nhật nào của script.
                  if (phase.showScript)
                    DialogueScriptCard(turns: turns, player: player)
                  else if (!phase.isAnswered)
                    const _ScriptPlaceholder(),
                ],
              ),
            ),
          ),
          if (phase.isAnswered)
            _ResultBar(
              timedOut: timedOut,
              isCorrect: isCorrect,
              xpGained: xpGained,
              combo: combo,
              correctLabel: question.options[question.correctIndex],
              correctLetter: String.fromCharCode(65 + question.correctIndex),
              scriptShown: phase.showScript,
              onShowScript: onShowScript,
              onContinue: onContinue,
            ),
        ],
      ),
    );
  }

  _OptionState _stateFor(int i) {
    if (!phase.isAnswered) {
      return hiddenOptions.contains(i)
          ? _OptionState.hidden
          : _OptionState.idle;
    }
    if (i == question.correctIndex) return _OptionState.correct;
    if (i == selectedOption) return _OptionState.wrong;
    return _OptionState.disabled;
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.title,
    required this.index,
    required this.total,
    required this.hearts,
    required this.answered,
    required this.timerController,
    required this.timerSeconds,
    required this.onClose,
    required this.onVoicePicker,
  });

  final String title;
  final int index;
  final int total;
  final int hearts;
  final bool answered;
  final AnimationController timerController;
  final int timerSeconds;
  final VoidCallback onClose;
  final VoidCallback onVoicePicker;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            IconButton(
              onPressed: onClose,
              visualDensity: VisualDensity.compact,
              icon: const Icon(Icons.close_rounded, size: 22),
              color: AppColors.inkSoft,
            ),
            Expanded(
              child: Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: AppColors.ink,
                ),
              ),
            ),
            const Icon(
              Icons.favorite_rounded,
              size: 16,
              color: AppColors.danger,
            ),
            const SizedBox(width: 3),
            Text(
              '$hearts',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: AppColors.danger,
              ),
            ),
            IconButton(
              onPressed: onVoicePicker,
              visualDensity: VisualDensity.compact,
              tooltip: 'Chọn giọng đọc',
              icon: const Icon(Icons.record_voice_over_outlined, size: 20),
              color: AppColors.inkFaint,
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(100),
          child: LinearProgressIndicator(
            value: (index + (answered ? 1 : 0)) / total,
            minHeight: 8,
            backgroundColor: AppColors.border,
            valueColor: const AlwaysStoppedAnimation(AppColors.accent),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Text(
              'Câu ${index + 1} / $total',
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: AppColors.inkSoft,
              ),
            ),
            const Spacer(),
            _TimerChip(controller: timerController, totalSeconds: timerSeconds),
          ],
        ),
      ],
    );
  }
}

/// Đồng hồ đếm ngược của câu, dạng mm:ss gọn (thời gian nghe hội thoại dài
/// hơn 1 phút nên số giây thuần sẽ khó đọc).
class _TimerChip extends StatelessWidget {
  const _TimerChip({required this.controller, required this.totalSeconds});

  final AnimationController controller;
  final int totalSeconds;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final t = controller.value.clamp(0.0, 1.0);
        final left = (t * totalSeconds).ceil();
        final urgent = t < 0.3;
        final color = urgent ? AppColors.danger : AppColors.inkSoft;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
          decoration: BoxDecoration(
            color: urgent ? AppColors.dangerSoft : AppColors.chip,
            borderRadius: BorderRadius.circular(100),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.timer_outlined, size: 14, color: color),
              const SizedBox(width: 3),
              Text(
                '${left ~/ 60}:${(left % 60).toString().padLeft(2, '0')}',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ScriptPlaceholder extends StatelessWidget {
  const _ScriptPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.chip.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: const Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.lock_outline_rounded,
                size: 18,
                color: AppColors.inkSoft,
              ),
              SizedBox(width: 6),
              Text(
                'Script đã ẩn',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: AppColors.inkSoft,
                ),
              ),
            ],
          ),
          SizedBox(height: 4),
          Text(
            'Hãy nghe và chọn đáp án',
            style: TextStyle(fontSize: 12.5, color: AppColors.inkFaint),
          ),
        ],
      ),
    );
  }
}

enum _OptionState { idle, correct, wrong, disabled, hidden }

class _OptionCard extends StatelessWidget {
  const _OptionCard({
    required this.letter,
    required this.text,
    required this.state,
    required this.onTap,
  });

  final String letter;
  final String text;
  final _OptionState state;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final (Color bg, Color border, Color fg, Color badge, Color badgeFg) =
        switch (state) {
      _OptionState.correct => (
          AppColors.mossSoft,
          AppColors.moss,
          AppColors.ink,
          AppColors.moss,
          Colors.white,
        ),
      _OptionState.wrong => (
          AppColors.dangerSoft,
          AppColors.danger,
          AppColors.ink,
          AppColors.danger,
          Colors.white,
        ),
      _ => (
          AppColors.card,
          AppColors.border,
          AppColors.ink,
          AppColors.chip,
          AppColors.inkSoft,
        ),
    };
    final opacity = switch (state) {
      _OptionState.disabled => 0.55,
      _OptionState.hidden => 0.3,
      _ => 1.0,
    };
    return Opacity(
      opacity: opacity,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 58),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: border, width: 1.6),
          ),
          child: Row(
            children: [
              Container(
                width: 30,
                height: 30,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: badge,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Text(
                  letter,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                    color: badgeFg,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  text,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14.5,
                    height: 1.4,
                    color: fg,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Kết quả gọn ở cuối màn (không che nội dung phía trên) — đúng/sai + đáp án
/// đúng nếu cần, và nút Tiếp tục.
class _ResultBar extends StatelessWidget {
  const _ResultBar({
    required this.timedOut,
    required this.isCorrect,
    required this.xpGained,
    required this.combo,
    required this.correctLabel,
    required this.correctLetter,
    required this.scriptShown,
    required this.onShowScript,
    required this.onContinue,
  });

  final bool timedOut;
  final bool isCorrect;
  final int? xpGained;
  final int combo;
  final String correctLabel;
  final String correctLetter;
  final bool scriptShown;
  final VoidCallback onShowScript;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    final ok = isCorrect;
    final color = ok ? AppColors.moss : AppColors.danger;
    final bg = ok ? AppColors.mossSoft : AppColors.dangerSoft;
    final title = ok ? 'Chính xác!' : (timedOut ? 'Hết giờ!' : 'Chưa đúng');
    final detail = ok
        ? [
            if (xpGained != null) '+$xpGained XP',
            if (combo >= 2) 'Combo x$combo',
          ].join(' · ')
        : 'Đáp án đúng: $correctLetter. $correctLabel';
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                child: Icon(
                  ok ? Icons.check_rounded : Icons.close_rounded,
                  size: 20,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: color,
                      ),
                    ),
                    if (detail.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        detail,
                        style: const TextStyle(
                          fontSize: 12.5,
                          height: 1.4,
                          color: AppColors.inkSoft,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              if (!scriptShown) ...[
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onShowScript,
                    icon: const Icon(Icons.article_outlined, size: 18),
                    label: const Text('Scriptを見る'),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(46),
                      foregroundColor: color,
                      side: BorderSide(color: color.withValues(alpha: 0.5)),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
              ],
              Expanded(
                child: FilledButton(
                  onPressed: onContinue,
                  style: FilledButton.styleFrom(
                    backgroundColor: color,
                    minimumSize: const Size.fromHeight(46),
                  ),
                  child: const Text('Tiếp tục'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Bottom sheet "Hết giờ!" — gọn, cuộn được, không che kín màn hình. Không tự
/// hiện Script: chỉ có nút "Xem script" để người học chủ động mở.
Future<void> showListeningTimeoutSheet(
  BuildContext context, {
  required String correctLetter,
  required String correctLabel,
  required VoidCallback onShowScript,
  required VoidCallback onContinue,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.card,
    barrierColor: Colors.black38,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (sheetContext) {
      final maxHeight = MediaQuery.sizeOf(sheetContext).height * 0.6;
      return SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: maxHeight),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 52,
                    height: 52,
                    decoration: const BoxDecoration(
                      color: AppColors.dangerSoft,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close_rounded,
                      size: 28,
                      color: AppColors.danger,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Hết giờ!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppColors.danger,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Câu trả lời đúng là:',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: AppColors.inkSoft),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.mossSoft,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    '$correctLetter. $correctLabel',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      height: 1.45,
                      color: AppColors.ink,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                OutlinedButton(
                  onPressed: () {
                    Navigator.pop(sheetContext);
                    onShowScript();
                  },
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(46),
                    side: const BorderSide(color: AppColors.border),
                  ),
                  child: const Text('Scriptを見る · Xem script'),
                ),
                const SizedBox(height: 8),
                FilledButton(
                  onPressed: () {
                    Navigator.pop(sheetContext);
                    onContinue();
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.danger,
                    minimumSize: const Size.fromHeight(48),
                  ),
                  child: const Text('Tiếp tục'),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}
