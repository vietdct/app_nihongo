/// Tiến trình học dở của 1 bài — đọc từ `user_lesson_progress`. Nguồn thật
/// duy nhất cho thẻ "Continue Learning" biết nên hiện đúng bài đang học dở
/// (thay vì luôn trỏ về bài đầu tiên của cấp độ).
class LessonProgress {
  const LessonProgress({
    required this.lastStepIndex,
    required this.totalSteps,
    this.completedAt,
  });

  final int lastStepIndex;
  final int totalSteps;
  final DateTime? completedAt;

  bool get isCompleted => completedAt != null;

  /// null khi chưa có bước nào được ghi (totalSteps = 0) — tránh chia 0.
  double? get ratio => totalSteps == 0 ? null : lastStepIndex / totalSteps;
}
