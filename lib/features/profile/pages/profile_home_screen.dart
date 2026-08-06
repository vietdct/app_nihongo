import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/supabase_providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../grammar/providers/grammar_progress_providers.dart';
import '../../home/providers/profile_providers.dart';
import '../../kaiwa/providers/kaiwa_conversation_providers.dart';
import '../../kanji/providers/kanji_progress_providers.dart';
import '../../vocabulary/providers/vocab_progress_providers.dart';
import '../providers/jlpt_progress_providers.dart';
import '../widgets/jlpt_progress_ring.dart';
import '../widgets/profile_group_nav_card.dart';
import '../widgets/profile_section_label.dart';
import '../widgets/profile_stat_tile.dart';

/// Trang gốc tab "Hồ sơ" — trung tâm điều hướng tới 4 nhóm màn hình con:
/// Học tập / Thành tích / AI / Tài khoản (nhóm "Cá nhân" nằm ngay ở phần
/// header của trang này, không tách trang riêng). Mỗi nhóm chỉ hiển thị 1
/// preview số liệu thật trên hub, chi tiết đầy đủ nằm ở trang con.
class ProfileHomeScreen extends ConsumerWidget {
  const ProfileHomeScreen({super.key});

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
    final country = profile?.country;
    final studySince = profile?.createdAt;
    final avatarUrl = profile?.avatarUrl;

    final knownVocab =
        vocabProgress.values.where((p) => p.isKnown == true).length;
    final knownKanji =
        kanjiProgress.values.where((p) => p.isKnown == true).length;
    final knownGrammar =
        grammarProgress.values.where((p) => p.isKnown == true).length;

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
              country: country,
              studySince: studySince,
              avatarUrl: avatarUrl,
              onTap: () => context.push('/profile/edit'),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(
                children: [
                  ProfileStatTile(
                    value: '$streak',
                    label: 'Chuỗi ngày',
                    color: AppColors.accent,
                  ),
                  const SizedBox(width: 8),
                  ProfileStatTile(
                    value: '$knownVocab',
                    label: 'Từ đã biết',
                    color: AppColors.moss,
                  ),
                  const SizedBox(width: 8),
                  ProfileStatTile(
                    value: '$knownKanji',
                    label: 'Kanji đã biết',
                    color: AppColors.indigo,
                  ),
                  const SizedBox(width: 8),
                  ProfileStatTile(value: '$xp', label: 'XP', color: AppColors.plum),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 22, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const ProfileSectionLabel('Tiến độ JLPT'),
                      _SeeAllButton(
                        onTap: () => context.push('/profile/learning'),
                      ),
                    ],
                  ),
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
                                JlptProgressRing(progress: lp),
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
                  const ProfileSectionLabel('Khám phá'),
                  const SizedBox(height: 10),
                  ProfileGroupNavCard(
                    icon: Icons.menu_book_rounded,
                    iconColor: AppColors.moss,
                    title: 'Học tập',
                    subtitle:
                        '$knownVocab từ · $knownKanji Kanji · $knownGrammar ngữ pháp · ${kaiwaConversations.length} buổi Kaiwa',
                    onTap: () => context.push('/profile/learning'),
                  ),
                  const SizedBox(height: 8),
                  ProfileGroupNavCard(
                    icon: Icons.emoji_events_rounded,
                    iconColor: AppColors.accentStrong,
                    title: 'Thành tích',
                    subtitle: '$xp XP · Chuỗi $streak ngày · Huy hiệu',
                    onTap: () => context.push('/profile/achievements'),
                  ),
                  const SizedBox(height: 8),
                  ProfileGroupNavCard(
                    icon: Icons.auto_awesome_rounded,
                    iconColor: AppColors.indigo,
                    title: 'AI Insights',
                    subtitle: 'Gợi ý học tập cá nhân hoá',
                    onTap: () => context.push('/profile/ai-insights'),
                  ),
                  const SizedBox(height: 8),
                  ProfileGroupNavCard(
                    icon: Icons.settings_rounded,
                    iconColor: AppColors.plum,
                    title: 'Tài khoản',
                    subtitle: 'Premium · Giao diện · Đăng xuất',
                    onTap: () => context.push('/profile/account'),
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

class _SeeAllButton extends StatelessWidget {
  const _SeeAllButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: const Padding(
        padding: EdgeInsets.symmetric(vertical: 2, horizontal: 4),
        child: Text(
          'Xem tất cả',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: AppColors.accentStrong,
          ),
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
    required this.onTap,
    this.country,
    this.studySince,
    this.avatarUrl,
  });

  final String initial;
  final String name;
  final int streak;
  final int xp;
  final String? country;
  final DateTime? studySince;
  final String? avatarUrl;
  final VoidCallback onTap;

  static const _months = [
    'T1', 'T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'T8', 'T9', 'T10', 'T11', 'T12',
  ];

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
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
              backgroundImage:
                  avatarUrl != null ? NetworkImage(avatarUrl!) : null,
              child: avatarUrl == null
                  ? Text(
                      initial,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 24,
                      ),
                    )
                  : null,
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
                  if (studySince != null || country != null) ...[
                    const SizedBox(height: 3),
                    Text(
                      [
                        if (studySince != null)
                          'Học từ ${studySince!.day}/${_months[studySince!.month - 1]}/${studySince!.year}',
                        if (country != null) country!,
                      ].join(' · '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 10.5,
                        color: Colors.white54,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              size: 20,
              color: Colors.white54,
            ),
          ],
        ),
      ),
    );
  }
}
