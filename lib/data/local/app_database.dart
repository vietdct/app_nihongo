import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import 'tables.dart';

part 'app_database.g.dart';

@DriftDatabase(tables: [VocabularyTable, KanjiTable, LessonsTable, LessonItemsTable])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;

  static QueryExecutor _openConnection() {
    return driftDatabase(name: 'nihongo');
  }

  Stream<List<LessonsTableData>> watchLessonsByLevel(String levelId) {
    return (select(lessonsTable)
          ..where((t) => t.levelId.equals(levelId))
          ..orderBy([(t) => OrderingTerm(expression: t.orderIndex)]))
        .watch();
  }

  Stream<List<VocabularyTableData>> watchAllVocabulary() {
    return (select(vocabularyTable)..orderBy([(t) => OrderingTerm(expression: t.word)])).watch();
  }

  Stream<List<KanjiTableData>> watchAllKanji() {
    return (select(kanjiTable)..orderBy([(t) => OrderingTerm(expression: t.strokeCount)])).watch();
  }

  Stream<List<LessonItemsTableData>> watchLessonItems(String lessonId) {
    return (select(lessonItemsTable)
          ..where((t) => t.lessonId.equals(lessonId))
          ..orderBy([(t) => OrderingTerm(expression: t.orderIndex)]))
        .watch();
  }

  Future<void> replaceVocabulary(List<VocabularyTableCompanion> rows) async {
    await batch((b) => b.insertAllOnConflictUpdate(vocabularyTable, rows));
  }

  Future<void> replaceKanji(List<KanjiTableCompanion> rows) async {
    await batch((b) => b.insertAllOnConflictUpdate(kanjiTable, rows));
  }

  Future<void> replaceLessons(List<LessonsTableCompanion> rows) async {
    await batch((b) => b.insertAllOnConflictUpdate(lessonsTable, rows));
  }

  Future<void> replaceLessonItems(String lessonId, List<LessonItemsTableCompanion> rows) async {
    await batch((b) {
      b.deleteWhere(lessonItemsTable, (t) => t.lessonId.equals(lessonId));
      b.insertAllOnConflictUpdate(lessonItemsTable, rows);
    });
  }
}
