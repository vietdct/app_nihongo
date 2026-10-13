/// 1 nghĩa của từ vựng kèm ví dụ minh hoạ riêng. Một [Vocabulary] có thể có
/// nhiều nghĩa (VD: 高い = "đắt" khi nói giá, "cao" khi nói chiều cao).
class VocabMeaning {
  const VocabMeaning({
    required this.meaningVi,
    this.exampleJp,
    this.exampleVi,
    this.extraExamplesJp = const [],
    this.extraExamplesVi = const [],
  });

  final String meaningVi;
  final String? exampleJp;
  final String? exampleVi;

  /// Ví dụ bổ sung ngoài exampleJp/exampleVi (song song, ghép theo index) —
  /// cùng mẫu với `GrammarPoint.extraExamplesJp/Vi`.
  final List<String> extraExamplesJp;
  final List<String> extraExamplesVi;

  /// Tất cả cặp ví dụ của nghĩa này (exampleJp/Vi + extra), bỏ qua phần tử
  /// thiếu 1 trong 2 vế.
  List<(String, String?)> get allExamples => [
        if (exampleJp != null) (exampleJp!, exampleVi),
        for (var i = 0; i < extraExamplesJp.length; i++)
          (extraExamplesJp[i], i < extraExamplesVi.length ? extraExamplesVi[i] : null),
      ];
}
