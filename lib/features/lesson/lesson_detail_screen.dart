import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/lesson.dart';
import 'providers/content_providers.dart';

class LessonDetailScreen extends ConsumerWidget {
  const LessonDetailScreen({super.key, required this.lessonId, this.title});

  final String lessonId;
  final String? title;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(lessonItemsProvider(lessonId));

    return Scaffold(
      appBar: AppBar(title: Text(title ?? 'Bài học')),
      body: items.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Lỗi: $e')),
        data: (contentItems) {
          if (contentItems.isEmpty) {
            return const Center(child: Text('Bài học này chưa có nội dung.'));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: contentItems.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, i) => _ContentItemTile(item: contentItems[i]),
          );
        },
      ),
    );
  }
}

class _ContentItemTile extends StatelessWidget {
  const _ContentItemTile({required this.item});

  final LessonContentItem item;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    if (item.type == LessonItemType.vocabulary) {
      final v = item.vocabulary!;
      return Card(
        margin: EdgeInsets.zero,
        child: ListTile(
          leading: CircleAvatar(backgroundColor: scheme.secondaryContainer, child: const Text('語')),
          title: Text('${v.word} 「${v.reading}」', style: const TextStyle(fontWeight: FontWeight.w600)),
          subtitle: Text(v.meaningVi),
        ),
      );
    }

    final k = item.kanji!;
    return Card(
      margin: EdgeInsets.zero,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: scheme.tertiaryContainer,
          child: Text(k.character, style: const TextStyle(fontSize: 18)),
        ),
        title: Text(k.meaningVi, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text('On: ${k.onyomi ?? "—"}  ·  Kun: ${k.kunyomi ?? "—"}'),
      ),
    );
  }
}
