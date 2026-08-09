import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/supabase_providers.dart';
import '../../../domain/entities/lesson.dart';
import '../../../domain/entities/lesson_progress.dart';
import '../../lesson/providers/content_providers.dart';

/// Bài học nên hiện ở "Continue Learning" — bài đầu tiên (theo orderIndex)
/// chưa có completed_at trong `user_lesson_progress`, kèm tiến trình đã lưu
/// nếu có. Khi tất cả bài của cấp độ đã hoàn thành, vẫn trả về bài cuối
/// cùng (đã xong) thay vì null, để thẻ không biến mất đột ngột.
class CurrentLesson {
  const CurrentLesson({required this.lesson, this.progress});

  final Lesson lesson;
  final LessonProgress? progress;
}

final currentLessonProvider =
    FutureProvider.autoDispose<CurrentLesson?>((ref) async {
  final lessons = await ref.watch(lessonsProvider.future);
  if (lessons.isEmpty) return null;
  final sorted = [...lessons]..sort((a, b) => a.orderIndex.compareTo(b.orderIndex));

  final sb = ref.watch(supabaseProvider);
  final userId = ref.watch(currentUserProvider)?.id;
  if (userId == null) return CurrentLesson(lesson: sorted.first);

  final rows = await sb
      .from('user_lesson_progress')
      .select('lesson_id, last_step_index, total_steps, completed_at')
      .eq('user_id', userId)
      .inFilter('lesson_id', [for (final l in sorted) l.id]);

  final progressByLesson = {
    for (final r in rows)
      r['lesson_id'] as String: LessonProgress(
        lastStepIndex: r['last_step_index'] as int,
        totalSteps: r['total_steps'] as int,
        completedAt: r['completed_at'] == null
            ? null
            : DateTime.parse(r['completed_at'] as String),
      ),
  };

  for (final lesson in sorted) {
    final p = progressByLesson[lesson.id];
    if (p == null || !p.isCompleted) {
      return CurrentLesson(lesson: lesson, progress: p);
    }
  }
  return CurrentLesson(lesson: sorted.last, progress: progressByLesson[sorted.last.id]);
});
