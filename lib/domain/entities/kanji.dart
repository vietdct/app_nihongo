class Kanji {
  const Kanji({
    required this.id,
    required this.character,
    required this.meaningVi,
    required this.levelId,
    this.onyomi,
    this.kunyomi,
    this.strokeCount,
    this.exampleJp,
    this.exampleVi,
  });

  final String id;
  final String character;
  final String meaningVi;
  final String levelId;
  final String? onyomi;
  final String? kunyomi;
  final int? strokeCount;
  final String? exampleJp;
  final String? exampleVi;
}
