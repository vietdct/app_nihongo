import 'package:drift/drift.dart' show Value;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/kanji.dart';
import '../../domain/entities/lesson.dart';
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
              .map((r) => Lesson(
                    id: r.id,
                    title: r.title,
                    description: r.description,
                    levelId: r.levelId,
                    orderIndex: r.orderIndex,
                  ))
              .toList(),
        );
  }

  @override
  Stream<List<Vocabulary>> watchVocabulary(String levelId) {
    return _db.watchVocabularyByLevel(levelId).map(
          (rows) => rows
              .map((r) => Vocabulary(
                    id: r.id,
                    word: r.word,
                    reading: r.reading,
                    meaningVi: r.meaningVi,
                    levelId: r.levelId,
                    partOfSpeech: r.partOfSpeech,
                    exampleJp: r.exampleJp,
                    exampleVi: r.exampleVi,
                    audioUrl: r.audioUrl,
                  ))
              .toList(),
        );
  }

  @override
  Stream<List<Kanji>> watchKanji(String levelId) {
    return _db.watchKanjiByLevel(levelId).map(
          (rows) => rows
              .map((r) => Kanji(
                    id: r.id,
                    character: r.character,
                    meaningVi: r.meaningVi,
                    levelId: r.levelId,
                    onyomi: r.onyomi,
                    kunyomi: r.kunyomi,
                    strokeCount: r.strokeCount,
                    exampleJp: r.exampleJp,
                    exampleVi: r.exampleVi,
                  ))
              .toList(),
        );
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
            result.add(LessonContentItem.vocabulary(Vocabulary(
              id: v.id,
              word: v.word,
              reading: v.reading,
              meaningVi: v.meaningVi,
              levelId: v.levelId,
              partOfSpeech: v.partOfSpeech,
              exampleJp: v.exampleJp,
              exampleVi: v.exampleVi,
              audioUrl: v.audioUrl,
            )));
          }
        } else if (item.itemType == 'kanji') {
          final k = await (_db.select(_db.kanjiTable)
                ..where((t) => t.id.equals(item.itemId)))
              .getSingleOrNull();
          if (k != null) {
            result.add(LessonContentItem.kanji(Kanji(
              id: k.id,
              character: k.character,
              meaningVi: k.meaningVi,
              levelId: k.levelId,
              onyomi: k.onyomi,
              kunyomi: k.kunyomi,
              strokeCount: k.strokeCount,
              exampleJp: k.exampleJp,
              exampleVi: k.exampleVi,
            )));
          }
        }
      }
      return result;
    });
  }

  @override
  Future<void> refreshFromRemote(String levelId) async {
    final vocabRows =
        await _supabase.from('vocabulary').select().eq('level_id', levelId);
    await _db.replaceVocabulary([
      for (final r in vocabRows)
        VocabularyTableCompanion.insert(
          id: r['id'] as String,
          word: r['word'] as String,
          reading: r['reading'] as String,
          meaningVi: r['meaning_vi'] as String,
          levelId: r['level_id'] as String,
          partOfSpeech: Value(r['part_of_speech'] as String?),
          exampleJp: Value(r['example_jp'] as String?),
          exampleVi: Value(r['example_vi'] as String?),
          audioUrl: Value(r['audio_url'] as String?),
        ),
    ]);

    final kanjiRows =
        await _supabase.from('kanji').select().eq('level_id', levelId);
    await _db.replaceKanji([
      for (final r in kanjiRows)
        KanjiTableCompanion.insert(
          id: r['id'] as String,
          character: r['character'] as String,
          meaningVi: r['meaning_vi'] as String,
          levelId: r['level_id'] as String,
          onyomi: Value(r['onyomi'] as String?),
          kunyomi: Value(r['kunyomi'] as String?),
          strokeCount: Value(r['stroke_count'] as int?),
          exampleJp: Value(r['example_jp'] as String?),
          exampleVi: Value(r['example_vi'] as String?),
        ),
    ]);

    final lessonRows =
        await _supabase.from('lessons').select().eq('level_id', levelId);
    await _db.replaceLessons([
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
