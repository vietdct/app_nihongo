import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../grammar/providers/grammar_progress_providers.dart';
import '../../lesson/providers/content_providers.dart';
import '../../vocabulary/providers/vocab_progress_providers.dart';
import '../widgets/profile_section_label.dart';

/// Nhóm "Học tập" › Bookmarks — danh sách thật các từ vựng/ngữ pháp đã đánh
/// dấu sao (starred), không chỉ đếm số lượng như ở Learning Overview. Ghép
/// client-side giữa danh mục đầy đủ (`vocabularyListProvider`/
/// `grammarListProvider`) và tiến độ (`starred` trong vocab_progress/
/// grammar_progress) vì app chưa có bảng "bookmark" riêng.
class BookmarksScreen extends ConsumerWidget {
  const BookmarksScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vocabAsync = ref.watch(vocabularyListProvider);
    final vocabProgress =
        ref.watch(vocabProgressProvider).valueOrNull ?? const {};
    final grammarAsync = ref.watch(grammarListProvider);
    final grammarProgress =
        ref.watch(grammarProgressProvider).valueOrNull ?? const {};

    final starredVocab = (vocabAsync.valueOrNull ?? const [])
        .where((v) => vocabProgress[v.id]?.starred == true)
        .toList();
    final starredGrammar = (grammarAsync.valueOrNull ?? const [])
        .where((g) => grammarProgress[g.id]?.starred == true)
        .toList();

    final loading = vocabAsync.isLoading || grammarAsync.isLoading;

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        backgroundColor: AppColors.canvas,
        title: const Text('Đã đánh dấu'),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
          : ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    ProfileSectionLabel('Từ vựng (${starredVocab.length})'),
                    InkWell(
                      onTap: () => context.push('/vocabulary/list'),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(vertical: 2),
                        child: Text(
                          'Xem đầy đủ',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.accentStrong,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                if (starredVocab.isEmpty)
                  const _EmptyHint(text: 'Chưa đánh dấu từ vựng nào.')
                else
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border, width: 1.0),
                    ),
                    child: Column(
                      children: [
                        for (var i = 0; i < starredVocab.length; i++) ...[
                          if (i > 0)
                            const Divider(height: 1, color: AppColors.border),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '${starredVocab[i].word} · ${starredVocab[i].reading}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w800,
                                          fontSize: 13.5,
                                          color: AppColors.ink,
                                        ),
                                      ),
                                      if (starredVocab[i]
                                          .meanings
                                          .isNotEmpty) ...[
                                        const SizedBox(height: 2),
                                        Text(
                                          starredVocab[i].meanings.first
                                              .meaningVi,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontSize: 11.5,
                                            color: AppColors.inkSoft,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                const Icon(
                                  Icons.star_rounded,
                                  size: 18,
                                  color: AppColors.accent,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                const SizedBox(height: 22),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    ProfileSectionLabel(
                      'Ngữ pháp (${starredGrammar.length})',
                    ),
                    InkWell(
                      onTap: () => context.push('/grammar'),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(vertical: 2),
                        child: Text(
                          'Xem đầy đủ',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.accentStrong,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                if (starredGrammar.isEmpty)
                  const _EmptyHint(text: 'Chưa đánh dấu mẫu ngữ pháp nào.')
                else
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border, width: 1.0),
                    ),
                    child: Column(
                      children: [
                        for (var i = 0; i < starredGrammar.length; i++) ...[
                          if (i > 0)
                            const Divider(height: 1, color: AppColors.border),
                          InkWell(
                            onTap: () => context
                                .push('/grammar/${starredGrammar[i].id}'),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 12,
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      starredGrammar[i].title,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 13.5,
                                        color: AppColors.ink,
                                      ),
                                    ),
                                  ),
                                  const Icon(
                                    Icons.chevron_right_rounded,
                                    size: 18,
                                    color: AppColors.inkFaint,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
              ],
            ),
    );
  }
}

class _EmptyHint extends StatelessWidget {
  const _EmptyHint({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border, width: 1.0),
      ),
      child: Text(
        text,
        style: const TextStyle(fontSize: 12.5, color: AppColors.inkSoft),
      ),
    );
  }
}
