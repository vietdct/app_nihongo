/// 1 câu hỏi trắc nghiệm về nội dung [ReadingPassage] — nhiều câu hỏi có
/// thể cùng thuộc 1 đoạn văn (khác `ListeningDialogue`: 1 hội thoại chỉ có
/// đúng 1 câu hỏi).
class ReadingPassageQuestion {
  const ReadingPassageQuestion({
    required this.questionJa,
    required this.options,
    required this.correctIndex,
  });

  final String questionJa;
  final List<String> options;
  final int correctIndex;
}

/// 1 đoạn văn đọc hiểu kiểu JLPT — nội dung do người soạn viết tay
/// (docs/JLPT_MOCK_EXAM_DESIGN.md §8, §20), không sinh tự động cho Full
/// Exam/Mini Test.
class ReadingPassage {
  const ReadingPassage({
    required this.id,
    required this.levelId,
    required this.title,
    required this.bodyJa,
    required this.questions,
  });

  final String id;
  final String levelId;
  final String title;
  final String bodyJa;
  final List<ReadingPassageQuestion> questions;
}
