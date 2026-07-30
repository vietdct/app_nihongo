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
    this.practiceTokens = const [],
    this.practiceBlankIndex,
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

  /// example_jp tách thành từ/cụm có nghĩa, đúng thứ tự — soạn thủ công, xem
  /// migration `20260727040000_grammar_practice_tokens.sql`. Rỗng nếu mẫu
  /// này chưa được soạn cho Practice mở rộng.
  final List<String> practiceTokens;

  /// Index trong [practiceTokens] là từ/trợ từ bị ẩn cho bài điền từ — null
  /// nếu mẫu này dùng cho bài ghép câu thay vì điền từ (hoặc chưa soạn).
  final int? practiceBlankIndex;
}
