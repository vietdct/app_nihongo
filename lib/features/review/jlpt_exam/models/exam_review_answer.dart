import '../../../../domain/services/quiz_generator.dart';

/// 1 câu đã làm trong lượt thi — dữ liệu cho màn "Xem lại bài làm"
/// (`ExamReviewScreen`). [selectedIndex] null nghĩa là bỏ trống không trả
/// lời (tính là sai, giống lúc chấm điểm ở `_ExamBodyState._submit()`).
class ExamReviewAnswer {
  const ExamReviewAnswer({required this.question, required this.selectedIndex});

  final QuizQuestion question;
  final int? selectedIndex;

  bool get isCorrect => selectedIndex == question.correctIndex;
}

class ExamReviewSection {
  const ExamReviewSection({required this.type, required this.answers});

  final String type;
  final List<ExamReviewAnswer> answers;
}
