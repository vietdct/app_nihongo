import 'package:drift/drift.dart';

/// Mirror của bảng `vocabulary` trên Supabase — nguồn sự thật cho UI khi offline.
class VocabularyTable extends Table {
  TextColumn get id => text()();
  TextColumn get word => text()();
  TextColumn get reading => text()();
  TextColumn get meaningVi => text()();
  TextColumn get partOfSpeech => text().nullable()();
  TextColumn get exampleJp => text().nullable()();
  TextColumn get exampleVi => text().nullable()();
  TextColumn get audioUrl => text().nullable()();
  TextColumn get levelId => text()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Mirror của bảng `kanji`.
class KanjiTable extends Table {
  TextColumn get id => text()();
  TextColumn get character => text()();
  TextColumn get onyomi => text().nullable()();
  TextColumn get kunyomi => text().nullable()();
  TextColumn get meaningVi => text()();
  IntColumn get strokeCount => integer().nullable()();
  TextColumn get exampleJp => text().nullable()();
  TextColumn get exampleVi => text().nullable()();
  TextColumn get levelId => text()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Mirror của bảng `lessons`.
class LessonsTable extends Table {
  TextColumn get id => text()();
  TextColumn get title => text()();
  TextColumn get description => text().nullable()();
  TextColumn get levelId => text()();
  IntColumn get orderIndex => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}

/// Mirror của bảng `lesson_items` — polymorphic (itemType + itemId trỏ tới
/// VocabularyTable hoặc KanjiTable tuỳ giá trị itemType).
class LessonItemsTable extends Table {
  TextColumn get id => text()();
  TextColumn get lessonId => text()();
  TextColumn get itemType => text()(); // 'vocabulary' | 'kanji'
  TextColumn get itemId => text()();
  IntColumn get orderIndex => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}
