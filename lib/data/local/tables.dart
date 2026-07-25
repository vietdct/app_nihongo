import 'package:drift/drift.dart';

/// Mirror của bảng `vocabulary` trên Supabase — nguồn sự thật cho UI khi offline.
/// Nghĩa + ví dụ nằm ở [VocabularyMeaningsTable] (1 từ có thể nhiều nghĩa).
class VocabularyTable extends Table {
  TextColumn get id => text()();
  TextColumn get word => text()();
  TextColumn get reading => text()();
  TextColumn get partOfSpeech => text().nullable()();
  TextColumn get audioUrl => text().nullable()();
  TextColumn get levelId => text()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Mirror của bảng `vocabulary_meanings` — mỗi từ vựng có 1+ nghĩa, mỗi
/// nghĩa có ví dụ riêng (VD: 高い = "đắt" khi nói giá, "cao" khi nói chiều cao).
class VocabularyMeaningsTable extends Table {
  TextColumn get id => text()();
  TextColumn get vocabularyId => text()();
  IntColumn get orderIndex => integer().withDefault(const Constant(0))();
  TextColumn get meaningVi => text()();
  TextColumn get exampleJp => text().nullable()();
  TextColumn get exampleVi => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Mirror của bảng `kanji`. onyomi/kunyomi/hanViet/meaningVi lưu dạng chuỗi
/// JSON của List&lt;String&gt; — 1 chữ Hán có thể nhiều âm đọc/nghĩa, không
/// chỉ đúng 1 giá trị.
class KanjiTable extends Table {
  TextColumn get id => text()();
  TextColumn get character => text()();
  TextColumn get onyomi => text().nullable()();
  TextColumn get kunyomi => text().nullable()();
  TextColumn get meaningVi => text().nullable()();
  IntColumn get strokeCount => integer().nullable()();
  TextColumn get exampleJp => text().nullable()();
  TextColumn get exampleVi => text().nullable()();
  TextColumn get hanViet => text().nullable()();
  TextColumn get mnemonic => text().nullable()();
  TextColumn get strokeData => text().nullable()();
  TextColumn get levelId => text()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Mirror của bảng `grammar_points`.
class GrammarPointsTable extends Table {
  TextColumn get id => text()();
  TextColumn get title => text()();
  TextColumn get explanation => text()();
  TextColumn get exampleJp => text().nullable()();
  TextColumn get exampleVi => text().nullable()();
  TextColumn get commonMistake => text().nullable()();
  TextColumn get memoryTip => text().nullable()();
  TextColumn get comparisonNote => text().nullable()();
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
/// VocabularyTable, KanjiTable, hoặc GrammarPointsTable tuỳ giá trị itemType).
class LessonItemsTable extends Table {
  TextColumn get id => text()();
  TextColumn get lessonId => text()();
  TextColumn get itemType => text()(); // 'vocabulary' | 'kanji' | 'grammar'
  TextColumn get itemId => text()();
  IntColumn get orderIndex => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}
