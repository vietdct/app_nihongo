class JlptLevel {
  const JlptLevel({
    required this.id,
    required this.code,
    required this.title,
    required this.orderIndex,
  });

  final String id;
  final String code; // 'N5'..'N1'
  final String title;
  final int orderIndex;
}
