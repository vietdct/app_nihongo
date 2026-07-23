/// Model thuần Dart — không phụ thuộc Drift/Supabase, dùng xuyên suốt domain/presentation.
class Vocabulary {
  const Vocabulary({
    required this.id,
    required this.word,
    required this.reading,
    required this.meaningVi,
    required this.levelId,
    this.partOfSpeech,
    this.exampleJp,
    this.exampleVi,
    this.audioUrl,
  });

  final String id;
  final String word;
  final String reading;
  final String meaningVi;
  final String levelId;
  final String? partOfSpeech;
  final String? exampleJp;
  final String? exampleVi;
  final String? audioUrl;
}
