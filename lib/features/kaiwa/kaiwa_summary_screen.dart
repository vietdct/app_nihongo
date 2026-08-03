import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../domain/entities/kaiwa_conversation.dart';
import '../../domain/entities/kaiwa_message.dart';
import '../../domain/entities/kaiwa_persona.dart';
import '../../domain/entities/kaiwa_scenario.dart';
import 'providers/kaiwa_chat_service.dart';
import 'providers/kaiwa_conversation_providers.dart';

/// Tóm tắt hội thoại — hiện sau khi bấm "Kết thúc hội thoại" ở
/// `KaiwaChatScreen`. Mọi số liệu tính thẳng từ `kaiwa_messages`/
/// `kaiwa_conversations` thật của đúng hội thoại này (không có XP, "từ đã
/// học", hay điểm phát âm giả — những thứ app chưa có pipeline chấm thật).
class KaiwaSummaryScreen extends ConsumerWidget {
  const KaiwaSummaryScreen({
    super.key,
    required this.conversationId,
    required this.persona,
    required this.scenario,
  });

  final String conversationId;
  final KaiwaPersona persona;
  final KaiwaScenario scenario;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final messagesAsync = ref.watch(kaiwaMessagesProvider(conversationId));
    final conversations = ref.watch(kaiwaConversationsProvider).valueOrNull;
    KaiwaConversation? conversation;
    if (conversations != null) {
      for (final c in conversations) {
        if (c.id == conversationId) {
          conversation = c;
          break;
        }
      }
    }

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(title: const Text('Tóm tắt hội thoại')),
      body: messagesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Lỗi tải hội thoại: $e')),
        data: (messages) {
          final userMessages =
              messages.where((m) => m.role == KaiwaMessageRole.user).toList();
          final feedbacks = [
            for (final m in userMessages)
              if (m.feedback != null && m.feedback!.hasContent) m.feedback!,
          ];
          final avgRating = feedbacks.isEmpty
              ? null
              : feedbacks.map((f) => f.rating).reduce((a, b) => a + b) /
                  feedbacks.length;
          final corrections = [
            for (final m in userMessages)
              if (m.feedback != null &&
                  m.feedback!.hasContent &&
                  m.feedback!.betterPhrasing.trim().isNotEmpty &&
                  m.feedback!.betterPhrasing.trim() != m.contentJp.trim())
                m,
          ];
          final conv = conversation;
          final duration = conv?.lastMessageAt.difference(conv.startedAt);

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
            children: [
              Center(
                child: Column(
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: const BoxDecoration(
                        color: AppColors.tealSoft,
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.forum_rounded,
                        color: AppColors.teal,
                        size: 30,
                      ),
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'Hoàn thành hội thoại!',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${persona.name} · ${scenario.title}',
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.inkSoft,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      icon: Icons.timer_outlined,
                      label: 'Thời gian',
                      value: _formatDuration(duration),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _StatCard(
                      icon: Icons.chat_bubble_outline_rounded,
                      label: 'Lượt bạn nói',
                      value: '${userMessages.length}',
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _StatCard(
                      icon: Icons.star_outline_rounded,
                      label: 'Điểm tự nhiên',
                      value: avgRating == null
                          ? '—'
                          : '${avgRating.toStringAsFixed(1)}/5',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),
              if (userMessages.isEmpty)
                const _EmptyNote(
                  text:
                      'Bạn chưa nói câu nào trong buổi này — thử lại lần sau nhé!',
                )
              else if (corrections.isEmpty)
                const _EmptyNote(
                  text:
                      'Không có câu nào cần sửa trong buổi này — làm tốt lắm!',
                )
              else ...[
                const _SectionLabel('Câu nên ôn lại'),
                const SizedBox(height: 10),
                for (final m in corrections) ...[
                  _CorrectionCard(message: m),
                  const SizedBox(height: 8),
                ],
              ],
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.teal,
                    minimumSize: const Size.fromHeight(52),
                  ),
                  onPressed: () =>
                      Navigator.of(context).popUntil((route) => route.isFirst),
                  child: const Text('Về trang chủ Kaiwa'),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

String _formatDuration(Duration? duration) {
  if (duration == null) return '—';
  if (duration.inMinutes < 1) return '<1 phút';
  if (duration.inMinutes < 60) return '${duration.inMinutes} phút';
  final hours = duration.inHours;
  final minutes = duration.inMinutes % 60;
  return '${hours}h${minutes.toString().padLeft(2, '0')}';
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 1.0),
      ),
      child: Column(
        children: [
          Icon(icon, size: 18, color: AppColors.teal),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 10.5,
              color: AppColors.inkSoft,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _CorrectionCard extends StatelessWidget {
  const _CorrectionCard({required this.message});

  final KaiwaMessage message;

  @override
  Widget build(BuildContext context) {
    final feedback = message.feedback!;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            message.contentJp,
            style:
                AppFonts.zenMaruGothic(fontSize: 14, color: AppColors.inkFaint)
                    .copyWith(
              decoration: TextDecoration.lineThrough,
              decorationColor: AppColors.inkFaint,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            feedback.betterPhrasing.trim(),
            style: AppFonts.zenMaruGothic(
              fontSize: 15,
              color: AppColors.moss,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (feedback.explanation.trim().isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              feedback.explanation.trim(),
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.inkSoft,
                height: 1.4,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _EmptyNote extends StatelessWidget {
  const _EmptyNote({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.tealSoft,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 13,
          color: AppColors.ink,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: AppColors.inkFaint,
        letterSpacing: 0.6,
      ),
    );
  }
}
