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

  /// Chủ đề để duyệt/lọc (VD: "Mua sắm", "Gia đình") — 1 từ đúng 1 category,
  /// có thể null cho từ chưa được gán (xem migration `vocabulary_category`).
  TextColumn get category => text().nullable()();

  /// Nội dung "mini từ điển" mở rộng — chỉ 1 số từ được biên soạn thủ công,
  /// null/rỗng nghĩa là chưa có (UI ẩn cả section thay vì hiện chỗ trống).
  /// Các cột mảng lưu dạng chuỗi JSON của List&lt;String&gt;, cùng quy ước với
  /// `KanjiTable`/`GrammarPointsTable` — xem migration
  /// `20260811000000_vocabulary_extra_content.sql`.
  TextColumn get commonUsagePattern => text().nullable()();
  TextColumn get commonUsageDesc => text().nullable()();
  TextColumn get commonUsageExamplesJp =>
      text().withDefault(const Constant('[]'))();
  TextColumn get commonUsageExamplesVi =>
      text().withDefault(const Constant('[]'))();
  TextColumn get nuancePoints => text().withDefault(const Constant('[]'))();
  TextColumn get similarWords => text().withDefault(const Constant('[]'))();
  TextColumn get similarWordsMeaningVi =>
      text().withDefault(const Constant('[]'))();
  TextColumn get comparisonWords => text().withDefault(const Constant('[]'))();
  TextColumn get comparisonMainDescs =>
      text().withDefault(const Constant('[]'))();
  TextColumn get comparisonOtherDescs =>
      text().withDefault(const Constant('[]'))();
  TextColumn get commonMistakeNote => text().nullable()();
  TextColumn get commonMistakeSuggestions =>
      text().withDefault(const Constant('[]'))();

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

  /// Ví dụ bổ sung ngoài exampleJp/exampleVi (JSON của List&lt;String&gt;,
  /// song song, ghép theo index) — cùng mẫu với
  /// `GrammarPointsTable.extraExamplesJp/Vi`.
  TextColumn get extraExamplesJp => text().withDefault(const Constant('[]'))();
  TextColumn get extraExamplesVi => text().withDefault(const Constant('[]'))();

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

  /// Các bộ ghép trực tiếp nên chữ này (JSON của List&lt;String&gt;) — xem
  /// migration `20260727020000_kanji_components.sql` để biết nguồn dữ liệu.
  TextColumn get components => text().nullable()();

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

  /// Ví dụ bổ sung ngoài exampleJp/exampleVi, lưu dạng chuỗi JSON của
  /// List&lt;String&gt; (song song, ghép theo index) — xem migration
  /// `20260810100000_grammar_extra_examples.sql`.
  TextColumn get extraExamplesJp => text().nullable()();
  TextColumn get extraExamplesVi => text().nullable()();

  /// Từ/cụm tách sẵn từ example_jp, đúng thứ tự (JSON của List&lt;String&gt;) —
  /// dùng cho Practice mở rộng, xem migration
  /// `20260727040000_grammar_practice_tokens.sql`.
  TextColumn get practiceTokens => text().nullable()();
  IntColumn get practiceBlankIndex => integer().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Mirror của bảng `grammar_meanings` — 1 điểm ngữ pháp có thể nhiều nghĩa,
/// mỗi nghĩa có tối đa 2 ví dụ riêng (examplesJp/examplesVi lưu dạng chuỗi
/// JSON của List&lt;String&gt;, xem migration `20260810110000_grammar_meanings.sql`).
/// Điểm ngữ pháp chưa có dòng nào ở đây (N4/N5 cũ) vẫn hiển thị theo
/// explanation/exampleJp/exampleVi phẳng như trước.
class GrammarMeaningsTable extends Table {
  TextColumn get id => text()();
  TextColumn get grammarPointId => text()();
  IntColumn get orderIndex => integer().withDefault(const Constant(0))();
  TextColumn get meaningVi => text()();
  TextColumn get examplesJp => text().withDefault(const Constant('[]'))();
  TextColumn get examplesVi => text().withDefault(const Constant('[]'))();

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
