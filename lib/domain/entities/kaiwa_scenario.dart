/// Tình huống hội thoại (nhà hàng, phỏng vấn, hẹn hò...).
class KaiwaScenario {
  const KaiwaScenario({
    required this.id,
    required this.title,
    required this.glyph,
    required this.category,
    required this.description,
    required this.levelMin,
    required this.systemContext,
    required this.orderIndex,
  });

  final String id;
  final String title;
  final String glyph;
  final String category;
  final String description;
  final String levelMin;
  final String systemContext;
  final int orderIndex;
}
