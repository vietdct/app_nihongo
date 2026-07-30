import 'dart:convert';

import 'package:drift/drift.dart' show Value;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/grammar_point.dart';
import '../../domain/entities/kanji.dart';
import '../../domain/entities/lesson.dart';
import '../../domain/entities/vocab_meaning.dart';
import '../../domain/entities/vocabulary.dart';
import '../../domain/repositories/content_repository.dart';
import '../local/app_database.dart';

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
  Stream<List<Vocabulary>> watchVocabulary(String levelId) {
    return _db.watchVocabularyByLevel(levelId).asyncMap((rows) async {
      final result = <Vocabulary>[];
      for (final r in rows) {
        result.add(await _buildVocabulary(r));
      }
      return result;
    });
  }

  @override
  Stream<List<Kanji>> watchKanji(String levelId) {
    return _db.watchKanjiByLevel(levelId).map(
          (rows) => rows.map(_buildKanji).toList(),
        );
  }

  @override
  Stream<List<GrammarPoint>> watchGrammar(String levelId) {
    return _db.watchGrammarByLevel(levelId).map(
          (rows) => rows.map(_buildGrammar).toList(),
        );
  }

  GrammarPoint _buildGrammar(GrammarPointsTableData r) => GrammarPoint(
        id: r.id,
        title: r.title,
        explanation: r.explanation,
        levelId: r.levelId,
        exampleJp: r.exampleJp,
        exampleVi: r.exampleVi,
        commonMistake: r.commonMistake,
        memoryTip: r.memoryTip,
        comparisonNote: r.comparisonNote,
        practiceTokens: _decodeStringList(r.practiceTokens),
        practiceBlankIndex: r.practiceBlankIndex,
      );

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
            result.add(LessonContentItem.grammar(_buildGrammar(g)));
          }
        }
      }
      return result;
    });
  }

  Future<Vocabulary> _buildVocabulary(VocabularyTableData r) async {
    final meaningRows = await _db.vocabularyMeaningsFor(r.id);
    return Vocabulary(
      id: r.id,
      word: r.word,
      reading: r.reading,
      levelId: r.levelId,
      partOfSpeech: r.partOfSpeech,
      audioUrl: r.audioUrl,
      meanings: meaningRows
          .map(
            (m) => VocabMeaning(
              meaningVi: m.meaningVi,
              exampleJp: m.exampleJp,
              exampleVi: m.exampleVi,
            ),
          )
          .toList(),
    );
  }

  @override
  Future<void> refreshFromRemote(String levelId) async {
    final vocabRows =
        await _supabase.from('vocabulary').select().eq('level_id', levelId);
    await _db.replaceVocabulary(levelId, [
      for (final r in vocabRows)
        VocabularyTableCompanion.insert(
          id: r['id'] as String,
          word: r['word'] as String,
          reading: r['reading'] as String,
          levelId: r['level_id'] as String,
          partOfSpeech: Value(r['part_of_speech'] as String?),
          audioUrl: Value(r['audio_url'] as String?),
        ),
    ]);

    final vocabIds = [for (final r in vocabRows) r['id'] as String];
    if (vocabIds.isNotEmpty) {
      final meaningRows = await _supabase
          .from('vocabulary_meanings')
          .select()
          .inFilter('vocabulary_id', vocabIds);
      await _db.replaceVocabularyMeanings(vocabIds, [
        for (final r in meaningRows)
          VocabularyMeaningsTableCompanion.insert(
            id: r['id'] as String,
            vocabularyId: r['vocabulary_id'] as String,
            orderIndex: Value(r['order_index'] as int? ?? 0),
            meaningVi: r['meaning_vi'] as String,
            exampleJp: Value(r['example_jp'] as String?),
            exampleVi: Value(r['example_vi'] as String?),
          ),
      ]);
    }

    final kanjiRows =
        await _supabase.from('kanji').select().eq('level_id', levelId);
    await _db.replaceKanji(levelId, [
      for (final r in kanjiRows)
        KanjiTableCompanion.insert(
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
        ),
    ]);

    final grammarRows =
        await _supabase.from('grammar_points').select().eq('level_id', levelId);
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
          practiceTokens: Value(_encodeStringList(r['practice_tokens'])),
          practiceBlankIndex: Value(r['practice_blank_index'] as int?),
        ),
    ]);

    final lessonRows =
        await _supabase.from('lessons').select().eq('level_id', levelId);
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
