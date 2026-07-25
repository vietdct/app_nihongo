import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/network/supabase_providers.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/level_badge.dart';
import '../auth/auth_controller.dart';
import '../lesson/providers/content_providers.dart';
import '../lesson/providers/level_providers.dart';
import 'providers/profile_providers.dart';
import 'widgets/feature_tile.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour < 11) return 'Chào buổi sáng';
    if (hour < 14) return 'Chào buổi trưa';
    if (hour < 18) return 'Chào buổi chiều';
    return 'Chào buổi tối';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final profileAsync = ref.watch(profileProvider);
    final lessons = ref.watch(lessonsProvider);
    final selectedLevel = ref.watch(selectedLevelCodeProvider);

    final email = user?.email ?? '';
    final initial = email.isNotEmpty ? email[0].toUpperCase() : '?';
    final displayName = profileAsync.valueOrNull?.displayName ?? email;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            CircleAvatar(
              radius: 21,
              backgroundColor: AppColors.accentSoft,
              child: Text(
                initial,
                style: const TextStyle(color: AppColors.accentStrong, fontWeight: FontWeight.w800, fontSize: 15),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_greeting, style: const TextStyle(fontSize: 12, color: AppColors.inkSoft, fontWeight: FontWeight.w400)),
                  Text(
                    displayName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.ink),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          const LevelBadge(),
          const SizedBox(width: 4),
          IconButton(
            tooltip: 'Đăng xuất',
            icon: const Icon(Icons.logout, color: AppColors.inkFaint),
            onPressed: () => ref.read(authControllerProvider.notifier).signOut(),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
        children: [
          _StreakCard(streakCount: profileAsync.valueOrNull?.streakCount, xp: profileAsync.valueOrNull?.xp),
          const SizedBox(height: 16),
          _KaiwaBanner(onTap: () => context.push('/kaiwa')),
          const SizedBox(height: 24),

          const _SectionLabel('Học ngay'),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: FeatureTile(
                  glyph: '学',
                  label: 'Bài học',
                  color: AppColors.accent,
                  onTap: () => context.push('/lessons'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FeatureTile(
                  glyph: '語',
                  label: 'Từ vựng',
                  color: AppColors.moss,
                  onTap: () => context.push('/vocabulary'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FeatureTile(
                  glyph: '字',
                  label: 'Kanji',
                  color: AppColors.indigo,
                  onTap: () => context.push('/kanji'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FeatureTile(
                  glyph: '文',
                  label: 'Ngữ pháp',
                  color: AppColors.plum,
                  onTap: () => context.push('/grammar'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),

          const _SectionLabel('Ôn tập & luyện thi'),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 4,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 0.82,
            children: const [
              ReviewTile(glyph: '復', label: 'Flashcard', phaseNote: 'sẽ có ở Pha 3'),
              ReviewTile(glyph: '験', label: 'Quiz', phaseNote: 'sẽ có ở Pha 3'),
              ReviewTile(glyph: '聴', label: 'Nghe hiểu', phaseNote: 'sẽ có ở Pha 4'),
              ReviewTile(glyph: '試', label: 'Thi thử', phaseNote: 'sẽ có ở Pha 7'),
            ],
          ),
          const SizedBox(height: 28),

          _SectionLabel('Bài học · $selectedLevel'),
          const SizedBox(height: 12),
          lessons.when(
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, _) => Text('Lỗi tải bài học: $e'),
            data: (items) {
              if (items.isEmpty) {
                return _EmptyState(
                  glyph: '学',
                  message: 'Chưa có bài học nào cho $selectedLevel.\nNội dung đang được bổ sung dần.',
                );
              }
              return Column(
                children: [
                  for (final lesson in items) ...[
                    _LessonCard(title: lesson.title, description: lesson.description, lessonId: lesson.id),
                    const SizedBox(height: 10),
                  ],
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _StreakCard extends StatelessWidget {
  const _StreakCard({required this.streakCount, required this.xp});

  final int? streakCount;
  final int? xp;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border, width: 0.6),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Chuỗi học tập', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppColors.inkSoft)),
                const SizedBox(height: 2),
                Text(
                  streakCount == null ? '—' : '$streakCount ngày',
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.ink),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
            decoration: BoxDecoration(color: AppColors.accentSoft, borderRadius: BorderRadius.circular(100)),
            child: Text(
              xp == null ? '— XP' : '$xp XP',
              style: const TextStyle(color: AppColors.accentStrong, fontWeight: FontWeight.w700, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

class _KaiwaBanner extends StatelessWidget {
  const _KaiwaBanner({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.teal, Color(0xFF1F6B62)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.18), borderRadius: BorderRadius.circular(14)),
              alignment: Alignment.center,
              child: const Text('話', style: TextStyle(fontFamily: 'ZenMaruGothic', fontSize: 22, color: Colors.white, fontWeight: FontWeight.w700)),
            ),
            const SizedBox(width: 14),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('AI Kaiwa', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16)),
                  SizedBox(height: 2),
                  Text('Luyện nói cùng AI — chọn nhân vật & tình huống', style: TextStyle(color: Colors.white70, fontSize: 12.5)),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 16),
          ],
        ),
      ),
    );
  }
}

class _LessonCard extends StatelessWidget {
  const _LessonCard({required this.title, required this.description, required this.lessonId});

  final String title;
  final String? description;
  final String lessonId;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => context.push('/lessons/$lessonId', extra: title),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border, width: 0.6),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(color: AppColors.indigoSoft, borderRadius: BorderRadius.circular(12)),
              alignment: Alignment.center,
              child: Text('課', style: AppFonts.zenMaruGothic(fontSize: 18, color: AppColors.indigo)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5, color: AppColors.ink)),
                  if (description != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      description!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12.5, color: AppColors.inkSoft),
                    ),
                  ],
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.inkFaint),
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
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: AppColors.inkFaint,
        letterSpacing: 0.6,
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.glyph, required this.message});

  final String glyph;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
      decoration: BoxDecoration(
        color: AppColors.chip,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(glyph, style: AppFonts.zenMaruGothic(fontSize: 28, color: AppColors.inkFaint)),
          const SizedBox(height: 10),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13.5, color: AppColors.inkSoft),
          ),
        ],
      ),
    );
  }
}
