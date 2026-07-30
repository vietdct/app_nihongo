import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../domain/entities/kaiwa_scenario.dart';
import '../../domain/services/kaiwa_streak.dart';
import 'providers/kaiwa_content_providers.dart';
import 'providers/kaiwa_conversation_providers.dart';
import 'providers/kaiwa_stats_providers.dart';

/// Thống kê AI Kaiwa — số liệu thật tính từ `kaiwa_conversations`/
/// `kaiwa_messages` của người dùng, không có XP/điểm phát âm giả (giống
/// `KanjiStatisticsScreen`). [KaiwaMessageStats.averageRating] hiện "—" khi
/// chưa có câu nào được AI chấm, không giả định 0.
class KaiwaStatisticsScreen extends ConsumerWidget {
  const KaiwaStatisticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final conversationsAsync = ref.watch(kaiwaConversationsProvider);
    final scenariosAsync = ref.watch(kaiwaScenariosProvider);
    final statsAsync = ref.watch(kaiwaMessageStatsProvider);

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(title: const Text('Thống kê Kaiwa')),
      body: conversationsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Lỗi: $e')),
        data: (conversations) {
          if (conversations.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Chưa có buổi hội thoại nào — bắt đầu trò chuyện với AI Kaiwa để tích lũy số liệu nhé.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.inkSoft),
                ),
              ),
            );
          }

          final streak = computeKaiwaStreak(
            [for (final c in conversations) c.lastMessageAt],
          );
          final stats = statsAsync.valueOrNull;
          final scenarios = scenariosAsync.valueOrNull;

          final categoryCounts = <String, int>{};
          if (scenarios != null) {
            for (final c in conversations) {
              final scenario = _findScenario(scenarios, c.scenarioId);
              if (scenario == null) continue;
              categoryCounts[scenario.category] =
                  (categoryCounts[scenario.category] ?? 0) + 1;
            }
          }
          final sortedCategories = categoryCounts.entries.toList()
            ..sort((a, b) => b.value.compareTo(a.value));

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
            children: [
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.5,
                children: [
                  _StatCard(
                    label: 'Buổi hội thoại',
                    value: '${conversations.length}',
                    sub: 'buổi',
                    color: AppColors.teal,
                  ),
                  _StatCard(
                    label: 'Chuỗi ngày luyện',
                    value: '$streak',
                    sub: 'ngày',
                    color: AppColors.accent,
                  ),
                  _StatCard(
                    label: 'Điểm AI chấm TB',
                    value: stats == null || stats.averageRating == null
                        ? '—'
                        : stats.averageRating!.toStringAsFixed(1),
                    sub: '/5 sao',
                    color: AppColors.moss,
                  ),
                  _StatCard(
                    label: 'Câu đã ôn lại',
                    value:
                        '${stats?.reviewedCount ?? 0}/${stats?.correctedCount ?? 0}',
                    sub: 'câu sửa',
                    color: AppColors.indigo,
                  ),
                ],
              ),
              if (sortedCategories.isNotEmpty) ...[
                const SizedBox(height: 24),
                const _SectionLabel('Chủ đề đã luyện'),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    children: [
                      for (var i = 0; i < sortedCategories.length; i++) ...[
                        if (i > 0) const SizedBox(height: 12),
                        _CategoryBar(
                          label: sortedCategories[i].key,
                          count: sortedCategories[i].value,
                          total: conversations.length,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

KaiwaScenario? _findScenario(List<KaiwaScenario> scenarios, String id) {
  for (final s in scenarios) {
    if (s.id == id) return s;
  }
  return null;
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

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.sub,
    required this.color,
  });

  final String label;
  final String value;
  final String sub;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label, style: const TextStyle(fontSize: 11.5, color: AppColors.inkSoft)),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: color),
              ),
              const SizedBox(width: 4),
              Text(sub, style: const TextStyle(fontSize: 11, color: AppColors.inkFaint)),
            ],
          ),
        ],
      ),
    );
  }
}

class _CategoryBar extends StatelessWidget {
  const _CategoryBar({required this.label, required this.count, required this.total});

  final String label;
  final int count;
  final int total;

  @override
  Widget build(BuildContext context) {
    final ratio = total == 0 ? 0.0 : count / total;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontSize: 12.5, color: AppColors.ink)),
            Text(
              '$count',
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12.5, color: AppColors.teal),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(100),
          child: LinearProgressIndicator(
            value: ratio,
            minHeight: 7,
            backgroundColor: AppColors.chip,
            valueColor: const AlwaysStoppedAnimation(AppColors.teal),
          ),
        ),
      ],
    );
  }
}
