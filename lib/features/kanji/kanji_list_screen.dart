import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../lesson/providers/content_providers.dart';

final _kanjiSearchQueryProvider = StateProvider<String>((ref) => '');

class KanjiListScreen extends ConsumerWidget {
  const KanjiListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final kanjiAsync = ref.watch(kanjiListProvider);
    final query = ref.watch(_kanjiSearchQueryProvider).trim();

    return Scaffold(
      appBar: AppBar(title: const Text('Kanji · N5')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: TextField(
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Tra kanji hoặc nghĩa...',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              onChanged: (v) => ref.read(_kanjiSearchQueryProvider.notifier).state = v,
            ),
          ),
          Expanded(
            child: kanjiAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Lỗi: $e')),
              data: (all) {
                final filtered = query.isEmpty
                    ? all
                    : all
                        .where((k) => k.character.contains(query) || k.meaningVi.toLowerCase().contains(query.toLowerCase()))
                        .toList();

                if (filtered.isEmpty) {
                  return const Center(child: Text('Không tìm thấy kanji nào.'));
                }
                return GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: 0.85,
                  ),
                  itemCount: filtered.length,
                  itemBuilder: (context, i) {
                    final k = filtered[i];
                    return InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () => context.push('/kanji/${k.id}'),
                      child: Card(
                        margin: EdgeInsets.zero,
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(k.character, style: const TextStyle(fontSize: 28)),
                              const SizedBox(height: 4),
                              Text(
                                k.meaningVi,
                                style: Theme.of(context).textTheme.labelSmall,
                                textAlign: TextAlign.center,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
