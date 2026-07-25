/// Tiến độ học 1 điểm ngữ pháp của người dùng hiện tại.
/// [isKnown]: null = chưa ôn qua flashcard, true = đã thuộc (vuốt phải),
/// false = chưa thuộc (vuốt trái).
class GrammarProgress {
  const GrammarProgress({
    required this.grammarId,
    this.isKnown,
    this.starred = false,
  });

  final String grammarId;
  final bool? isKnown;
  final bool starred;
}
