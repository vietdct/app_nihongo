import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../grammar/providers/grammar_progress_providers.dart';
import '../../kanji/providers/kanji_progress_providers.dart';
import '../../lesson/providers/content_providers.dart';
import '../../review/providers/review_mistakes_providers.dart';
import '../../vocabulary/providers/vocab_progress_providers.dart';
import '../../vocabulary/providers/vocab_review_providers.dart'
    show weakEaseThreshold;

/// Số mục "yếu" (đã ôn ít nhất 1 lần, ease factor dưới ngưỡng) theo từng kỹ
/// năng — cùng công thức `_isWeak` của `ReviewWeakPointsScreen`, tính lại ở
/// đây vì hàm đó private trong file màn hình khác, không export được.
bool _isWeak(int? reviewCount, double? easeFactor) =>
    (reviewCount ?? 0) > 0 && (easeFactor ?? 2.5) < weakEaseThreshold;

class WeakAreaCounts {
  const WeakAreaCounts({
    required this.vocab,
    required this.kanji,
    required this.grammar,
  });

  final int vocab;
  final int kanji;
  final int grammar;

  int get total => vocab + kanji + grammar;
}

final weakAreaCountsProvider = Provider.autoDispose<WeakAreaCounts>((ref) {
  final vocabList = ref.watch(vocabularyListProvider).valueOrNull ?? const [];
  final kanjiList = ref.watch(kanjiListProvider).valueOrNull ?? const [];
  final grammarList = ref.watch(grammarListProvider).valueOrNull ?? const [];
  final vocabProgress =
      ref.watch(vocabProgressProvider).valueOrNull ?? const {};
  final kanjiProgress =
      ref.watch(kanjiProgressProvider).valueOrNull ?? const {};
  final grammarProgress =
      ref.watch(grammarProgressProvider).valueOrNull ?? const {};

  return WeakAreaCounts(
    vocab: vocabList
        .where(
          (v) => _isWeak(
            vocabProgress[v.id]?.reviewCount,
            vocabProgress[v.id]?.easeFactor,
          ),
        )
        .length,
    kanji: kanjiList
        .where(
          (k) => _isWeak(
            kanjiProgress[k.id]?.reviewCount,
            kanjiProgress[k.id]?.easeFactor,
          ),
        )
        .length,
    grammar: grammarList
        .where(
          (g) => _isWeak(
            grammarProgress[g.id]?.reviewCount,
            grammarProgress[g.id]?.easeFactor,
          ),
        )
        .length,
  );
});

/// 5 lỗi lặp lại nhiều nhất (occurrence_count cao nhất) từ Mistake Notebook
/// đã có sẵn — dữ liệu thật, không tính toán suy diễn.
final topMistakesProvider = Provider.autoDispose((ref) {
  final mistakes = ref.watch(reviewMistakesProvider).valueOrNull ?? const [];
  final sorted = [...mistakes]
    ..sort((a, b) => b.occurrenceCount.compareTo(a.occurrenceCount));
  return sorted.take(5).toList();
});
