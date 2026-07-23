import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../shared/level_badge.dart';
import '../lesson/providers/content_providers.dart';
import '../lesson/providers/level_providers.dart';

final _kanjiSearchQueryProvider = StateProvider<String>((ref) => '');

class KanjiListScreen extends ConsumerWidget {
  const KanjiListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final kanjiAsync = ref.watch(kanjiListProvider);
    final query = ref.watch(_kanjiSearchQueryProvider).trim();
    final selectedLevel = ref.watch(selectedLevelCodeProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kanji'),
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
                    hintText: 'Tra kanji hoặc nghĩa...',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  onChanged: (v) => ref.read(_kanjiSearchQueryProvider.notifier).state = v,
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: kanjiAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Lỗi: $e')),
              data: (all) {
                if (all.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        'Chưa có kanji nào cho $selectedLevel.\nNội dung đang được bổ sung dần.',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                  );
                }

                final filtered = query.isEmpty
                    ? all
                    : all
                        .where((k) =>
                            k.character.contains(query) || k.meaningVi.toLowerCase().contains(query.toLowerCase()))
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
