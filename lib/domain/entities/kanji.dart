class Kanji {
  const Kanji({
    required this.id,
    required this.character,
    required this.meaningVi,
    required this.levelId,
    this.onyomi = const [],
    this.kunyomi = const [],
    this.strokeCount,
    this.exampleJp,
    this.exampleVi,
    this.hanViet = const [],
    this.mnemonic,
    this.strokeData,
    this.components = const [],
  });

  final String id;
  final String character;
  final String levelId;
  final int? strokeCount;
  final String? exampleJp;
  final String? exampleVi;
  final String? mnemonic;

  /// 1 chữ Hán không chỉ có đúng 1 âm On/Kun/Hán Việt/nghĩa — tuỳ chữ mà có
  /// thể nhiều (VD: 生 có On せい/しょう, Kun い.きる/う.まれる/なま).
  final List<String> onyomi;
  final List<String> kunyomi;
  final List<String> hanViet;
  final List<String> meaningVi;

  /// JSON thô {viewBox, strokes: [...]} — rút gọn từ KanjiVG. Parse bằng
  /// KanjiStrokeData.tryParse() ở tầng UI (giữ domain layer không phụ thuộc
  /// path_drawing).
  final String? strokeData;

  /// Các bộ (component) ghép trực tiếp nên chữ này — dữ liệu IDS thật, xem
  /// migration `20260727020000_kanji_components.sql`. Rỗng nếu chữ này
  /// không có quan hệ ghép-bộ thật với kanji khác đang có trong app.
  final List<String> components;

  String get primaryMeaning => meaningVi.isEmpty ? '' : meaningVi.first;
}
