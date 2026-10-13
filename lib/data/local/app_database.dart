import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import '../../shared/kanji_text_utils.dart';
import 'tables.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [
    VocabularyTable,
    VocabularyMeaningsTable,
    KanjiTable,
    GrammarPointsTable,
    GrammarMeaningsTable,
    LessonsTable,
    LessonItemsTable,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 11;

  // Đây chỉ là cache offline (nguồn sự thật là Supabase, xem
  // ContentRepositoryImpl.refreshFromRemote) nên khi đổi schema, đơn giản
  // nhất là xoá sạch rồi tạo lại — dữ liệu sẽ tự nạp lại ngay sau đó.
  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) => m.createAll(),
        onUpgrade: (m, from, to) async {
          for (final table in allTables) {
            await m.deleteTable(table.actualTableName);
          }
          await m.createAll();
        },
      );

  static QueryExecutor _openConnection() {
    return driftDatabase(name: 'nihongo');
  }

  Stream<List<LessonsTableData>> watchLessonsByLevel(String levelId) {
    return (select(lessonsTable)
          ..where((t) => t.levelId.equals(levelId))
          ..orderBy([(t) => OrderingTerm(expression: t.orderIndex)]))
        .watch();
  }

  Stream<List<VocabularyTableData>> watchVocabularyByLevel(String levelId) {
    return (select(vocabularyTable)
          ..where((t) => t.levelId.equals(levelId))
          ..orderBy([(t) => OrderingTerm(expression: t.word)]))
        .watch();
  }

  Stream<List<KanjiTableData>> watchKanjiByLevel(String levelId) {
    return (select(kanjiTable)
          ..where((t) => t.levelId.equals(levelId))
          ..orderBy([(t) => OrderingTerm(expression: t.strokeCount)]))
        .watch();
  }

  /// Kanji xuất hiện trong từ vựng của 1 cấp (dùng cho cấp không có bộ Kanji
  /// riêng như IT). Nghe cả bảng kanji vì Kanji cấp khác được tải sau từ vựng.
  Stream<List<KanjiTableData>> watchKanjiUsedByVocabulary(String levelId) {
    return customSelect('SELECT 1', readsFrom: {kanjiTable, vocabularyTable})
        .watch()
        .asyncMap((_) async {
      final words = await (select(vocabularyTable)
            ..where((t) => t.levelId.equals(levelId)))
          .map((r) => r.word)
          .get();
      final chars = {for (final w in words) ...uniqueKanjiChars(w)}.toList();
      if (chars.isEmpty) return <KanjiTableData>[];
      return (select(kanjiTable)
            ..where((t) => t.character.isIn(chars))
            ..orderBy([(t) => OrderingTerm(expression: t.strokeCount)]))
          .get();
    });
  }

  /// Tra 1 chữ Kanji không giới hạn theo cấp độ — dùng để ghép âm Hán Việt/
  /// breakdown cho từ vựng có chữ thuộc cấp độ khác cấp đang chọn. Chỉ tìm
  /// được trong dữ liệu đã cache cục bộ (cấp độ người dùng từng mở qua).
  Future<KanjiTableData?> kanjiByCharacter(String character) {
    return (select(kanjiTable)..where((t) => t.character.equals(character)))
        .getSingleOrNull();
  }

  /// Từ vựng (thuộc bất kỳ cấp độ nào đã cache) có chứa ít nhất 1 trong các
  /// ký tự Kanji của [characters], trừ chính từ [excludeId] — nguồn cho
  /// section "Từ liên quan".
  Future<List<VocabularyTableData>> vocabularyContainingAnyCharacter(
    List<String> characters,
    String excludeId, {
    int limit = 8,
  }) {
    if (characters.isEmpty) return Future.value(const []);
    final query = select(vocabularyTable)
      ..where((t) {
        final matchesAnyChar = characters
            .map<Expression<bool>>((c) => t.word.like('%$c%'))
            .reduce((a, b) => a | b);
        return t.id.equals(excludeId).not() & matchesAnyChar;
      })
      ..limit(limit);
    return query.get();
  }

  Stream<List<GrammarPointsTableData>> watchGrammarByLevel(String levelId) {
    return (select(grammarPointsTable)..where((t) => t.levelId.equals(levelId)))
        .watch();
  }

  Stream<List<LessonItemsTableData>> watchLessonItems(String lessonId) {
    return (select(lessonItemsTable)
          ..where((t) => t.lessonId.equals(lessonId))
          ..orderBy([(t) => OrderingTerm(expression: t.orderIndex)]))
        .watch();
  }

  /// Bài học của mọi từ vựng/kanji trong 1 cấp độ — join lesson_items với
  /// lessons để lọc theo levelId (lesson_items không có cột levelId riêng).
  Stream<
      List<
          ({
            String itemType,
            String itemId,
            String lessonId,
            int orderIndex
          })>> watchLessonItemAssignments(String levelId) {
    final query = select(lessonItemsTable).join([
      innerJoin(
        lessonsTable,
        lessonsTable.id.equalsExp(lessonItemsTable.lessonId),
      ),
    ])
      ..where(lessonsTable.levelId.equals(levelId))
      ..orderBy([
        OrderingTerm(expression: lessonsTable.orderIndex),
        OrderingTerm(expression: lessonItemsTable.orderIndex),
      ]);
    return query.watch().map(
          (rows) => [
            for (final row in rows)
              (
                itemType: row.readTable(lessonItemsTable).itemType,
                itemId: row.readTable(lessonItemsTable).itemId,
                lessonId: row.readTable(lessonItemsTable).lessonId,
                orderIndex: row.readTable(lessonItemsTable).orderIndex,
              ),
          ],
        );
  }

  Future<void> replaceVocabulary(
    String levelId,
    List<VocabularyTableCompanion> rows,
  ) async {
    await batch((b) {
      b.deleteWhere(vocabularyTable, (t) => t.levelId.equals(levelId));
      b.insertAllOnConflictUpdate(vocabularyTable, rows);
    });
  }

  Future<List<VocabularyMeaningsTableData>> vocabularyMeaningsFor(
    String vocabularyId,
  ) {
    return (select(vocabularyMeaningsTable)
          ..where((t) => t.vocabularyId.equals(vocabularyId))
          ..orderBy([(t) => OrderingTerm(expression: t.orderIndex)]))
        .get();
  }

  Future<void> replaceVocabularyMeanings(
    List<String> vocabularyIds,
    List<VocabularyMeaningsTableCompanion> rows,
  ) async {
    await batch((b) {
      b.deleteWhere(
        vocabularyMeaningsTable,
        (t) => t.vocabularyId.isIn(vocabularyIds),
      );
      b.insertAllOnConflictUpdate(vocabularyMeaningsTable, rows);
    });
  }

  Future<List<GrammarMeaningsTableData>> grammarMeaningsFor(
    String grammarPointId,
  ) {
    return (select(grammarMeaningsTable)
          ..where((t) => t.grammarPointId.equals(grammarPointId))
          ..orderBy([(t) => OrderingTerm(expression: t.orderIndex)]))
        .get();
  }

  Future<void> replaceGrammarMeanings(
    List<String> grammarPointIds,
    List<GrammarMeaningsTableCompanion> rows,
  ) async {
    await batch((b) {
      b.deleteWhere(
        grammarMeaningsTable,
        (t) => t.grammarPointId.isIn(grammarPointIds),
      );
      b.insertAllOnConflictUpdate(grammarMeaningsTable, rows);
    });
  }

  Future<void> replaceKanji(
    String levelId,
    List<KanjiTableCompanion> rows,
  ) async {
    await batch((b) {
      b.deleteWhere(kanjiTable, (t) => t.levelId.equals(levelId));
      b.insertAllOnConflictUpdate(kanjiTable, rows);
    });
  }

  Future<void> upsertKanji(List<KanjiTableCompanion> rows) async {
    await batch((b) => b.insertAllOnConflictUpdate(kanjiTable, rows));
  }

  Future<void> replaceGrammar(
    String levelId,
    List<GrammarPointsTableCompanion> rows,
  ) async {
    await batch((b) {
      b.deleteWhere(grammarPointsTable, (t) => t.levelId.equals(levelId));
      b.insertAllOnConflictUpdate(grammarPointsTable, rows);
    });
  }

  Future<void> replaceLessons(
    String levelId,
    List<LessonsTableCompanion> rows,
  ) async {
    await batch((b) {
      b.deleteWhere(lessonsTable, (t) => t.levelId.equals(levelId));
      b.insertAllOnConflictUpdate(lessonsTable, rows);
    });
  }

  Future<void> replaceLessonItems(
    String lessonId,
    List<LessonItemsTableCompanion> rows,
  ) async {
    await batch((b) {
      b.deleteWhere(lessonItemsTable, (t) => t.lessonId.equals(lessonId));
      b.insertAllOnConflictUpdate(lessonItemsTable, rows);
    });
  }
}
