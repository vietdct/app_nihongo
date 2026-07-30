import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/network/supabase_providers.dart';
import '../../core/theme/app_theme.dart';
import '../auth/auth_controller.dart';
import '../grammar/providers/grammar_progress_providers.dart';
import '../home/providers/profile_providers.dart';
import '../kaiwa/providers/kaiwa_conversation_providers.dart';
import '../kanji/providers/kanji_progress_providers.dart';
import '../vocabulary/providers/vocab_progress_providers.dart';
import 'providers/jlpt_progress_providers.dart';

/// Tab "Hồ sơ" — theo mockup "Nihongo App Redesign" nhưng chỉ hiển thị số
/// liệu tính được thật từ dữ liệu đã có. Mockup gốc có thêm lịch học dạng
/// heatmap và biểu đồ thời gian học theo tuần — app chưa track lịch sử theo
/// ngày/thời lượng học nên 2 phần đó KHÔNG được vẽ (bịa số liệu sẽ vi phạm
/// nguyên tắc "honest data" áp dụng xuyên suốt app).
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final profile = ref.watch(profileProvider).valueOrNull;
    final vocabProgress =
        ref.watch(vocabProgressProvider).valueOrNull ?? const {};
    final kanjiProgress =
        ref.watch(kanjiProgressProvider).valueOrNull ?? const {};
    final grammarProgress =
        ref.watch(grammarProgressProvider).valueOrNull ?? const {};
    final kaiwaConversations =
        ref.watch(kaiwaConversationsProvider).valueOrNull ?? const [];
    final levelProgress = ref.watch(jlptLevelProgressProvider).valueOrNull;

    final email = user?.email ?? '';
    final initial = email.isNotEmpty ? email[0].toUpperCase() : '?';
    final displayName = profile?.displayName ?? email;
    final streak = profile?.streakCount ?? 0;
    final xp = profile?.xp ?? 0;

    final knownVocab =
        vocabProgress.values.where((p) => p.isKnown == true).length;
    final knownKanji =
        kanjiProgress.values.where((p) => p.isKnown == true).length;
    final starredVocab = vocabProgress.values.where((p) => p.starred).length;
    final starredGrammar =
        grammarProgress.values.where((p) => p.starred).length;

    final achievements = [
      (
        earned: streak >= 7,
        icon: Icons.local_fire_department_rounded,
        label: '7 ngày',
        sub: 'Chuỗi học',
      ),
      (
        earned: knownVocab >= 50,
        icon: Icons.style_rounded,
        label: '50 từ',
        sub: 'Từ vựng',
      ),
      (
        earned: knownKanji >= 10,
        icon: Icons.brush_rounded,
        label: '10 Kanji',
        sub: 'Kanji',
      ),
      (
        earned: kaiwaConversations.isNotEmpty,
        icon: Icons.forum_rounded,
        label: 'Kaiwa đầu',
        sub: 'Hội thoại',
      ),
      (
        earned: streak >= 30,
        icon: Icons.emoji_events_rounded,
        label: '30 ngày',
        sub: 'Chuỗi học',
      ),
    ];

    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            _HeroHeader(
              initial: initial,
              name: displayName,
              streak: streak,
              xp: xp,
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(
                children: [
                  _StatTile(
                    value: '$streak',
                    label: 'Chuỗi ngày',
                    color: AppColors.accent,
                  ),
                  const SizedBox(width: 8),
                  _StatTile(
                    value: '$knownVocab',
                    label: 'Từ đã biết',
                    color: AppColors.moss,
                  ),
                  const SizedBox(width: 8),
                  _StatTile(
                    value: '$knownKanji',
                    label: 'Kanji đã biết',
                    color: AppColors.indigo,
                  ),
                  const SizedBox(width: 8),
                  _StatTile(value: '$xp', label: 'XP', color: AppColors.plum),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 22, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _SectionLabel('Tiến độ JLPT'),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border, width: 1.0),
                    ),
                    child: levelProgress == null
                        ? const Padding(
                            padding: EdgeInsets.symmetric(vertical: 10),
                            child: Center(
                              child: SizedBox(
                                width: 20,
                                height: 20,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              ),
                            ),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              for (final lp in levelProgress)
                                _JlptRing(progress: lp),
                            ],
                          ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 22, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _SectionLabel('Achievements'),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 92,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: achievements.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (context, i) {
                        final a = achievements[i];
                        return _AchievementBadge(
                          earned: a.earned,
                          icon: a.icon,
                          label: a.label,
                          sub: a.sub,
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 22, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _SectionLabel('Collections'),
                  const SizedBox(height: 10),
                  _CollectionRow(
                    emoji: '📚',
                    title: 'Từ đã đánh dấu',
                    count: '$starredVocab từ',
                    onTap: () => context.push('/vocabulary/list'),
                  ),
                  const SizedBox(height: 8),
                  _CollectionRow(
                    emoji: '📝',
                    title: 'Ngữ pháp yêu thích',
                    count: '$starredGrammar mẫu',
                    onTap: () => context.push('/grammar'),
                  ),
                  const SizedBox(height: 8),
                  _CollectionRow(
                    emoji: '💬',
                    title: 'Lịch sử Kaiwa',
                    count: '${kaiwaConversations.length} buổi',
                    onTap: () => context.push('/kaiwa'),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 22, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _SectionLabel('Settings'),
                  const SizedBox(height: 10),
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border, width: 1.0),
                    ),
                    child: Column(
                      children: [
                        _SettingsRow(
                          icon: Icons.workspace_premium_outlined,
                          label: 'Nâng cấp Premium',
                          labelColor: AppColors.accentStrong,
                          onTap: () => context.push('/premium'),
                        ),
                        const Divider(height: 1, color: AppColors.border),
                        const _SettingsRow(
                          icon: Icons.dark_mode_outlined,
                          label: 'Giao diện',
                          trailingText: 'Theo hệ thống',
                        ),
                        const Divider(height: 1, color: AppColors.border),
                        const _SettingsRow(
                          icon: Icons.language_rounded,
                          label: 'Ngôn ngữ',
                          trailingText: 'Tiếng Việt',
                        ),
                        const Divider(height: 1, color: AppColors.border),
                        _SettingsRow(
                          icon: Icons.logout_rounded,
                          label: 'Đăng xuất',
                          labelColor: AppColors.danger,
                          onTap: () => ref
                              .read(authControllerProvider.notifier)
                              .signOut(),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _HeroHeader extends StatelessWidget {
  const _HeroHeader({
    required this.initial,
    required this.name,
    required this.streak,
    required this.xp,
  });

  final String initial;
  final String name;
  final int streak;
  final int xp;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 22),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF241C15), Color(0xFF3D2F22)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 32,
            backgroundColor: AppColors.accent.withValues(alpha: 0.9),
            child: Text(
              initial,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 24,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 17,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    const Icon(
                      Icons.local_fire_department_rounded,
                      size: 13,
                      color: AppColors.accent,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      '$streak ngày học',
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      '$xp XP',
                      style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFFFFB020),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.value,
    required this.label,
    required this.color,
  });

  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border, width: 1.0),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 17,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 8.5,
                fontWeight: FontWeight.w700,
                color: AppColors.inkSoft,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _JlptRing extends StatelessWidget {
  const _JlptRing({required this.progress});

  final LevelProgress progress;

  @override
  Widget build(BuildContext context) {
    final pct = (progress.ratio * 100).round();
    return Column(
      children: [
        SizedBox(
          width: 42,
          height: 42,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CircularProgressIndicator(
                value: progress.ratio,
                strokeWidth: 4,
                backgroundColor: AppColors.border,
                valueColor: const AlwaysStoppedAnimation(AppColors.accent),
              ),
              Text(
                '$pct%',
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 9,
                  color: AppColors.ink,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          progress.level.code,
          style: const TextStyle(
            fontSize: 8.5,
            fontWeight: FontWeight.w700,
            color: AppColors.inkSoft,
          ),
        ),
      ],
    );
  }
}

class _AchievementBadge extends StatelessWidget {
  const _AchievementBadge({
    required this.earned,
    required this.icon,
    required this.label,
    required this.sub,
  });

  final bool earned;
  final IconData icon;
  final String label;
  final String sub;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 72,
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: earned ? AppColors.accentSoft : AppColors.chip,
              borderRadius: BorderRadius.circular(16),
              border: earned
                  ? null
                  : Border.all(
                      color: AppColors.border,
                      width: 2,
                      style: BorderStyle.solid,
                    ),
            ),
            alignment: Alignment.center,
            child: Icon(
              icon,
              size: 22,
              color: earned ? AppColors.accentStrong : AppColors.inkFaint,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 1,
            style: const TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              color: AppColors.ink,
            ),
          ),
          Text(
            sub,
            textAlign: TextAlign.center,
            maxLines: 1,
            style: const TextStyle(fontSize: 8, color: AppColors.inkSoft),
          ),
        ],
      ),
    );
  }
}

class _CollectionRow extends StatelessWidget {
  const _CollectionRow({
    required this.emoji,
    required this.title,
    required this.count,
    required this.onTap,
  });

  final String emoji;
  final String title;
  final String count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border, width: 1.0),
        ),
        child: Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 20)),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                      color: AppColors.ink,
                    ),
                  ),
                  Text(
                    count,
                    style: const TextStyle(
                      fontSize: 10,
                      color: AppColors.inkSoft,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              size: 18,
              color: AppColors.inkFaint,
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingsRow extends StatelessWidget {
  const _SettingsRow({
    required this.icon,
    required this.label,
    this.trailingText,
    this.labelColor,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final String? trailingText;
  final Color? labelColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        child: Row(
          children: [
            Icon(icon, size: 18, color: labelColor ?? AppColors.inkSoft),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: labelColor ?? AppColors.ink,
                ),
              ),
            ),
            if (trailingText != null)
              Text(
                trailingText!,
                style: const TextStyle(fontSize: 12, color: AppColors.inkSoft),
              ),
          ],
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
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: AppColors.inkFaint,
        letterSpacing: 0.6,
      ),
    );
  }
}
