import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/repositories/content_repository_provider.dart';
import '../../../domain/entities/jlpt_level.dart';
import '../../kanji/providers/kanji_progress_providers.dart';
import '../../lesson/providers/level_providers.dart';
import '../../vocabulary/providers/vocab_progress_providers.dart';

/// % hoàn thành 1 cấp độ JLPT — tính từ số từ vựng + kanji đã đánh dấu
/// "thuộc" thật. Ngữ pháp không tính vào vì ngữ pháp chỉ có đánh dấu sao
/// (yêu thích), không có khái niệm thuộc/chưa thuộc như từ vựng/kanji.
class LevelProgress {
  const LevelProgress({
    required this.level,
    required this.known,
    required this.total,
  });

  final JlptLevel level;
  final int known;
  final int total;

  double get ratio => total == 0 ? 0 : known / total;
}

/// Tính riêng cho từng cấp độ N5→N1 — gọi thẳng repository theo levelId của
/// từng cấp thay vì qua [selectedLevelCodeProvider] (cấp đang duyệt), để
/// không phụ thuộc/đổi cấp độ người dùng đang chọn xem.
final jlptLevelProgressProvider =
    FutureProvider.autoDispose<List<LevelProgress>>((ref) async {
  final levels = await ref.watch(jlptLevelsProvider.future);
  final repo = ref.watch(contentRepositoryProvider);
  final vocabProgress = await ref.watch(vocabProgressProvider.future);
  final kanjiProgress = await ref.watch(kanjiProgressProvider.future);

  final result = <LevelProgress>[];
  for (final level in levels) {
    await repo.refreshFromRemote(level.id);
    final vocab = await repo.watchVocabulary(level.id).first;
    final kanji = await repo.watchKanji(level.id).first;

    final knownVocab =
        vocab.where((v) => vocabProgress[v.id]?.isKnown == true).length;
    final knownKanji =
        kanji.where((k) => kanjiProgress[k.id]?.isKnown == true).length;

    result.add(
      LevelProgress(
        level: level,
        known: knownVocab + knownKanji,
        total: vocab.length + kanji.length,
      ),
    );
  }
  return result;
});
