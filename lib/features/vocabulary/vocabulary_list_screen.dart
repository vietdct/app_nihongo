import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/vocabulary.dart';
import '../../shared/level_badge.dart';
import '../lesson/providers/content_providers.dart';
import '../lesson/providers/level_providers.dart';

final _vocabSearchQueryProvider = StateProvider<String>((ref) => '');

class VocabularyListScreen extends ConsumerWidget {
  const VocabularyListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vocabAsync = ref.watch(vocabularyListProvider);
    final query = ref.watch(_vocabSearchQueryProvider).trim().toLowerCase();
    final selectedLevel = ref.watch(selectedLevelCodeProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Từ vựng'),
        actions: const [LevelBadge(), SizedBox(width: 12)],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.search),
                    hintText: 'Tra từ (chữ Nhật hoặc cách đọc)...',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  onChanged: (v) => ref.read(_vocabSearchQueryProvider.notifier).state = v,
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: vocabAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Lỗi: $e')),
              data: (all) {
                final filtered = query.isEmpty
                    ? all
                    : all
                        .where((v) =>
                            v.word.toLowerCase().contains(query) ||
                            v.reading.toLowerCase().contains(query) ||
                            v.meaningVi.toLowerCase().contains(query))
                        .toList();

                if (all.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        'Chưa có từ vựng nào cho $selectedLevel.\nNội dung đang được bổ sung dần.',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                  );
                }
                if (filtered.isEmpty) {
                  return const Center(child: Text('Không tìm thấy từ nào.'));
                }
                return ListView.separated(
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, i) => _VocabTile(vocab: filtered[i]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _VocabTile extends StatelessWidget {
  const _VocabTile({required this.vocab});

  final Vocabulary vocab;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text('${vocab.word} 「${vocab.reading}」', style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(vocab.meaningVi),
      trailing: vocab.partOfSpeech != null
          ? Text(vocab.partOfSpeech!, style: Theme.of(context).textTheme.labelSmall)
          : null,
      onTap: () => showModalBottomSheet(
        context: context,
        showDragHandle: true,
        builder: (_) => _VocabDetailSheet(vocab: vocab),
      ),
    );
  }
}

class _VocabDetailSheet extends StatelessWidget {
  const _VocabDetailSheet({required this.vocab});

  final Vocabulary vocab;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(vocab.word, style: Theme.of(context).textTheme.headlineMedium),
          Text(vocab.reading, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          Text(vocab.meaningVi, style: const TextStyle(fontWeight: FontWeight.w600)),
          if (vocab.exampleJp != null) ...[
            const SizedBox(height: 16),
            Text(vocab.exampleJp!),
            if (vocab.exampleVi != null) Text(vocab.exampleVi!, style: Theme.of(context).textTheme.bodySmall),
          ],
        ],
      ),
    );
  }
}
