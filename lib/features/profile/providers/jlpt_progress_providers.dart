import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/network/supabase_providers.dart';
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

const _curatedN5VocabularyIdLowerBound = '22222222-0000-0000-0000-000000000000';
const _curatedN5VocabularyIdUpperBound = '22222222-0000-0000-0000-000000001000';

/// Tính riêng cho từng cấp độ N5→N1 mà không tải toàn bộ nội dung vào cache.
/// Chỉ lấy cột id của vocabulary/kanji song song để ghép với tiến độ cục bộ.
/// Điều này tránh việc mở tab Hồ sơ lại phải tuần tự tải hàng nghìn từ N2/N4.
/// Provider không auto-dispose để kết quả được tái sử dụng khi đổi tab.
final jlptLevelProgressProvider =
    FutureProvider<List<LevelProgress>>((ref) async {
  final levels = await ref.watch(jlptLevelsProvider.future);
  final supabase = ref.watch(supabaseProvider);
  final vocabProgress = await ref.watch(vocabProgressProvider.future);
  final kanjiProgress = await ref.watch(kanjiProgressProvider.future);

  final contentIdsByLevel = await Future.wait([
    for (final level in levels)
      _fetchLevelContentIds(
        supabase,
        levelId: level.id,
        curatedN5VocabularyOnly: level.code == 'N5',
      ),
  ]);

  final result = <LevelProgress>[];
  for (var index = 0; index < levels.length; index++) {
    final level = levels[index];
    final ids = contentIdsByLevel[index];

    final knownVocab =
        ids.vocabulary.where((id) => vocabProgress[id]?.isKnown == true).length;
    final knownKanji =
        ids.kanji.where((id) => kanjiProgress[id]?.isKnown == true).length;

    result.add(
      LevelProgress(
        level: level,
        known: knownVocab + knownKanji,
        total: ids.vocabulary.length + ids.kanji.length,
      ),
    );
  }
  return result;
});

Future<({Set<String> vocabulary, Set<String> kanji})> _fetchLevelContentIds(
  SupabaseClient supabase, {
  required String levelId,
  required bool curatedN5VocabularyOnly,
}) async {
  final results = await Future.wait<Set<String>>([
    _fetchContentIds(
      supabase,
      table: 'vocabulary',
      levelId: levelId,
      curatedN5VocabularyOnly: curatedN5VocabularyOnly,
    ),
    _fetchContentIds(
      supabase,
      table: 'kanji',
      levelId: levelId,
      curatedN5VocabularyOnly: false,
    ),
  ]);
  return (vocabulary: results[0], kanji: results[1]);
}

/// PostgREST giới hạn 1 response; phân trang để các cấp có trên 1.000 từ
/// (như N2) vẫn đếm đúng, dù payload chỉ gồm UUID.
Future<Set<String>> _fetchContentIds(
  SupabaseClient supabase, {
  required String table,
  required String levelId,
  required bool curatedN5VocabularyOnly,
}) async {
  const pageSize = 1000;
  final ids = <String>{};
  var from = 0;

  while (true) {
    final request = supabase.from(table).select('id').eq('level_id', levelId);
    final page = curatedN5VocabularyOnly && table == 'vocabulary'
        ? await request
            .gte('id', _curatedN5VocabularyIdLowerBound)
            .lt('id', _curatedN5VocabularyIdUpperBound)
            .range(from, from + pageSize - 1)
        : await request.range(from, from + pageSize - 1);
    ids.addAll([
      for (final row in page.cast<Map<String, dynamic>>()) row['id'] as String,
    ]);
    if (page.length < pageSize) return ids;
    from += pageSize;
  }
}
