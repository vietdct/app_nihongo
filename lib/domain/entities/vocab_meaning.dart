/// 1 nghĩa của từ vựng kèm ví dụ minh hoạ riêng. Một [Vocabulary] có thể có
/// nhiều nghĩa (VD: 高い = "đắt" khi nói giá, "cao" khi nói chiều cao).
class VocabMeaning {
  const VocabMeaning({
    required this.meaningVi,
    this.exampleJp,
    this.exampleVi,
  });

  final String meaningVi;
  final String? exampleJp;
  final String? exampleVi;
}
