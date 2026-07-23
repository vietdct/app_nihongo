import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/network/supabase_providers.dart';
import '../../shared/level_selector.dart';
import '../auth/auth_controller.dart';
import '../lesson/providers/content_providers.dart';
import '../lesson/providers/level_providers.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final lessons = ref.watch(lessonsProvider);
    final selectedLevel = ref.watch(selectedLevelCodeProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nihongo'),
        actions: [
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
          Text('おかえりなさい 👋', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 4),
          Text(
            user?.email ?? '',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.outline),
          ),
          const SizedBox(height: 24),
          const _SectionLabel('Cấp độ'),
          const SizedBox(height: 10),
          const LevelSelector(),
          const SizedBox(height: 28),
          Row(
            children: [
              Expanded(
                child: _NavCard(icon: Icons.menu_book, label: 'Từ vựng', onTap: () => context.push('/vocabulary')),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _NavCard(icon: Icons.brush, label: 'Kanji', onTap: () => context.push('/kanji')),
              ),
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

class _NavCard extends StatelessWidget {
  const _NavCard({required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            children: [
              Icon(icon, color: scheme.primary),
              const SizedBox(height: 8),
              Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }
}
