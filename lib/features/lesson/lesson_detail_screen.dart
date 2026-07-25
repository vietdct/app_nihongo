import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
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
            return const Center(child: Text('Bài học này chưa có nội dung.', style: TextStyle(color: AppColors.inkSoft)));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(20),
            itemCount: contentItems.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
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
    final String glyph;
    final String title;
    final String subtitle;
    final Color bg;
    final Color fg;

    switch (item.type) {
      case LessonItemType.vocabulary:
        final v = item.vocabulary!;
        glyph = '語';
        title = '${v.word} 「${v.reading}」';
        subtitle = v.primaryMeaning;
        bg = AppColors.mossSoft;
        fg = AppColors.moss;
      case LessonItemType.kanji:
        final k = item.kanji!;
        glyph = k.character;
        title = k.primaryMeaning;
        subtitle = 'On: ${k.onyomi.isEmpty ? "—" : k.onyomi.join('、')}   ·   '
            'Kun: ${k.kunyomi.isEmpty ? "—" : k.kunyomi.join('、')}';
        bg = AppColors.indigoSoft;
        fg = AppColors.indigo;
      case LessonItemType.grammar:
        final g = item.grammar!;
        glyph = '文';
        title = g.title;
        subtitle = g.explanation;
        bg = AppColors.plumSoft;
        fg = AppColors.plum;
    }

    return Container(
      padding: const EdgeInsets.all(13),
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
            decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
            alignment: Alignment.center,
            child: Text(glyph, style: AppFonts.zenMaruGothic(fontSize: item.type == LessonItemType.vocabulary ? 16 : 19, color: fg)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5, color: AppColors.ink)),
                const SizedBox(height: 2),
                Text(subtitle, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12.5, color: AppColors.inkSoft)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
