import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../shared/level_badge.dart';
import 'providers/content_providers.dart';
import 'providers/level_providers.dart';

class LessonListScreen extends ConsumerWidget {
  const LessonListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lessons = ref.watch(lessonsProvider);
    final selectedLevel = ref.watch(selectedLevelCodeProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bài học'),
        actions: const [LevelBadge(), SizedBox(width: 12)],
      ),
      body: lessons.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Lỗi: $e')),
        data: (items) {
          if (items.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Chưa có bài học nào cho $selectedLevel.\nNội dung đang được bổ sung dần.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, i) {
              final lesson = items[i];
              return Card(
                margin: EdgeInsets.zero,
                child: ListTile(
                  title: Text(lesson.title, style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: lesson.description != null ? Text(lesson.description!) : null,
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/lessons/${lesson.id}', extra: lesson.title),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
