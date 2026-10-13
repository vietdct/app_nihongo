import 'dart:convert';

import 'package:drift/drift.dart' show Value;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/grammar_meaning.dart';
import '../../domain/entities/grammar_point.dart';
import '../../domain/entities/kanji.dart';
import '../../domain/entities/lesson.dart';
import '../../domain/entities/vocab_meaning.dart';
import '../../domain/entities/vocabulary.dart';
import '../../domain/repositories/content_repository.dart';
import '../../shared/kanji_text_utils.dart';
import '../local/app_database.dart';

// 254 UUID N5 cốt lõi là dải liên tiếp ...000001 đến ...000254.
// Không dùng LIKE: PostgREST không hỗ trợ LIKE trên cột UUID.
const _curatedN5VocabularyIdLowerBound = '22222222-0000-0000-0000-000000000000';
const _curatedN5VocabularyIdUpperBound = '22222222-0000-0000-0000-000000001000';

/// Offline-first: mọi read đi qua Drift (stream). refreshFromRemote() chỉ
/// làm mới cache nền — nếu request Supabase thất bại (mất mạng), UI vẫn
/// tiếp tục hoạt động bình thường với dữ liệu đã cache.
class ContentRepositoryImpl implements ContentRepository {
  ContentRepositoryImpl(this._db, this._supabase);

  final AppDatabase _db;
  final SupabaseClient _supabase;

  @override
  Stream<List<Lesson>> watchLessons(String levelId) {
    return _db.watchLessonsByLevel(levelId).map(
          (rows) => rows
              .map(
                (r) => Lesson(
                  id: r.id,
                  title: r.title,
                  description: r.description,
                  levelId: r.levelId,
                  orderIndex: r.orderIndex,
                ),
              )
              .toList(),
        );
  }

  @override
  Stream<Map<String, LessonAssignment>> watchVocabularyLessonAssignments(
    String levelId,
  ) {
    return _db.watchLessonItemAssignments(levelId).map(
          (rows) => {
            for (final r in rows)
              if (r.itemType == 'vocabulary')
                r.itemId: LessonAssignment(
                  lessonId: r.lessonId,
                  orderIndex: r.orderIndex,
                ),
          },
        );
  }

  @override
  Stream<Map<String, LessonAssignment>> watchKanjiLessonAssignments(
    String levelId,
  ) {
    return _db.watchLessonItemAssignments(levelId).map(
          (rows) => {
            for (final r in rows)
              if (r.itemType == 'kanji')
                r.itemId: LessonAssignment(
                  lessonId: r.lessonId,
                  orderIndex: r.orderIndex,
                ),
          },
        );
  }

  @override
  Stream<Map<String, LessonAssignment>> watchGrammarLessonAssignments(
    String levelId,
  ) {
    return _db.watchLessonItemAssignments(levelId).map(
          (rows) => {
            for (final r in rows)
              if (r.itemType == 'grammar')
                r.itemId: LessonAssignment(
                  lessonId: r.lessonId,
                  orderIndex: r.orderIndex,
                ),
          },
        );
  }

  @override
  Stream<List<Vocabulary>> watchVocabulary(
    String levelId, {
    bool coreN5Only = false,
  }) {
    return _db.watchVocabularyByLevel(levelId).asyncMap((rows) async {
      final result = <Vocabulary>[];
      for (final r in rows) {
        if (coreN5Only &&
            (r.id.compareTo(_curatedN5VocabularyIdLowerBound) <= 0 ||
                r.id.compareTo(_curatedN5VocabularyIdUpperBound) >= 0)) {
          continue;
        }
        result.add(await _buildVocabulary(r));
      }
      return result;
    });
  }

  @override
  Stream<List<Kanji>> watchKanji(String levelId) {
    // Cấp không có Kanji riêng (IT) → hiện Kanji có trong từ vựng của cấp đó.
    return _db
        .watchKanjiByLevel(levelId)
        .asyncExpand(
          (own) => own.isNotEmpty
              ? Stream.value(own)
              : _db.watchKanjiUsedByVocabulary(levelId),
        )
        .map((rows) => rows.map(_buildKanji).toList());
  }

  @override
  Future<Kanji?> findKanjiByCharacter(String character) async {
    final row = await _db.kanjiByCharacter(character);
    return row == null ? null : _buildKanji(row);
  }

  @override
  Future<List<Vocabulary>> findRelatedVocabulary(
    String word, {
    required String excludeId,
    int limit = 8,
  }) async {
    final characters = uniqueKanjiChars(word);
    if (characters.isEmpty) return const [];
    final rows = await _db.vocabularyContainingAnyCharacter(
      characters,
      excludeId,
      limit: limit,
    );
    final result = <Vocabulary>[];
    for (final r in rows) {
      result.add(await _buildVocabulary(r));
    }
    return result;
  }

  @override
  Stream<List<GrammarPoint>> watchGrammar(String levelId) {
    return _db.watchGrammarByLevel(levelId).asyncMap((rows) async {
      final result = <GrammarPoint>[];
      for (final r in rows) {
        result.add(await _buildGrammar(r));
      }
      return result;
    });
  }

  Future<GrammarPoint> _buildGrammar(GrammarPointsTableData r) async {
    final meaningRows = await _db.grammarMeaningsFor(r.id);
    return GrammarPoint(
      id: r.id,
      title: r.title,
      explanation: r.explanation,
      levelId: r.levelId,
      exampleJp: r.exampleJp,
      exampleVi: r.exampleVi,
      commonMistake: r.commonMistake,
      memoryTip: r.memoryTip,
      comparisonNote: r.comparisonNote,
      extraExamplesJp: _decodeStringList(r.extraExamplesJp),
      extraExamplesVi: _decodeStringList(r.extraExamplesVi),
      practiceTokens: _decodeStringList(r.practiceTokens),
      practiceBlankIndex: r.practiceBlankIndex,
      meanings: meaningRows
          .map(
            (m) => GrammarMeaning(
              meaningVi: m.meaningVi,
              examplesJp: _decodeStringList(m.examplesJp),
              examplesVi: _decodeStringList(m.examplesVi),
            ),
          )
          .toList(),
    );
  }

  Kanji _buildKanji(KanjiTableData r) => Kanji(
        id: r.id,
        character: r.character,
        meaningVi: _decodeStringList(r.meaningVi),
        levelId: r.levelId,
        onyomi: _decodeStringList(r.onyomi),
        kunyomi: _decodeStringList(r.kunyomi),
        strokeCount: r.strokeCount,
        exampleJp: r.exampleJp,
        exampleVi: r.exampleVi,
        hanViet: _decodeStringList(r.hanViet),
        mnemonic: r.mnemonic,
        strokeData: r.strokeData,
        components: _decodeStringList(r.components),
      );

  static List<String> _decodeStringList(String? json) {
    if (json == null || json.isEmpty) return const [];
    return (jsonDecode(json) as List).cast<String>();
  }

  static String _encodeStringList(dynamic value) {
    return jsonEncode((value as List?)?.cast<String>() ?? const <String>[]);
  }

  @override
  Stream<List<LessonContentItem>> watchLessonItems(String lessonId) {
    return _db.watchLessonItems(lessonId).asyncMap((items) async {
      final result = <LessonContentItem>[];
      for (final item in items) {
        if (item.itemType == 'vocabulary') {
          final v = await (_db.select(_db.vocabularyTable)
                ..where((t) => t.id.equals(item.itemId)))
              .getSingleOrNull();
          if (v != null) {
            result.add(LessonContentItem.vocabulary(await _buildVocabulary(v)));
          }
        } else if (item.itemType == 'kanji') {
          final k = await (_db.select(_db.kanjiTable)
                ..where((t) => t.id.equals(item.itemId)))
              .getSingleOrNull();
          if (k != null) {
            result.add(LessonContentItem.kanji(_buildKanji(k)));
          }
        } else if (item.itemType == 'grammar') {
          final g = await (_db.select(_db.grammarPointsTable)
                ..where((t) => t.id.equals(item.itemId)))
              .getSingleOrNull();
          if (g != null) {
            result.add(LessonContentItem.grammar(await _buildGrammar(g)));
          }
        }
      }
      return result;
    });
  }

  Future<Vocabulary> _buildVocabulary(VocabularyTableData r) async {
    final meaningRows = await _db.vocabularyMeaningsFor(r.id);
    final similarWords = _decodeStringList(r.similarWords);
    final similarWordsMeaningVi = _decodeStringList(r.similarWordsMeaningVi);
    final comparisonWords = _decodeStringList(r.comparisonWords);
    final comparisonMainDescs = _decodeStringList(r.comparisonMainDescs);
    final comparisonOtherDescs = _decodeStringList(r.comparisonOtherDescs);
    final usageExamplesJp = _decodeStringList(r.commonUsageExamplesJp);
    final usageExamplesVi = _decodeStringList(r.commonUsageExamplesVi);
    return Vocabulary(
      id: r.id,
      word: r.word,
      reading: r.reading,
      levelId: r.levelId,
      partOfSpeech: r.partOfSpeech,
      audioUrl: r.audioUrl,
      category: r.category,
      commonUsagePattern: r.commonUsagePattern,
      commonUsageDesc: r.commonUsageDesc,
      commonUsageExamples: [
        for (var i = 0; i < usageExamplesJp.length; i++)
          VocabUsageExample(
            phrase: usageExamplesJp[i],
            meaningVi: i < usageExamplesVi.length ? usageExamplesVi[i] : '',
          ),
      ],
      nuancePoints: _decodeStringList(r.nuancePoints),
      similarWords: [
        for (var i = 0; i < similarWords.length; i++)
          VocabSimilarWord(
            word: similarWords[i],
            meaningVi: i < similarWordsMeaningVi.length
                ? similarWordsMeaningVi[i]
                : '',
          ),
      ],
      comparisons: [
        for (var i = 0; i < comparisonWords.length; i++)
          VocabComparison(
            word: comparisonWords[i],
            mainWordDesc:
                i < comparisonMainDescs.length ? comparisonMainDescs[i] : '',
            otherWordDesc:
                i < comparisonOtherDescs.length ? comparisonOtherDescs[i] : '',
          ),
      ],
      commonMistakeNote: r.commonMistakeNote,
      commonMistakeSuggestions: _decodeStringList(r.commonMistakeSuggestions),
      meanings: meaningRows
          .map(
            (m) => VocabMeaning(
              meaningVi: m.meaningVi,
              exampleJp: m.exampleJp,
              exampleVi: m.exampleVi,
              extraExamplesJp: _decodeStringList(m.extraExamplesJp),
              extraExamplesVi: _decodeStringList(m.extraExamplesVi),
            ),
          )
          .toList(),
    );
  }

  /// PostgREST giới hạn tối đa 1000 dòng/response theo mặc định — với >1000
  /// từ vựng 1 cấp độ thì `.select()` đơn thuần sẽ bị cắt bớt âm thầm, nên
  /// phải phân trang bằng `.range()` cho tới khi hết dữ liệu.
  Future<List<Map<String, dynamic>>> _fetchAllRows(
    String table,
    String levelId, {
    bool coreN5VocabularyOnly = false,
  }) async {
    const pageSize = 1000;
    final result = <Map<String, dynamic>>[];
    var from = 0;
    while (true) {
      final request = _supabase.from(table).select().eq('level_id', levelId);
      final page = coreN5VocabularyOnly && table == 'vocabulary'
          ? await request
              .gte('id', _curatedN5VocabularyIdLowerBound)
              .lt('id', _curatedN5VocabularyIdUpperBound)
              .range(from, from + pageSize - 1)
          : await request.range(from, from + pageSize - 1);
      result.addAll(page.cast<Map<String, dynamic>>());
      if (page.length < pageSize) break;
      from += pageSize;
    }
    return result;
  }

  KanjiTableCompanion _kanjiCompanion(Map<String, dynamic> r) {
    return KanjiTableCompanion.insert(
      id: r['id'] as String,
      character: r['character'] as String,
      meaningVi: Value(_encodeStringList(r['meaning_vi'])),
      levelId: r['level_id'] as String,
      onyomi: Value(_encodeStringList(r['onyomi'])),
      kunyomi: Value(_encodeStringList(r['kunyomi'])),
      strokeCount: Value(r['stroke_count'] as int?),
      exampleJp: Value(r['example_jp'] as String?),
      exampleVi: Value(r['example_vi'] as String?),
      hanViet: Value(_encodeStringList(r['han_viet'])),
      mnemonic: Value(r['mnemonic'] as String?),
      strokeData: Value(
        r['stroke_data'] == null ? null : jsonEncode(r['stroke_data']),
      ),
      components: Value(_encodeStringList(r['components'])),
    );
  }

  /// Từ vựng của 1 cấp có thể chứa Kanji thuộc cấp khác (VD từ IT dùng Kanji
  /// N5/N4/N2). Tải thêm đúng các chữ đó để thẻ Kanji và nét vẽ luôn hiện,
  /// kể cả khi người dùng chưa từng mở cấp kia.
  Future<void> _syncKanjiOfOtherLevels(
    String levelId,
    List<Map<String, dynamic>> vocabRows,
  ) async {
    final chars = <String>{
      for (final r in vocabRows) ...uniqueKanjiChars(r['word'] as String),
    }.toList();
    const chunkSize = 100;
    final rows = <Map<String, dynamic>>[];
    for (var i = 0; i < chars.length; i += chunkSize) {
      final chunk = chars.sublist(
        i,
        i + chunkSize > chars.length ? chars.length : i + chunkSize,
      );
      final page = await _supabase
          .from('kanji')
          .select()
          .inFilter('character', chunk)
          .neq('level_id', levelId);
      rows.addAll(page.cast<Map<String, dynamic>>());
    }
    if (rows.isEmpty) return;
    await _db.upsertKanji([for (final r in rows) _kanjiCompanion(r)]);
  }

  @override
  Future<void> refreshFromRemote(
    String levelId, {
    bool coreN5Only = false,
  }) async {
    final vocabRows = await _fetchAllRows(
      'vocabulary',
      levelId,
      coreN5VocabularyOnly: coreN5Only,
    );
    await _db.replaceVocabulary(levelId, [
      for (final r in vocabRows)
        VocabularyTableCompanion.insert(
          id: r['id'] as String,
          word: r['word'] as String,
          reading: r['reading'] as String,
          levelId: r['level_id'] as String,
          partOfSpeech: Value(r['part_of_speech'] as String?),
          audioUrl: Value(r['audio_url'] as String?),
          category: Value(r['category'] as String?),
          commonUsagePattern: Value(r['common_usage_pattern'] as String?),
          commonUsageDesc: Value(r['common_usage_desc'] as String?),
          commonUsageExamplesJp:
              Value(_encodeStringList(r['common_usage_examples_jp'])),
          commonUsageExamplesVi:
              Value(_encodeStringList(r['common_usage_examples_vi'])),
          nuancePoints: Value(_encodeStringList(r['nuance_points'])),
          similarWords: Value(_encodeStringList(r['similar_words'])),
          similarWordsMeaningVi:
              Value(_encodeStringList(r['similar_words_meaning_vi'])),
          comparisonWords: Value(_encodeStringList(r['comparison_words'])),
          comparisonMainDescs:
              Value(_encodeStringList(r['comparison_main_descs'])),
          comparisonOtherDescs:
              Value(_encodeStringList(r['comparison_other_descs'])),
          commonMistakeNote: Value(r['common_mistake_note'] as String?),
          commonMistakeSuggestions:
              Value(_encodeStringList(r['common_mistake_suggestions'])),
        ),
    ]);

    final vocabIds = [for (final r in vocabRows) r['id'] as String];
    if (vocabIds.isNotEmpty) {
      // Danh sách ID dài (>~200) làm URL `in.(...)` vượt giới hạn của
      // PostgREST/gateway và trả về 400 — chia nhỏ theo lô để tránh lỗi.
      const chunkSize = 150;
      final meaningRows = <Map<String, dynamic>>[];
      for (var i = 0; i < vocabIds.length; i += chunkSize) {
        final chunk = vocabIds.sublist(
          i,
          i + chunkSize > vocabIds.length ? vocabIds.length : i + chunkSize,
        );
        final rows = await _supabase
            .from('vocabulary_meanings')
            .select()
            .inFilter('vocabulary_id', chunk);
        meaningRows.addAll(rows.cast<Map<String, dynamic>>());
      }
      await _db.replaceVocabularyMeanings(vocabIds, [
        for (final r in meaningRows)
          VocabularyMeaningsTableCompanion.insert(
            id: r['id'] as String,
            vocabularyId: r['vocabulary_id'] as String,
            orderIndex: Value(r['order_index'] as int? ?? 0),
            meaningVi: r['meaning_vi'] as String,
            exampleJp: Value(r['example_jp'] as String?),
            exampleVi: Value(r['example_vi'] as String?),
            extraExamplesJp: Value(_encodeStringList(r['extra_examples_jp'])),
            extraExamplesVi: Value(_encodeStringList(r['extra_examples_vi'])),
          ),
      ]);
    }

    final kanjiRows = await _fetchAllRows('kanji', levelId);
    await _db.replaceKanji(levelId, [
      for (final r in kanjiRows) _kanjiCompanion(r),
    ]);
    await _syncKanjiOfOtherLevels(levelId, vocabRows);

    final grammarRows = await _fetchAllRows('grammar_points', levelId);
    await _db.replaceGrammar(levelId, [
      for (final r in grammarRows)
        GrammarPointsTableCompanion.insert(
          id: r['id'] as String,
          title: r['title'] as String,
          explanation: r['explanation'] as String,
          levelId: r['level_id'] as String,
          exampleJp: Value(r['example_jp'] as String?),
          exampleVi: Value(r['example_vi'] as String?),
          commonMistake: Value(r['common_mistake'] as String?),
          memoryTip: Value(r['memory_tip'] as String?),
          comparisonNote: Value(r['comparison_note'] as String?),
          extraExamplesJp: Value(_encodeStringList(r['extra_examples_jp'])),
          extraExamplesVi: Value(_encodeStringList(r['extra_examples_vi'])),
          practiceTokens: Value(_encodeStringList(r['practice_tokens'])),
          practiceBlankIndex: Value(r['practice_blank_index'] as int?),
        ),
    ]);

    final grammarIds = [for (final r in grammarRows) r['id'] as String];
    if (grammarIds.isNotEmpty) {
      // Cùng lý do chia lô như vocabulary_meanings ở trên — tránh URL
      // `in.(...)` quá dài khi 1 cấp độ có nhiều điểm ngữ pháp.
      const chunkSize = 150;
      final meaningRows = <Map<String, dynamic>>[];
      for (var i = 0; i < grammarIds.length; i += chunkSize) {
        final chunk = grammarIds.sublist(
          i,
          i + chunkSize > grammarIds.length ? grammarIds.length : i + chunkSize,
        );
        final rows = await _supabase
            .from('grammar_meanings')
            .select()
            .inFilter('grammar_point_id', chunk);
        meaningRows.addAll(rows.cast<Map<String, dynamic>>());
      }
      await _db.replaceGrammarMeanings(grammarIds, [
        for (final r in meaningRows)
          GrammarMeaningsTableCompanion.insert(
            id: r['id'] as String,
            grammarPointId: r['grammar_point_id'] as String,
            orderIndex: Value(r['order_index'] as int? ?? 0),
            meaningVi: r['meaning_vi'] as String,
            examplesJp: Value(_encodeStringList(r['examples_jp'])),
            examplesVi: Value(_encodeStringList(r['examples_vi'])),
          ),
      ]);
    }

    final lessonRows = await _fetchAllRows('lessons', levelId);
    await _db.replaceLessons(levelId, [
      for (final r in lessonRows)
        LessonsTableCompanion.insert(
          id: r['id'] as String,
          title: r['title'] as String,
          levelId: r['level_id'] as String,
          description: Value(r['description'] as String?),
          orderIndex: Value(r['order_index'] as int? ?? 0),
        ),
    ]);

    for (final lesson in lessonRows) {
      final lessonId = lesson['id'] as String;
      final itemRows = await _supabase
          .from('lesson_items')
          .select()
          .eq('lesson_id', lessonId);
      await _db.replaceLessonItems(lessonId, [
        for (final r in itemRows)
          LessonItemsTableCompanion.insert(
            id: r['id'] as String,
            lessonId: r['lesson_id'] as String,
            itemType: r['item_type'] as String,
            itemId: r['item_id'] as String,
            orderIndex: Value(r['order_index'] as int? ?? 0),
          ),
      ]);
    }
  }
}
