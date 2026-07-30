import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../../domain/entities/kaiwa_conversation.dart';
import '../../domain/entities/kaiwa_persona.dart';
import '../../domain/entities/kaiwa_scenario.dart';
import 'kaiwa_chat_screen.dart';
import 'providers/kaiwa_content_providers.dart';
import 'providers/kaiwa_conversation_providers.dart';

/// Toàn bộ lịch sử hội thoại thật của người dùng (Dashboard chỉ hiện 3 buổi
/// gần nhất) — chạm vào 1 dòng để mở lại đúng hội thoại đó, dùng chung cơ
/// chế resume với thẻ "Tiếp tục hội thoại" ở Dashboard.
class KaiwaHistoryScreen extends ConsumerWidget {
  const KaiwaHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final conversationsAsync = ref.watch(kaiwaConversationsProvider);
    final personasAsync = ref.watch(kaiwaPersonasProvider);
    final scenariosAsync = ref.watch(kaiwaScenariosProvider);

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(title: const Text('Lịch sử hội thoại')),
      body: conversationsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Lỗi tải lịch sử: $e')),
        data: (conversations) {
          if (conversations.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Chưa có hội thoại nào.', style: TextStyle(color: AppColors.inkSoft, fontSize: 13.5)),
                    const SizedBox(height: 14),
                    FilledButton(
                      style: FilledButton.styleFrom(backgroundColor: AppColors.teal),
                      onPressed: () => context.push('/kaiwa/topics'),
                      child: const Text('Bắt đầu hội thoại đầu tiên'),
                    ),
                  ],
                ),
              ),
            );
          }

          final personas = personasAsync.valueOrNull;
          final scenarios = scenariosAsync.valueOrNull;
          final sorted = [...conversations]..sort((a, b) => b.lastMessageAt.compareTo(a.lastMessageAt));

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            itemCount: sorted.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, i) {
              final conv = sorted[i];
              final persona = personas == null ? null : _findById(personas, conv.personaId, (p) => p.id);
              final scenario = scenarios == null ? null : _findById(scenarios, conv.scenarioId, (s) => s.id);
              if (persona == null || scenario == null) return const SizedBox.shrink();
              return _HistoryTile(
                conversation: conv,
                persona: persona,
                scenario: scenario,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => KaiwaChatScreen(
                      persona: persona,
                      scenario: scenario,
                      resumeConversationId: conv.id,
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

T? _findById<T>(List<T> items, String id, String Function(T) idOf) {
  for (final item in items) {
    if (idOf(item) == id) return item;
  }
  return null;
}

class _HistoryTile extends StatelessWidget {
  const _HistoryTile({required this.conversation, required this.persona, required this.scenario, required this.onTap});

  final KaiwaConversation conversation;
  final KaiwaPersona persona;
  final KaiwaScenario scenario;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border, width: 0.8),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: AppColors.tealSoft,
              child: Text(persona.glyph, style: AppFonts.zenMaruGothic(fontSize: 15, color: AppColors.teal)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${scenario.title} · ${persona.name}', style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: AppColors.ink)),
                  const SizedBox(height: 2),
                  Text(_relativeTime(conversation.lastMessageAt), style: const TextStyle(fontSize: 11.5, color: AppColors.inkSoft)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: AppColors.inkFaint),
          ],
        ),
      ),
    );
  }
}

String _relativeTime(DateTime dt) {
  final diff = DateTime.now().difference(dt);
  if (diff.inMinutes < 60) return '${diff.inMinutes < 1 ? 1 : diff.inMinutes} phút trước';
  if (diff.inHours < 24) return '${diff.inHours} giờ trước';
  return '${diff.inDays} ngày trước';
}
