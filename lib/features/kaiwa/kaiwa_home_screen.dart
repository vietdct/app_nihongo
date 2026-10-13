import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../../domain/entities/kaiwa_conversation.dart';
import '../../domain/entities/kaiwa_persona.dart';
import '../../domain/entities/kaiwa_scenario.dart';
import '../../domain/services/kaiwa_streak.dart';
import '../home/providers/profile_providers.dart';
import '../lesson/providers/level_providers.dart';
import 'kaiwa_chat_screen.dart';
import 'providers/kaiwa_content_providers.dart';
import 'providers/kaiwa_conversation_providers.dart';
import 'providers/kaiwa_review_providers.dart';

const _levelRank = {'N5': 0, 'N4': 1, 'N3': 2, 'N2': 3, 'N1': 4};

/// AI Kaiwa Dashboard — thay cho màn chọn persona+scenario gộp chung cũ.
/// Mọi số liệu trên màn này lấy thật từ `kaiwa_conversations`/`kaiwa_messages`
/// của người dùng (không có XP/điểm phát âm giả — Đợt sau mới thêm khi có
/// pipeline chấm điểm thật). Bắt đầu hội thoại mới giờ đi qua Scenario Map
/// (`/kaiwa/topics`) → Role Play (`/kaiwa/topics/:id/roleplay`) thay vì chọn
/// nhân vật + tình huống trên cùng 1 màn.
class KaiwaHomeScreen extends ConsumerWidget {
  const KaiwaHomeScreen({super.key});

  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour < 11) return 'Chào buổi sáng';
    if (hour < 14) return 'Chào buổi trưa';
    if (hour < 18) return 'Chào buổi chiều';
    return 'Chào buổi tối';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider).valueOrNull;
    final conversationsAsync = ref.watch(kaiwaConversationsProvider);
    final personasAsync = ref.watch(kaiwaPersonasProvider);
    final scenariosAsync = ref.watch(kaiwaScenariosProvider);
    final selectedLevel = ref.watch(selectedLevelCodeProvider);
    final reviewDueCount = ref.watch(kaiwaReviewQueueProvider).valueOrNull?.length ?? 0;

    final conversations = conversationsAsync.valueOrNull ?? const <KaiwaConversation>[];
    final personas = personasAsync.valueOrNull;
    final scenarios = scenariosAsync.valueOrNull;

    final streak = computeKaiwaStreak([for (final c in conversations) c.lastMessageAt]);
    final sorted = [...conversations]..sort((a, b) => b.lastMessageAt.compareTo(a.lastMessageAt));
    final latest = sorted.isEmpty ? null : sorted.first;
    final recent = sorted.length > 3 ? sorted.sublist(0, 3) : sorted;

    List<KaiwaScenario> recommended = const [];
    if (scenarios != null) {
      final triedScenarioIds = conversations.map((c) => c.scenarioId).toSet();
      final selectedRank = _levelRank[selectedLevel] ?? 0;
      final eligible = scenarios
          .where((s) => (_levelRank[s.levelMin] ?? 0) <= selectedRank)
          .toList()
        ..sort((a, b) => a.orderIndex.compareTo(b.orderIndex));
      final untried = eligible.where((s) => !triedScenarioIds.contains(s.id)).toList();
      recommended = (untried.isNotEmpty ? untried : eligible).take(3).toList();
    }

    void openResumed(KaiwaConversation conv) {
      if (personas == null || scenarios == null) return;
      final persona = _findPersona(personas, conv.personaId);
      final scenario = _findScenario(scenarios, conv.scenarioId);
      if (persona == null || scenario == null) return;
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => KaiwaChatScreen(
            persona: persona,
            scenario: scenario,
            resumeConversationId: conv.id,
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          _KaiwaHero(
            greeting: _greeting,
            displayName: profile?.displayName,
            streak: streak,
            totalConversations: conversations.length,
            onStart: () => context.push('/kaiwa/topics'),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: () => context.push('/kaiwa/shadowing'),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.border, width: 0.8),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(color: AppColors.accentSoft, borderRadius: BorderRadius.circular(13)),
                      alignment: Alignment.center,
                      child: const Icon(Icons.mic_rounded, color: AppColors.accent, size: 22),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Luyện phát âm (Shadowing)', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: AppColors.ink)),
                          SizedBox(height: 2),
                          Text('Nghe câu mẫu · lặp lại · chấm độ khớp', style: TextStyle(fontSize: 11.5, color: AppColors.inkSoft)),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right_rounded, color: AppColors.inkFaint),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            child: InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: () => context.push('/kaiwa/statistics'),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.border, width: 0.8),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(color: AppColors.tealSoft, borderRadius: BorderRadius.circular(13)),
                      alignment: Alignment.center,
                      child: const Icon(Icons.bar_chart_rounded, color: AppColors.teal, size: 22),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Thống kê luyện nói', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: AppColors.ink)),
                          SizedBox(height: 2),
                          Text('Điểm AI chấm · chuỗi ngày · chủ đề đã luyện', style: TextStyle(fontSize: 11.5, color: AppColors.inkSoft)),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right_rounded, color: AppColors.inkFaint),
                  ],
                ),
              ),
            ),
          ),
          if (reviewDueCount > 0)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: _ReviewReminderCard(dueCount: reviewDueCount),
            ),
          if (latest != null && personas != null && scenarios != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _SectionLabel('Tiếp tục hội thoại'),
                  const SizedBox(height: 10),
                  _ContinueCard(
                    conversation: latest,
                    persona: _findPersona(personas, latest.personaId),
                    scenario: _findScenario(scenarios, latest.scenarioId),
                    onTap: () => openResumed(latest),
                  ),
                ],
              ),
            ),
          if (recommended.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _SectionLabel('Gợi ý chủ đề'),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 96,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: recommended.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 10),
                      itemBuilder: (context, i) {
                        final s = recommended[i];
                        return _RecommendedTile(
                          scenario: s,
                          onTap: () => context.push('/kaiwa/topics/${s.id}/roleplay'),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          if (recent.isNotEmpty && personas != null && scenarios != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const _SectionLabel('Hội thoại gần đây'),
                      if (conversations.length > recent.length)
                        InkWell(
                          onTap: () => context.push('/kaiwa/history'),
                          child: const Text(
                            'Xem tất cả',
                            style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: AppColors.teal),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  for (final c in recent) ...[
                    _RecentConversationTile(
                      conversation: c,
                      persona: _findPersona(personas, c.personaId),
                      scenario: _findScenario(scenarios, c.scenarioId),
                      onTap: () => openResumed(c),
                    ),
                    const SizedBox(height: 8),
                  ],
                ],
              ),
            ),
          if (conversations.isEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: AppColors.tealSoft, borderRadius: BorderRadius.circular(18)),
                child: const Row(
                  children: [
                    Text('話', style: TextStyle(fontFamily: 'ZenMaruGothic', fontSize: 30, color: AppColors.teal, fontWeight: FontWeight.w700)),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Chọn một tình huống và nhân vật, AI sẽ nói chuyện hoàn toàn bằng tiếng Nhật và chấm câu của bạn sau mỗi lượt.',
                        style: TextStyle(fontSize: 13, color: AppColors.ink, fontWeight: FontWeight.w600, height: 1.4),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 28),
        ],
      ),
    );
  }
}

KaiwaPersona? _findPersona(List<KaiwaPersona> personas, String id) {
  for (final p in personas) {
    if (p.id == id) return p;
  }
  return null;
}

KaiwaScenario? _findScenario(List<KaiwaScenario> scenarios, String id) {
  for (final s in scenarios) {
    if (s.id == id) return s;
  }
  return null;
}

class _KaiwaHero extends StatelessWidget {
  const _KaiwaHero({
    required this.greeting,
    required this.displayName,
    required this.streak,
    required this.totalConversations,
    required this.onStart,
  });

  final String greeting;
  final String? displayName;
  final int streak;
  final int totalConversations;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.teal, Color(0xFF0C8478)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // canPop chỉ true khi màn này bị push từ nơi khác (VD từ tab
              // Ôn tập) — khi là gốc của tab Kaiwa trong MainTabShell thì
              // không có route nào để quay lại, không hiện nút back.
              if (Navigator.canPop(context))
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(100),
                    onTap: () => Navigator.of(context).pop(),
                    child: const Padding(
                      padding: EdgeInsets.all(4),
                      child: Icon(Icons.arrow_back_rounded, color: Colors.white, size: 20),
                    ),
                  ),
                ),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(greeting, style: const TextStyle(fontSize: 10.5, color: Colors.white70, fontWeight: FontWeight.w600)),
                        Text(
                          displayName == null ? 'AI Kaiwa' : '$displayName, luyện nói thôi!',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                  if (streak > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.22), borderRadius: BorderRadius.circular(100)),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.local_fire_department_rounded, size: 14, color: Colors.white),
                          const SizedBox(width: 4),
                          Text('$streak ngày', style: const TextStyle(fontWeight: FontWeight.w800, color: Colors.white, fontSize: 12)),
                        ],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                totalConversations == 0
                    ? 'Bắt đầu buổi hội thoại đầu tiên của bạn'
                    : 'Bạn đã có $totalConversations buổi hội thoại',
                style: const TextStyle(fontSize: 12.5, color: Colors.white70, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.card,
                    foregroundColor: AppColors.teal,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: onStart,
                  icon: const Icon(Icons.mic_rounded),
                  label: const Text('Bắt đầu hội thoại', style: TextStyle(fontWeight: FontWeight.w800)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ContinueCard extends StatelessWidget {
  const _ContinueCard({required this.conversation, required this.persona, required this.scenario, required this.onTap});

  final KaiwaConversation conversation;
  final KaiwaPersona? persona;
  final KaiwaScenario? scenario;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    if (persona == null || scenario == null) return const SizedBox.shrink();
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.border, width: 1.0),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: AppColors.tealSoft,
              child: Text(persona!.glyph, style: AppFonts.zenMaruGothic(fontSize: 17, color: AppColors.teal)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${persona!.name} · ${scenario!.title}', style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: AppColors.ink)),
                  const SizedBox(height: 2),
                  Text(_relativeTime(conversation.lastMessageAt), style: const TextStyle(fontSize: 11.5, color: AppColors.inkSoft)),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(color: AppColors.tealSoft, borderRadius: BorderRadius.circular(100)),
              child: const Text('Tiếp tục', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.teal)),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecommendedTile extends StatelessWidget {
  const _RecommendedTile({required this.scenario, required this.onTap});

  final KaiwaScenario scenario;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        width: 132,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border, width: 0.8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(color: AppColors.tealSoft, borderRadius: BorderRadius.circular(10)),
              alignment: Alignment.center,
              child: Text(scenario.glyph, style: AppFonts.zenMaruGothic(fontSize: 14, color: AppColors.teal)),
            ),
            const SizedBox(height: 8),
            Text(
              scenario.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.ink, height: 1.2),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecentConversationTile extends StatelessWidget {
  const _RecentConversationTile({required this.conversation, required this.persona, required this.scenario, required this.onTap});

  final KaiwaConversation conversation;
  final KaiwaPersona? persona;
  final KaiwaScenario? scenario;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    if (persona == null || scenario == null) return const SizedBox.shrink();
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border, width: 0.8),
        ),
        child: Row(
          children: [
            Text(persona!.glyph, style: AppFonts.zenMaruGothic(fontSize: 15, color: AppColors.inkSoft)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                '${scenario!.title} · ${persona!.name}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppColors.ink),
              ),
            ),
            Text(_relativeTime(conversation.lastMessageAt), style: const TextStyle(fontSize: 11, color: AppColors.inkFaint)),
          ],
        ),
      ),
    );
  }
}

class _ReviewReminderCard extends StatelessWidget {
  const _ReviewReminderCard({required this.dueCount});

  final int dueCount;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () => context.push('/kaiwa/review'),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.dangerSoft,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          children: [
            const Icon(Icons.refresh_rounded, color: AppColors.danger, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                '$dueCount câu cần ôn lại — ôn ngay',
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.danger),
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: AppColors.danger, size: 20),
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

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.inkFaint, letterSpacing: 0.6),
    );
  }
}
