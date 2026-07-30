/// 1 lượt thoại trong 1 đoạn hội thoại nghe hiểu — `speaker` chỉ dùng để
/// tách giọng đọc TTS (không hiển thị tên thật, không có audio thu sẵn).
class ListeningTurn {
  const ListeningTurn({required this.speaker, required this.jp});

  final String speaker;
  final String jp;
}

/// 1 bài nghe hiểu kiểu JLPT (Minna no Nihongo): hội thoại 2 người thật,
/// độ dài khác nhau (2-8 lượt thoại tuỳ bài), kèm 1 câu hỏi trắc nghiệm về
/// nội dung — nội dung do người soạn viết tay, không sinh tự động.
class ListeningDialogue {
  const ListeningDialogue({
    required this.id,
    required this.levelId,
    required this.turns,
    required this.questionJa,
    required this.options,
    required this.correctIndex,
  });

  final String id;
  final String levelId;
  final List<ListeningTurn> turns;

  /// Câu hỏi bằng tiếng Nhật (đề bài) — người học luyện đọc/nghe hiểu tiếng
  /// Nhật thật, không phải đọc tiếng Việt rồi chỉ nghe hội thoại tiếng Nhật.
  final String questionJa;
  final List<String> options;
  final int correctIndex;
}
