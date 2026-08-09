import 'package:supabase_flutter/supabase_flutter.dart';

/// Lưu bước đang dừng lại của 1 phiên học vào `user_lesson_progress` —
/// upsert chỉ set các cột được truyền (last_step_index/total_steps/
/// updated_at), không đụng completed_at đã có sẵn. Gọi mỗi lần qua bước mới
/// trong `LessonRunnerScreen`.
Future<void> saveLessonStepProgress(
  SupabaseClient sb,
  String userId,
  String lessonId,
  int stepIndex,
  int totalSteps,
) async {
  await sb.from('user_lesson_progress').upsert(
    {
      'user_id': userId,
      'lesson_id': lessonId,
      'last_step_index': stepIndex,
      'total_steps': totalSteps,
      'updated_at': DateTime.now().toIso8601String(),
    },
    onConflict: 'user_id,lesson_id',
  );
}

/// Đánh dấu 1 bài đã hoàn thành — gọi khi người dùng bấm "Hoàn thành bài
/// học" ở chặng Review (chặng cuối). Chỉ set completed_at/updated_at, giữ
/// nguyên last_step_index/total_steps đã ghi từ các lần advance trước đó.
Future<void> markLessonCompleted(
  SupabaseClient sb,
  String userId,
  String lessonId,
) async {
  await sb.from('user_lesson_progress').upsert(
    {
      'user_id': userId,
      'lesson_id': lessonId,
      'completed_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    },
    onConflict: 'user_id,lesson_id',
  );
}
