import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import 'tables.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [
    VocabularyTable,
    VocabularyMeaningsTable,
    KanjiTable,
    GrammarPointsTable,
    LessonsTable,
    LessonItemsTable,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 7;

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

  Future<void> replaceKanji(
    String levelId,
    List<KanjiTableCompanion> rows,
  ) async {
    await batch((b) {
      b.deleteWhere(kanjiTable, (t) => t.levelId.equals(levelId));
      b.insertAllOnConflictUpdate(kanjiTable, rows);
    });
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
