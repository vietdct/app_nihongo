import 'package:supabase_flutter/supabase_flutter.dart';

/// Ghi 1 dòng vào `study_days` cho hôm nay (giờ địa phương) — nguồn dữ liệu
/// cho lịch nhiệt (heatmap) ở Thành tích. Idempotent qua `upsert` +
/// `ignoreDuplicates`, gọi lại nhiều lần trong ngày (mỗi lần mở Home, mỗi
/// lần hoàn thành Mini Test...) không tạo dòng trùng hay lỗi.
Future<void> markStudyDayToday(SupabaseClient sb, String userId) async {
  final today = DateTime.now();
  final dateStr =
      '${today.year.toString().padLeft(4, '0')}-'
      '${today.month.toString().padLeft(2, '0')}-'
      '${today.day.toString().padLeft(2, '0')}';
  await sb.from('study_days').upsert(
    {'user_id': userId, 'study_date': dateStr},
    onConflict: 'user_id,study_date',
    ignoreDuplicates: true,
  );
}
