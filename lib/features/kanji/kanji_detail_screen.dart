import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/kanji.dart';
import '../lesson/providers/content_providers.dart';

class KanjiDetailScreen extends ConsumerWidget {
  const KanjiDetailScreen({super.key, required this.kanjiId});

  final String kanjiId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final kanjiAsync = ref.watch(kanjiListProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Chi tiết Kanji')),
      body: kanjiAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Lỗi: $e')),
        data: (all) {
          final Kanji? kanji = all.where((k) => k.id == kanjiId).firstOrNull;
          if (kanji == null) {
            return const Center(child: Text('Không tìm thấy kanji này.'));
          }
          return Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Text(kanji.character, style: const TextStyle(fontSize: 96, fontWeight: FontWeight.w500)),
                ),
                const SizedBox(height: 8),
                Center(
                  child: Text(kanji.meaningVi, style: Theme.of(context).textTheme.titleLarge),
                ),
                const SizedBox(height: 28),
                _InfoRow(label: 'Âm On', value: kanji.onyomi ?? '—'),
                _InfoRow(label: 'Âm Kun', value: kanji.kunyomi ?? '—'),
                _InfoRow(label: 'Số nét', value: kanji.strokeCount?.toString() ?? '—'),
                if (kanji.exampleJp != null) ...[
                  const SizedBox(height: 20),
                  Text('Ví dụ', style: Theme.of(context).textTheme.labelLarge),
                  const SizedBox(height: 6),
                  Text(kanji.exampleJp!),
                  if (kanji.exampleVi != null)
                    Text(kanji.exampleVi!, style: Theme.of(context).textTheme.bodySmall),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(width: 90, child: Text(label, style: Theme.of(context).textTheme.labelLarge)),
          Text(value),
        ],
      ),
    );
  }
}
