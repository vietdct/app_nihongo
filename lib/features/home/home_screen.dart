import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/network/supabase_providers.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/level_badge.dart';
import '../auth/auth_controller.dart';
import '../lesson/providers/content_providers.dart';
import '../lesson/providers/level_providers.dart';
import 'widgets/feature_tile.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final lessons = ref.watch(lessonsProvider);
    final selectedLevel = ref.watch(selectedLevelCodeProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('日本語'),
        actions: [
          const LevelBadge(),
          const SizedBox(width: 4),
          IconButton(
            tooltip: 'Đăng xuất',
            icon: const Icon(Icons.logout),
            onPressed: () => ref.read(authControllerProvider.notifier).signOut(),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          Text('おかえりなさい 👋', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 2),
          Text(
            user?.email ?? '',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.outline),
          ),
          const SizedBox(height: 24),

          // Lưới tính năng chính — theo cấp độ đang chọn ở header.
          Row(
            children: [
              Expanded(
                child: FeatureTile(
                  icon: Icons.auto_stories,
                  label: 'Bài học',
                  color: AppColors.konIro,
                  onTap: () => context.push('/lessons'),
                ),
              ),
              Expanded(
                child: FeatureTile(
                  icon: Icons.menu_book,
                  label: 'Từ vựng',
                  color: AppColors.moss,
                  onTap: () => context.push('/vocabulary'),
                ),
              ),
              Expanded(
                child: FeatureTile(
                  icon: Icons.brush,
                  label: 'Kanji',
                  color: AppColors.shuIro,
                  onTap: () => context.push('/kanji'),
                ),
              ),
              Expanded(
                child: const ComingSoonTile(
                  icon: Icons.rule_folder_outlined,
                  label: 'Ngữ pháp',
                  phaseNote: 'sẽ có ở Pha 4',
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
              ComingSoonTile(icon: Icons.style_outlined, label: 'Flashcard', phaseNote: 'sẽ có ở Pha 3'),
              ComingSoonTile(icon: Icons.quiz_outlined, label: 'Quiz', phaseNote: 'sẽ có ở Pha 3'),
              ComingSoonTile(icon: Icons.headphones_outlined, label: 'Nghe hiểu', phaseNote: 'sẽ có ở Pha 4'),
              ComingSoonTile(icon: Icons.fact_check_outlined, label: 'Thi thử JLPT', phaseNote: 'sẽ có ở Pha 7'),
            ],
          ),
          const SizedBox(height: 28),

          _SectionLabel('Bài học · $selectedLevel'),
          const SizedBox(height: 10),
          lessons.when(
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, _) => Text('Lỗi tải bài học: $e'),
            data: (items) {
              if (items.isEmpty) {
                return _EmptyState(
                  icon: Icons.auto_stories_outlined,
                  message: 'Chưa có bài học nào cho $selectedLevel.\nNội dung đang được bổ sung dần.',
                );
              }
              return Column(
                children: [
                  for (final lesson in items) ...[
                    Card(
                      margin: EdgeInsets.zero,
                      child: ListTile(
                        title: Text(lesson.title, style: const TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: lesson.description != null ? Text(lesson.description!) : null,
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => context.push('/lessons/${lesson.id}', extra: lesson.title),
                      ),
                    ),
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

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: Theme.of(context).colorScheme.outline,
            letterSpacing: 0.6,
          ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Icon(icon, size: 32, color: scheme.outline),
          const SizedBox(height: 10),
          Text(message, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}
