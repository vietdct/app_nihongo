/// 1 điểm ngữ pháp, kèm nội dung học sâu (lỗi thường gặp/mẹo nhớ/so sánh)
/// ngoài công thức + ví dụ cơ bản.
class GrammarPoint {
  const GrammarPoint({
    required this.id,
    required this.title,
    required this.explanation,
    required this.levelId,
    this.exampleJp,
    this.exampleVi,
    this.commonMistake,
    this.memoryTip,
    this.comparisonNote,
  });

  final String id;
  final String title;
  final String explanation;
  final String levelId;
  final String? exampleJp;
  final String? exampleVi;
  final String? commonMistake;
  final String? memoryTip;
  final String? comparisonNote;
}
