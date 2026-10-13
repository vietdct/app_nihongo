/// 1 nghĩa của 1 điểm ngữ pháp kèm tối đa 2 ví dụ minh hoạ riêng. 1
/// [GrammarPoint] có thể có nhiều nghĩa (VD: 〜とともに vừa có nghĩa "cùng
/// với" vừa có nghĩa "đồng thời với việc gì").
class GrammarMeaning {
  const GrammarMeaning({
    required this.meaningVi,
    this.examplesJp = const [],
    this.examplesVi = const [],
  });

  final String meaningVi;
  final List<String> examplesJp;
  final List<String> examplesVi;
}
