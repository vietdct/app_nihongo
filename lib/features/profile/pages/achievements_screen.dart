import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../domain/entities/treasure_box.dart';
import '../../home/providers/profile_providers.dart';
import '../../kaiwa/providers/kaiwa_conversation_providers.dart';
import '../../kanji/providers/kanji_progress_providers.dart';
import '../../vocabulary/providers/vocab_progress_providers.dart';
import '../providers/study_heatmap_providers.dart';
import '../providers/treasure_box_providers.dart';
import '../widgets/achievement_badge.dart';
import '../widgets/profile_section_label.dart';
import '../widgets/profile_stat_tile.dart';
import '../widgets/study_heatmap.dart';

/// Nhóm "Thành tích" — XP, Coin, chuỗi ngày học, huy hiệu, rương phần
/// thưởng dựa trên mốc dữ liệu thật đã có. Giải đấu (League) — hạng mục
/// gamification treo còn lại (docs/REVIEW_DESIGN.md §11, §16 câu hỏi #4) —
/// đã bị bỏ theo quyết định người dùng 2026-08-07, không còn giữ chỗ UI.
class AchievementsScreen extends ConsumerWidget {
  const AchievementsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider).valueOrNull;
    final vocabProgress =
        ref.watch(vocabProgressProvider).valueOrNull ?? const {};
    final kanjiProgress =
        ref.watch(kanjiProgressProvider).valueOrNull ?? const {};
    final kaiwaConversations =
        ref.watch(kaiwaConversationsProvider).valueOrNull ?? const [];
    final studyDays = ref.watch(studyDaysProvider).valueOrNull;
    final treasureBoxes = ref.watch(treasureBoxesProvider).valueOrNull ?? const [];
    final pendingBoxes = treasureBoxes.where((b) => !b.isOpened).toList();

    final streak = profile?.streakCount ?? 0;
    final longestStreak = profile?.longestStreakCount ?? 0;
    final xp = profile?.xp ?? 0;
    final coins = profile?.coins ?? 0;
    final knownVocab =
        vocabProgress.values.where((p) => p.isKnown == true).length;
    final knownKanji =
        kanjiProgress.values.where((p) => p.isKnown == true).length;

    final achievements = [
      (
        // Dùng longestStreak (mốc cao nhất từng đạt), không phải streak hiện
        // tại — huy hiệu đã đạt phải là vĩnh viễn, không biến mất khi streak
        // bị reset.
        earned: longestStreak >= 7,
        icon: Icons.local_fire_department_rounded,
        label: '7 ngày',
        sub: 'Chuỗi học',
      ),
      (
        earned: longestStreak >= 30,
        icon: Icons.emoji_events_rounded,
        label: '30 ngày',
        sub: 'Chuỗi học',
      ),
      (
        earned: knownVocab >= 50,
        icon: Icons.style_rounded,
        label: '50 từ',
        sub: 'Từ vựng',
      ),
      (
        earned: knownVocab >= 200,
        icon: Icons.style_rounded,
        label: '200 từ',
        sub: 'Từ vựng',
      ),
      (
        earned: knownKanji >= 10,
        icon: Icons.brush_rounded,
        label: '10 Kanji',
        sub: 'Kanji',
      ),
      (
        earned: knownKanji >= 50,
        icon: Icons.brush_rounded,
        label: '50 Kanji',
        sub: 'Kanji',
      ),
      (
        earned: kaiwaConversations.isNotEmpty,
        icon: Icons.forum_rounded,
        label: 'Kaiwa đầu',
        sub: 'Hội thoại',
      ),
      (
        earned: xp >= 500,
        icon: Icons.bolt_rounded,
        label: '500 XP',
        sub: 'Kinh nghiệm',
      ),
    ];
    final earnedCount = achievements.where((a) => a.earned).length;

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        backgroundColor: AppColors.canvas,
        title: const Text('Thành tích'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        children: [
          Row(
            children: [
              ProfileStatTile(
                value: '$xp',
                label: 'XP',
                color: AppColors.plum,
              ),
              const SizedBox(width: 8),
              ProfileStatTile(
                value: '$coins',
                label: 'Coins',
                color: Colors.amber.shade800,
              ),
              const SizedBox(width: 8),
              ProfileStatTile(
                value: '$streak',
                label: 'Chuỗi hiện tại',
                color: AppColors.accent,
              ),
              const SizedBox(width: 8),
              ProfileStatTile(
                value: '$longestStreak',
                label: 'Chuỗi dài nhất',
                color: AppColors.moss,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              ProfileStatTile(
                value: '$earnedCount/${achievements.length}',
                label: 'Huy hiệu đã mở',
                color: AppColors.indigo,
              ),
            ],
          ),
          const SizedBox(height: 22),
          const ProfileSectionLabel('Lịch học'),
          const SizedBox(height: 12),
          if (studyDays != null) StudyHeatmap(studyDays: studyDays),
          const SizedBox(height: 22),
          const ProfileSectionLabel('Huy hiệu'),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 4,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 4,
            childAspectRatio: 0.8,
            children: [
              for (final a in achievements)
                AchievementBadge(
                  earned: a.earned,
                  icon: a.icon,
                  label: a.label,
                  sub: a.sub,
                ),
            ],
          ),
          const SizedBox(height: 22),
          const ProfileSectionLabel('Rương phần thưởng'),
          const SizedBox(height: 10),
          if (pendingBoxes.isEmpty)
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border, width: 1.0),
              ),
              child: const Text(
                'Đạt chuỗi 3 ngày học liên tiếp để mở rương đầu tiên.',
                style: TextStyle(fontSize: 12.5, color: AppColors.inkSoft),
              ),
            )
          else
            Column(
              children: [
                for (final box in pendingBoxes) ...[
                  _TreasureBoxRow(box: box),
                  const SizedBox(height: 8),
                ],
              ],
            ),
        ],
      ),
    );
  }
}

class _TreasureBoxRow extends ConsumerWidget {
  const _TreasureBoxRow({required this.box});

  final TreasureBox box;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border, width: 1.0),
      ),
      child: Row(
        children: [
          const Text('🎁', style: TextStyle(fontSize: 20)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Rương mốc ${box.milestone} ngày',
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 12.5,
                color: AppColors.ink,
              ),
            ),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.accent,
              minimumSize: const Size(0, 34),
              padding: const EdgeInsets.symmetric(horizontal: 14),
            ),
            onPressed: () => _openBox(context, ref),
            child: const Text('Mở rương', style: TextStyle(fontSize: 12.5)),
          ),
        ],
      ),
    );
  }

  Future<void> _openBox(BuildContext context, WidgetRef ref) async {
    final service = ref.read(treasureBoxServiceProvider);
    if (service == null) return;
    try {
      final reward = await service.open(box.id);
      ref.invalidate(treasureBoxesProvider);
      ref.invalidate(profileProvider);
      if (!context.mounted) return;
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('🎉 Mở rương thành công!'),
          content: Text('Bạn nhận được +$reward Coins.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không mở được rương, vui lòng thử lại.')),
      );
    }
  }
}
