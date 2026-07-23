import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/network/supabase_providers.dart';
import '../auth/auth_controller.dart';
import '../lesson/providers/content_providers.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final lessons = ref.watch(lessonsProvider);

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
        padding: const EdgeInsets.all(16),
        children: [
          Text('おかえりなさい 👋', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 4),
          Text(user?.email ?? '', style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _NavCard(
                  icon: Icons.menu_book,
                  label: 'Từ vựng',
                  onTap: () => context.push('/vocabulary'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _NavCard(
                  icon: Icons.brush,
                  label: 'Kanji',
                  onTap: () => context.push('/kanji'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text('Bài học · N5', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 10),
          lessons.when(
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, _) => Text('Lỗi tải bài học: $e'),
            data: (items) {
              if (items.isEmpty) {
                return const Text('Chưa có bài học nào — kéo để làm mới sau khi seed dữ liệu.');
              }
              return Column(
                children: [
                  for (final lesson in items)
                    Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      child: ListTile(
                        title: Text(lesson.title, style: const TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: lesson.description != null ? Text(lesson.description!) : null,
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => context.push('/lessons/${lesson.id}', extra: lesson.title),
                      ),
                    ),
                ],
              );
            },
          ),
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
