/// 1 cặp điểm ngữ pháp hay bị nhầm với nhau (VD Vています đang làm ↔
/// Vています thói quen). Chỉ là quan hệ liên kết — nội dung hiển thị khi so
/// sánh lấy trực tiếp từ 2 [GrammarPoint] tương ứng, không có field riêng.
class GrammarComparisonPair {
  const GrammarComparisonPair({
    required this.id,
    required this.grammarIdA,
    required this.grammarIdB,
  });

  final String id;
  final String grammarIdA;
  final String grammarIdB;
}
