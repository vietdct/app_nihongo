import 'dart:math';

import '../entities/reading_passage.dart';
import 'quiz_generator.dart';

/// Sinh câu hỏi Đọc hiểu từ [ReadingPassage] thật (đoạn văn + câu hỏi đã
/// soạn sẵn) — không sinh nội dung, chỉ xáo trộn thứ tự 4 lựa chọn có sẵn.
/// Giữ nguyên thứ tự đoạn văn → các câu hỏi của đoạn đó (khác
/// `DialogueListeningGenerator` xáo trộn cả tập hội thoại) vì đề thi đọc
/// hiểu thật luôn nhóm mọi câu hỏi của 1 đoạn văn liền nhau, không xen kẽ
/// đoạn khác.
///
/// Tái dùng [QuizQuestion] (qua [QuizQuestion.readingPassageBodyJa]) để
/// không phải xây lại UI/state machine của Exam Runner.
class ReadingQuestionGenerator {
  const ReadingQuestionGenerator({Random? random}) : _random = random;

  final Random? _random;

  List<QuizQuestion> generate({
    required List<ReadingPassage> passages,
    int questionCount = 10,
  }) {
    final rng = _random ?? Random();
    final result = <QuizQuestion>[];

    for (final passage in passages) {
      if (result.length >= questionCount) break;
      for (final q in passage.questions) {
        if (result.length >= questionCount) break;
        if (q.options.length < 2) continue;
        final correctText = q.options[q.correctIndex];
        final shuffled = q.options.toList()..shuffle(rng);
        result.add(
          QuizQuestion(
            promptVi: q.questionJa,
            displayJp: q.questionJa,
            options: shuffled,
            correctIndex: shuffled.indexOf(correctText),
            readingPassageTitle: passage.title,
            readingPassageBodyJa: passage.bodyJa,
          ),
        );
      }
    }

    return result;
  }
}
