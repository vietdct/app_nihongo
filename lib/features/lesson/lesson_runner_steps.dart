import '../../domain/entities/lesson.dart';
import '../../domain/services/grammar_practice_generator.dart';
import '../../domain/services/lesson_mission_generator.dart';
import '../../domain/services/quiz_generator.dart';

/// 5 pha của 1 phiên học Lesson — xem bản thiết kế "Lesson Module". Mỗi pha
/// có màu riêng dùng cho [LessonProgressHeader], map thẳng vào màu module đã
/// tồn tại trong app (xem `AppColors.phase*`) để người học không phải học
/// lại ý nghĩa màu mới.
enum LessonPhase { input, understand, practice, apply, review }

String phaseLabel(LessonPhase phase) => switch (phase) {
      LessonPhase.input => 'INPUT',
      LessonPhase.understand => 'UNDERSTAND',
      LessonPhase.practice => 'PRACTICE',
      LessonPhase.apply => 'APPLY',
      LessonPhase.review => 'REVIEW',
    };

sealed class LessonStep {
  const LessonStep();
}

class LessonIntroStep extends LessonStep {
  const LessonIntroStep();
}

class LessonObjectivesStep extends LessonStep {
  const LessonObjectivesStep();
}

class LessonUnderstandStep extends LessonStep {
  const LessonUnderstandStep(this.item);

  final LessonContentItem item;
}

/// Bước nghe hiểu — 1 hội thoại thật + câu hỏi trắc nghiệm đã soạn sẵn
/// (xem `DialogueListeningGenerator`). Transcript ẩn mặc định (luyện nghe
/// trước khi đọc), hiện lại sau khi trả lời để vừa ôn từ vựng vừa đóng vai
/// trò "Reading" — không tách riêng màn Reading vì app chưa có dữ liệu
/// furigana/dịch theo từng câu để làm toggle thật (honest, không bịa).
class LessonListeningStep extends LessonStep {
  const LessonListeningStep(this.question);

  final QuizQuestion question;
}

/// 1 mục luyện tập trong pha Practice — hoặc 1 câu hỏi ôn lại nội dung bài
/// ([LessonQuizPracticeItem], từ `QuizGenerator`) hoặc 1 bài luyện ngữ pháp
/// ([LessonGrammarPracticeItem], từ `GrammarPracticeGenerator`).
sealed class LessonPracticeItem {
  const LessonPracticeItem();
}

class LessonQuizPracticeItem extends LessonPracticeItem {
  const LessonQuizPracticeItem(this.question);

  final QuizQuestion question;
}

class LessonGrammarPracticeItem extends LessonPracticeItem {
  const LessonGrammarPracticeItem(this.exercise);

  final GrammarExercise exercise;
}

class LessonExerciseStep extends LessonStep {
  const LessonExerciseStep(this.item);

  final LessonPracticeItem item;
}

/// Pha Apply — hội thoại AI có mục tiêu (dùng đúng từ vựng/ngữ pháp thật của
/// bài, xem `generateLessonMission`). Vắng mặt (honest-empty) nếu bài không
/// đủ dữ liệu để đặt mục tiêu — xem `buildLessonSteps`.
class LessonMissionStep extends LessonStep {
  const LessonMissionStep(this.mission);

  final LessonMission mission;
}

/// Pha Review — chặng cuối thật của phiên học: ôn lại chính những từ vựng/
/// kanji/ngữ pháp vừa học bằng cơ chế SRS thật (SM-2 rút gọn, xem
/// `srs_scheduler.dart`), tự chấm mức nhớ để tính lịch ôn tiếp theo — cùng
/// cơ chế với `KanjiReviewScreen`/`GrammarReviewScreen`, chỉ khác là hàng đợi
/// khoanh vùng đúng nội dung của bài học này thay vì toàn bộ due-queue của
/// cấp độ. [items] luôn khớp [LessonUnderstandStep] đã xem qua trong bài —
/// không honest-empty riêng vì `buildLessonSteps` đã chặn bài rỗng ở đầu.
class LessonReviewStep extends LessonStep {
  const LessonReviewStep(this.items);

  final List<LessonContentItem> items;
}

LessonPhase phaseOfStep(LessonStep step) => switch (step) {
      LessonIntroStep() || LessonObjectivesStep() => LessonPhase.input,
      LessonUnderstandStep() => LessonPhase.understand,
      LessonListeningStep() || LessonExerciseStep() => LessonPhase.practice,
      LessonMissionStep() => LessonPhase.apply,
      LessonReviewStep() => LessonPhase.review,
    };

/// Xây danh sách bước từ nội dung thật của bài học — bài không có Kanji thì
/// không có bước Kanji, honest-empty (không bước nào) nếu bài chưa có nội
/// dung, khớp với cách `LessonDetailScreen` xử lý bài rỗng hiện tại.
/// [listeningQuestions]/[practiceItems] rỗng (chưa đủ dữ liệu nghe/luyện
/// tập ở cấp độ này) → các bước đó tự vắng mặt, không chặn tiến trình. Tương
/// tự [mission] null (bài thiếu từ vựng hoặc ngữ pháp để đặt mục tiêu) →
/// không có bước Mission Challenge. [reviewItems] mặc định dùng lại [items]
/// (thứ tự học) nếu không truyền riêng — provider truyền bản đã xáo trộn.
List<LessonStep> buildLessonSteps({
  required List<LessonContentItem> items,
  List<QuizQuestion> listeningQuestions = const [],
  List<LessonPracticeItem> practiceItems = const [],
  LessonMission? mission,
  List<LessonContentItem> reviewItems = const [],
}) {
  if (items.isEmpty) return const [];
  return [
    const LessonIntroStep(),
    const LessonObjectivesStep(),
    for (final item in items) LessonUnderstandStep(item),
    for (final q in listeningQuestions) LessonListeningStep(q),
    for (final p in practiceItems) LessonExerciseStep(p),
    if (mission != null) LessonMissionStep(mission),
    LessonReviewStep(reviewItems.isEmpty ? items : reviewItems),
  ];
}
