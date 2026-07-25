/// Tiến độ học 1 chữ Hán của người dùng hiện tại.
/// [isKnown]: null = chưa ôn qua flashcard, true = đã thuộc (vuốt phải),
/// false = chưa thuộc (vuốt trái).
class KanjiProgress {
  const KanjiProgress({
    required this.kanjiId,
    this.isKnown,
    this.starred = false,
  });

  final String kanjiId;
  final bool? isKnown;
  final bool starred;
}
