import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../grammar/providers/grammar_progress_providers.dart';
import '../kanji/providers/kanji_progress_providers.dart';
import '../lesson/providers/content_providers.dart';
import '../vocabulary/providers/vocab_progress_providers.dart';
import '../vocabulary/providers/vocab_review_providers.dart'
    show weakEaseThreshold;

const _maxRowsPerSection = 8;

/// "Điểm yếu" — suy ra hoàn toàn từ `easeFactor` (SM-2) đã có sẵn trên
/// VocabProgress/KanjiProgress/GrammarProgress, không cần bảng mới. Chỉ tính
/// mục đã ôn ít nhất 1 lần (`reviewCount > 0`) — mục chưa ôn có ease mặc định
/// 2.5, không phải "yếu", chỉ là chưa có dữ liệu. Ngưỡng dùng lại
/// `weakEaseThreshold` đã có ở màn Vocabulary (áp dụng chung cho cả 3 module
/// vì cùng 1 thang ease của `computeNextSchedule`).
class ReviewWeakPointsScreen extends ConsumerWidget {
  const ReviewWeakPointsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vocabList = ref.watch(vocabularyListProvider).valueOrNull ?? const [];
    final kanjiList = ref.watch(kanjiListProvider).valueOrNull ?? const [];
    final grammarList = ref.watch(grammarListProvider).valueOrNull ?? const [];
    final vocabProgress =
        ref.watch(vocabProgressProvider).valueOrNull ?? const {};
    final kanjiProgress =
        ref.watch(kanjiProgressProvider).valueOrNull ?? const {};
    final grammarProgress =
        ref.watch(grammarProgressProvider).valueOrNull ?? const {};

    final weakVocab = [
      for (final v in vocabList)
        if (_isWeak(
          vocabProgress[v.id]?.reviewCount,
          vocabProgress[v.id]?.easeFactor,
        ))
          (title: v.word, ease: vocabProgress[v.id]!.easeFactor),
    ]..sort((a, b) => a.ease.compareTo(b.ease));

    final weakKanji = [
      for (final k in kanjiList)
        if (_isWeak(
          kanjiProgress[k.id]?.reviewCount,
          kanjiProgress[k.id]?.easeFactor,
        ))
          (title: k.character, ease: kanjiProgress[k.id]!.easeFactor),
    ]..sort((a, b) => a.ease.compareTo(b.ease));

    final weakGrammar = [
      for (final g in grammarList)
        if (_isWeak(
          grammarProgress[g.id]?.reviewCount,
          grammarProgress[g.id]?.easeFactor,
        ))
          (title: g.title, ease: grammarProgress[g.id]!.easeFactor),
    ]..sort((a, b) => a.ease.compareTo(b.ease));

    final hasAnyWeak =
        weakVocab.isNotEmpty || weakKanji.isNotEmpty || weakGrammar.isNotEmpty;

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(title: const Text('Điểm yếu')),
      body: !hasAnyWeak
          ? const _EmptyWeakPointsState()
          : ListView(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
              children: [
                if (weakVocab.isNotEmpty)
                  _WeakSection(
                    title: 'Từ vựng',
                    color: AppColors.moss,
                    items: weakVocab,
                    onReviewTap: () => context.push('/vocabulary/review'),
                  ),
                if (weakKanji.isNotEmpty)
                  _WeakSection(
                    title: 'Kanji',
                    color: AppColors.indigo,
                    items: weakKanji,
                    onReviewTap: () => context.push('/kanji/review'),
                  ),
                if (weakGrammar.isNotEmpty)
                  _WeakSection(
                    title: 'Ngữ pháp',
                    color: AppColors.plum,
                    items: weakGrammar,
                    onReviewTap: () => context.push('/grammar/review'),
                  ),
              ],
            ),
    );
  }
}

bool _isWeak(int? reviewCount, double? easeFactor) =>
    (reviewCount ?? 0) > 0 && (easeFactor ?? 2.5) < weakEaseThreshold;

class _EmptyWeakPointsState extends StatelessWidget {
  const _EmptyWeakPointsState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.emoji_events_outlined,
              size: 48,
              color: AppColors.accent,
            ),
            SizedBox(height: 12),
            Text(
              'Chưa phát hiện điểm yếu nào',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 16,
                color: AppColors.ink,
              ),
            ),
            SizedBox(height: 6),
            Text(
              'Tiếp tục ôn tập để hệ thống nhận ra từ/chữ/mẫu nào bạn hay quên.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: AppColors.inkSoft),
            ),
          ],
        ),
      ),
    );
  }
}

class _WeakSection extends StatelessWidget {
  const _WeakSection({
    required this.title,
    required this.color,
    required this.items,
    required this.onReviewTap,
  });

  final String title;
  final Color color;
  final List<({String title, double ease})> items;
  final VoidCallback onReviewTap;

  @override
  Widget build(BuildContext context) {
    final shown = items.take(_maxRowsPerSection).toList();
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$title · ${items.length} mục yếu',
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 14,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.border, width: 1.0),
            ),
            child: Column(
              children: [
                for (final item in shown)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 15,
                      vertical: 10,
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            item.title,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                              color: AppColors.ink,
                            ),
                          ),
                        ),
                        Text(
                          'Ease ${item.ease.toStringAsFixed(1)}',
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.inkSoft,
                          ),
                        ),
                      ],
                    ),
                  ),
                InkWell(
                  borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(18),
                  ),
                  onTap: onReviewTap,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Text(
                      'Ôn ngay $title',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                        color: color,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
