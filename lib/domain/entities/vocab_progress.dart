/// Tiến độ học 1 từ vựng của người dùng hiện tại.
/// [isKnown]: null = chưa ôn qua flashcard, true = đã thuộc (vuốt phải),
/// false = chưa thuộc (vuốt trái).
class VocabProgress {
  const VocabProgress({
    required this.vocabId,
    this.isKnown,
    this.starred = false,
  });

  final String vocabId;
  final bool? isKnown;
  final bool starred;
}
