import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../domain/entities/kaiwa_message.dart';
import '../../../domain/services/lesson_mission_generator.dart';
import '../../../shared/jp_speak_button.dart';
import '../providers/lesson_mission_providers.dart';

/// Pha Apply (Mission Challenge) — hội thoại AI tự do nhưng có mục tiêu rõ
/// ràng: dùng đúng các từ vựng/mẫu ngữ pháp THẬT của chính bài học vừa xong
/// (xem `generateLessonMission`). Tiến độ cộng dồn từ dữ liệu thô AI trả về
/// mỗi lượt (`used_vocab`/`used_grammar`), không tự "chấm hoàn thành" bằng 1
/// lượt gọi AI tổng kết riêng — người học có thể dừng bất cứ lúc nào, không
/// bị ép phải hoàn thành 100% mới được đi tiếp (đúng tinh thần "Kết thúc hội
/// thoại" đã có ở Kaiwa tự do).
class LessonMissionView extends ConsumerStatefulWidget {
  const LessonMissionView({super.key, required this.mission, required this.onDone});

  final LessonMission mission;
  final VoidCallback onDone;

  @override
  ConsumerState<LessonMissionView> createState() => _LessonMissionViewState();
}

class _LessonMissionViewState extends ConsumerState<LessonMissionView> {
  final _textController = TextEditingController();
  final _scrollController = ScrollController();
  bool _showSummary = false;

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
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

  @override
  Widget build(BuildContext context) {
    final provider = lessonMissionControllerProvider(widget.mission);
    ref.listen(provider, (prev, next) {
      if (prev?.messages.length != next.messages.length) _scrollToBottom();
    });
    final state = ref.watch(provider);
    final notifier = ref.read(provider.notifier);

    if (_showSummary) {
      return _MissionSummaryView(
        mission: widget.mission,
        completedVocabIds: state.completedVocabIds,
        completedGrammarIds: state.completedGrammarIds,
        onContinue: widget.onDone,
      );
    }

    if (!state.started) {
      return _MissionIntroView(
        mission: widget.mission,
        loading: state.sending,
        error: state.error,
        onStart: notifier.start,
      );
    }

    return _MissionChatView(
      mission: widget.mission,
      state: state,
      isComplete: notifier.isComplete,
      textController: _textController,
      scrollController: _scrollController,
      onSend: (text) {
        _textController.clear();
        notifier.send(text);
      },
      onFinish: () => setState(() => _showSummary = true),
    );
  }
}

class _MissionIntroView extends StatelessWidget {
  const _MissionIntroView({
    required this.mission,
    required this.loading,
    required this.error,
    required this.onStart,
  });

  final LessonMission mission;
  final bool loading;
  final String? error;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(color: AppColors.tealSoft, borderRadius: BorderRadius.circular(100)),
                  child: const Text(
                    'Thử thách hội thoại',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.teal),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Trò chuyện với AI về chủ đề "${mission.lessonTitle}"',
                  style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: AppColors.ink),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Cố gắng dùng đúng những từ/mẫu câu dưới đây trong lúc trò chuyện. AI sẽ tự nhận ra khi bạn dùng đúng.',
                  style: TextStyle(fontSize: 13.5, color: AppColors.inkSoft, height: 1.4),
                ),
                const SizedBox(height: 18),
                if (mission.targetVocab.isNotEmpty) ...[
                  const _GoalSectionLabel(text: 'Từ vựng cần dùng'),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final v in mission.targetVocab) _GoalChip(label: '${v.word} · ${v.primaryMeaning}'),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
                if (mission.targetGrammar.isNotEmpty) ...[
                  const _GoalSectionLabel(text: 'Mẫu ngữ pháp cần dùng'),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final g in mission.targetGrammar) _GoalChip(label: g.title),
                    ],
                  ),
                ],
                if (error != null) ...[
                  const SizedBox(height: 16),
                  Text(error!, style: const TextStyle(color: AppColors.danger, fontSize: 13.5)),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: loading ? null : onStart,
            style: FilledButton.styleFrom(backgroundColor: AppColors.teal),
            child: loading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2.2, color: Colors.white),
                  )
                : const Text('Bắt đầu'),
          ),
        ),
      ],
    );
  }
}

class _GoalSectionLabel extends StatelessWidget {
  const _GoalSectionLabel({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(text, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.inkSoft));
  }
}

class _GoalChip extends StatelessWidget {
  const _GoalChip({required this.label, this.done = false});

  final String label;
  final bool done;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: done ? AppColors.teal : AppColors.tealSoft,
        borderRadius: BorderRadius.circular(100),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (done) ...[
            const Icon(Icons.check_rounded, size: 14, color: Colors.white),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: done ? Colors.white : AppColors.teal,
              decoration: done ? TextDecoration.lineThrough : null,
            ),
          ),
        ],
      ),
    );
  }
}

class _MissionChatView extends StatelessWidget {
  const _MissionChatView({
    required this.mission,
    required this.state,
    required this.isComplete,
    required this.textController,
    required this.scrollController,
    required this.onSend,
    required this.onFinish,
  });

  final LessonMission mission;
  final LessonMissionState state;
  final bool isComplete;
  final TextEditingController textController;
  final ScrollController scrollController;
  final void Function(String) onSend;
  final VoidCallback onFinish;

  @override
  Widget build(BuildContext context) {
    final lastAi = state.messages.reversed.where((m) => m.role == KaiwaMessageRole.ai).firstOrNull;

    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          child: Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final v in mission.targetVocab)
                _GoalChip(label: v.word, done: state.completedVocabIds.contains(v.id)),
              for (final g in mission.targetGrammar)
                _GoalChip(label: g.title, done: state.completedGrammarIds.contains(g.id)),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: ListView.builder(
            controller: scrollController,
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: state.messages.length + (state.sending ? 1 : 0),
            itemBuilder: (context, i) {
              if (i >= state.messages.length) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.teal),
                  ),
                );
              }
              return _MessageBubble(message: state.messages[i]);
            },
          ),
        ),
        if (state.error != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(state.error!, style: const TextStyle(color: AppColors.danger, fontSize: 13)),
          ),
        if (lastAi?.suggestedReplyJp != null && (lastAi!.suggestedReplyJp?.isNotEmpty ?? false))
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: ActionChip(
                backgroundColor: AppColors.tealSoft,
                label: Text(
                  '💡 ${lastAi.suggestedReplyJp}',
                  style: const TextStyle(fontSize: 12.5, color: AppColors.teal, fontWeight: FontWeight.w600),
                ),
                onPressed: () => textController.text = lastAi.suggestedReplyJp!,
              ),
            ),
          ),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: textController,
                decoration: const InputDecoration(hintText: 'Nhập câu trả lời bằng tiếng Nhật...'),
                onSubmitted: state.sending ? null : onSend,
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filled(
              onPressed: state.sending ? null : () => onSend(textController.text),
              style: IconButton.styleFrom(backgroundColor: AppColors.teal),
              icon: const Icon(Icons.send_rounded),
            ),
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: isComplete
              ? FilledButton.icon(
                  onPressed: onFinish,
                  style: FilledButton.styleFrom(backgroundColor: AppColors.teal),
                  icon: const Icon(Icons.emoji_events_outlined),
                  label: const Text('Hoàn thành nhiệm vụ'),
                )
              : TextButton(
                  onPressed: onFinish,
                  child: const Text('Kết thúc nhiệm vụ', style: TextStyle(color: AppColors.inkSoft)),
                ),
        ),
      ],
    );
  }
}

extension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message});

  final KaiwaMessage message;

  @override
  Widget build(BuildContext context) {
    final isAi = message.role == KaiwaMessageRole.ai;
    return Align(
      alignment: isAi ? Alignment.centerLeft : Alignment.centerRight,
      child: Column(
        crossAxisAlignment: isAi ? CrossAxisAlignment.start : CrossAxisAlignment.end,
        children: [
          Container(
            constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
            margin: const EdgeInsets.symmetric(vertical: 4),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isAi ? AppColors.tealSoft : AppColors.card,
              borderRadius: BorderRadius.circular(16),
              border: isAi ? null : Border.all(color: AppColors.border),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Flexible(
                  child: Text(
                    message.contentJp,
                    style: AppFonts.zenMaruGothic(fontSize: 15, color: AppColors.ink),
                  ),
                ),
                if (isAi) ...[
                  const SizedBox(width: 4),
                  JpSpeakButton(text: message.contentJp, color: AppColors.teal, size: 18),
                ],
              ],
            ),
          ),
          if (isAi && message.translationVi != null)
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 4),
              child: Text(
                message.translationVi!,
                style: const TextStyle(fontSize: 12, color: AppColors.inkSoft),
              ),
            ),
          if (!isAi && (message.feedback?.hasContent ?? false)) _FeedbackStrip(feedback: message.feedback!),
        ],
      ),
    );
  }
}

class _FeedbackStrip extends StatelessWidget {
  const _FeedbackStrip({required this.feedback});

  final KaiwaFeedback feedback;

  @override
  Widget build(BuildContext context) {
    final good = feedback.rating >= 4;
    final hasNote = feedback.betterPhrasing.trim().isNotEmpty || feedback.explanation.trim().isNotEmpty;
    if (!hasNote) return const SizedBox.shrink();

    return Container(
      constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: good ? AppColors.mossSoft : AppColors.accentSoft,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (feedback.betterPhrasing.trim().isNotEmpty)
            Text(
              'Tự nhiên hơn: ${feedback.betterPhrasing}',
              style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.ink),
            ),
          if (feedback.explanation.trim().isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                feedback.explanation,
                style: const TextStyle(fontSize: 12, color: AppColors.inkSoft, height: 1.3),
              ),
            ),
        ],
      ),
    );
  }
}

class _MissionSummaryView extends StatelessWidget {
  const _MissionSummaryView({
    required this.mission,
    required this.completedVocabIds,
    required this.completedGrammarIds,
    required this.onContinue,
  });

  final LessonMission mission;
  final Set<String> completedVocabIds;
  final Set<String> completedGrammarIds;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    final doneCount = completedVocabIds.length + completedGrammarIds.length;
    final total = mission.totalTargets;
    final allDone = total > 0 && doneCount == total;

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 24),
                Text(allDone ? '🎉' : '👍', style: const TextStyle(fontSize: 48)),
                const SizedBox(height: 12),
                Text(
                  allDone ? 'Hoàn thành xuất sắc!' : 'Đã kết thúc nhiệm vụ',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.ink),
                ),
                const SizedBox(height: 6),
                Text(
                  'Bạn đã dùng đúng $doneCount/$total mục tiêu trong hội thoại.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 13.5, color: AppColors.inkSoft),
                ),
                const SizedBox(height: 20),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            for (final v in mission.targetVocab)
                              _GoalChip(label: v.word, done: completedVocabIds.contains(v.id)),
                            for (final g in mission.targetGrammar)
                              _GoalChip(label: g.title, done: completedGrammarIds.contains(g.id)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: FilledButton(onPressed: onContinue, child: const Text('Tiếp tục')),
        ),
      ],
    );
  }
}
