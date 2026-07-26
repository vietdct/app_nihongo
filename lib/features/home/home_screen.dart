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
import 'widgets/daily_goal_card.dart';
import 'widgets/feature_tile.dart';
import 'widgets/skill_path_node.dart';

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
    final profile = profileAsync.valueOrNull;
    final displayName = profile?.displayName ?? email;

    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          _HeroHeader(
            greeting: _greeting,
            initial: initial,
            displayName: displayName,
            streakCount: profile?.streakCount,
            xp: profile?.xp,
            onLogout: () => ref.read(authControllerProvider.notifier).signOut(),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
            child: DailyGoalCard(lastStudyDate: profile?.lastStudyDate),
          ),
          lessons.maybeWhen(
            data: (items) => items.isEmpty
                ? const SizedBox.shrink()
                : Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                    child: _ContinueLessonCard(
                      title: items.first.title,
                      lessonId: items.first.id,
                      levelLabel: selectedLevel,
                    ),
                  ),
            orElse: () => const SizedBox.shrink(),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 26, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SectionLabel('Lộ trình học · $selectedLevel'),
                const SizedBox(height: 16),
                Column(
                  children: [
                    _SkillPathRow(
                      alignLeft: true,
                      node: SkillPathNode(
                          glyph: '語',
                          label: 'Từ vựng',
                          color: AppColors.moss,
                          onTap: () => context.push('/vocabulary'),),
                    ),
                    const SizedBox(height: 20),
                    _SkillPathRow(
                      alignLeft: false,
                      node: SkillPathNode(
                          glyph: '字',
                          label: 'Kanji',
                          color: AppColors.indigo,
                          onTap: () => context.push('/kanji'),),
                    ),
                    const SizedBox(height: 20),
                    _SkillPathRow(
                      alignLeft: true,
                      node: SkillPathNode(
                          glyph: '文',
                          label: 'Ngữ pháp',
                          color: AppColors.plum,
                          onTap: () => context.push('/grammar'),),
                    ),
                    const SizedBox(height: 20),
                    _SkillPathRow(
                      alignLeft: false,
                      node: SkillPathNode(
                          glyph: '聴',
                          label: 'Nghe hiểu',
                          color: AppColors.accent,
                          onTap: () => context.push('/listening'),),
                    ),
                    const SizedBox(height: 20),
                    _SkillPathRow(
                      alignLeft: true,
                      node: SkillPathNode(
                          glyph: '話',
                          label: 'AI Kaiwa',
                          color: AppColors.teal,
                          onTap: () => context.push('/kaiwa'),),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 26, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _SectionLabel('Ôn tập nhanh'),
                const SizedBox(height: 12),
                GridView.count(
                  crossAxisCount: 3,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 0.82,
                  children: [
                    const ReviewTile(
                        icon: Icons.style_outlined,
                        label: 'Flashcard',
                        phaseNote: 'sẽ có ở Pha 3',),
                    ReviewTile(
                        icon: Icons.help_outline_rounded,
                        label: 'Quiz',
                        onTap: () => context.push('/quiz'),),
                    const ReviewTile(
                        icon: Icons.fact_check_outlined,
                        label: 'Thi thử',
                        phaseNote: 'sẽ có ở Pha 7',),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
        ],
      ),
      bottomNavigationBar: const _HomeBottomNav(),
    );
  }
}

/// Footer 4 tab theo mockup (Trang chủ/Ôn tập/Premium/Hồ sơ). Chỉ "Trang chủ"
/// có màn hình thật — 3 tab kia chưa được xây (không có màn Ôn tập tổng hợp/
/// Premium/Hồ sơ), bấm vào báo "sắp có" giống các nút SẮP CÓ khác trong app
/// thay vì dẫn tới màn hình trống hoặc giả vờ đã có.
class _HomeBottomNav extends StatelessWidget {
  const _HomeBottomNav();

  static const _tabs = [
    (icon: Icons.home_rounded, label: 'Trang chủ'),
    (icon: Icons.history_rounded, label: 'Ôn tập'),
    (icon: Icons.workspace_premium_outlined, label: 'Premium'),
    (icon: Icons.person_outline_rounded, label: 'Hồ sơ'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(6, 8, 6, 10),
      decoration: const BoxDecoration(
        color: AppColors.card,
        border: Border(top: BorderSide(color: AppColors.border, width: 1.0)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            for (var i = 0; i < _tabs.length; i++)
              Expanded(
                child: _NavTabButton(
                  icon: _tabs[i].icon,
                  label: _tabs[i].label,
                  active: i == 0,
                  onTap: i == 0
                      ? null
                      : () {
                          ScaffoldMessenger.of(context)
                            ..hideCurrentSnackBar()
                            ..showSnackBar(SnackBar(
                                content: Text(
                                    '${_tabs[i].label} — sẽ có ở bản sau',),),);
                        },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _NavTabButton extends StatelessWidget {
  const _NavTabButton(
      {required this.icon,
      required this.label,
      required this.active,
      required this.onTap,});

  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final color = active ? AppColors.accent : AppColors.inkFaint;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 22, color: color),
            const SizedBox(height: 3),
            Text(label,
                style: TextStyle(
                    fontSize: 9, fontWeight: FontWeight.w700, color: color,),),
          ],
        ),
      ),
    );
  }
}

/// Header gradient hero — thay cho AppBar + thẻ streak riêng cũ. Chứa lời
/// chào + tên thật, pill streak/XP thật (không có pill xu — app chưa có khái
/// niệm xu), LevelBadge + nút đăng xuất, và hàng "mascot" + bong bóng chào.
/// Mascot dùng tạm avatar chữ cái đầu — chờ user cung cấp ảnh linh vật thật.
class _HeroHeader extends StatelessWidget {
  const _HeroHeader({
    required this.greeting,
    required this.initial,
    required this.displayName,
    required this.streakCount,
    required this.xp,
    required this.onLogout,
  });

  final String greeting;
  final String initial;
  final String displayName;
  final int? streakCount;
  final int? xp;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.heroGradientStart, AppColors.heroGradientEnd],
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
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 19,
                    backgroundColor: Colors.white.withValues(alpha: 0.28),
                    child: Text(initial,
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 14,),),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(greeting,
                            style: const TextStyle(
                                fontSize: 10.5,
                                color: Colors.white70,
                                fontWeight: FontWeight.w600,),),
                        Text(
                          displayName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,),
                        ),
                      ],
                    ),
                  ),
                  if (streakCount != null)
                    _HeaderPill(
                        icon: Icons.local_fire_department_rounded,
                        text: '$streakCount',),
                  const SizedBox(width: 6),
                  if (xp != null) _HeaderPill(text: '$xp XP'),
                  const SizedBox(width: 6),
                  const LevelBadge(onGradient: true),
                  const SizedBox(width: 4),
                  IconButton(
                    tooltip: 'Đăng xuất',
                    icon:
                        const Icon(Icons.logout, color: Colors.white, size: 20),
                    onPressed: onLogout,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  CircleAvatar(
                    radius: 32,
                    backgroundColor: Colors.white.withValues(alpha: 0.28),
                    child: Text(initial,
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 22,),),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 13, vertical: 11,),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(16),
                          topRight: Radius.circular(16),
                          bottomRight: Radius.circular(16),
                          bottomLeft: Radius.circular(4),
                        ),
                        boxShadow: [
                          BoxShadow(
                              color: Colors.black.withValues(alpha: 0.12),
                              blurRadius: 18,
                              offset: const Offset(0, 8),),
                        ],
                      ),
                      child: Text(
                        streakCount != null && streakCount! > 0
                            ? 'Giữ chuỗi $streakCount ngày nhé!'
                            : 'Bắt đầu chuỗi học đầu tiên hôm nay!',
                        style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 13,
                            color: AppColors.ink,),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeaderPill extends StatelessWidget {
  const _HeaderPill({this.icon, required this.text});

  final IconData? icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.22),
          borderRadius: BorderRadius.circular(100),),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: Colors.white),
            const SizedBox(width: 4),
          ],
          Text(text,
              style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  fontSize: 11.5,),),
        ],
      ),
    );
  }
}

/// Căn 1 node skill-path sang trái/phải để tạo hiệu ứng zigzag như mockup.
class _SkillPathRow extends StatelessWidget {
  const _SkillPathRow({required this.alignLeft, required this.node});

  final bool alignLeft;
  final SkillPathNode node;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment:
          alignLeft ? MainAxisAlignment.start : MainAxisAlignment.end,
      children: [node],
    );
  }
}

/// Thẻ "vào học ngay" nổi bật dưới thẻ mục tiêu — trỏ tới bài học đầu tiên
/// trong danh sách thật (app chưa lưu "đang học dở bài nào" nên không dùng
/// chữ "Tiếp tục" ngụ ý đã học dở, chỉ mời vào học bài đầu của cấp độ hiện tại).
class _ContinueLessonCard extends StatelessWidget {
  const _ContinueLessonCard(
      {required this.title, required this.lessonId, required this.levelLabel,});

  final String title;
  final String lessonId;
  final String levelLabel;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () => context.push('/lessons/$lessonId', extra: title),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.border, width: 1.0),
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                  color: AppColors.accentSoft,
                  borderRadius: BorderRadius.circular(13),),
              alignment: Alignment.center,
              child: const Icon(Icons.menu_book_rounded,
                  color: AppColors.accentStrong, size: 20,),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Vào học ngay · $title',
                      style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 13.5,
                          color: AppColors.ink,),),
                  const SizedBox(height: 1),
                  Text('Bài học đầu · $levelLabel',
                      style: const TextStyle(
                          fontSize: 11, color: AppColors.inkSoft,),),
                ],
              ),
            ),
            Container(
              width: 26,
              height: 26,
              decoration: const BoxDecoration(
                  color: AppColors.accent, shape: BoxShape.circle,),
              alignment: Alignment.center,
              child: const Icon(Icons.arrow_forward_ios_rounded,
                  color: Colors.white, size: 10,),
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
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: AppColors.inkFaint,
        letterSpacing: 0.6,
      ),
    );
  }
}
