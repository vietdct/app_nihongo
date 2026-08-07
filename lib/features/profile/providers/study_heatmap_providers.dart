import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/supabase_providers.dart';

/// Số tuần hiển thị trên lịch nhiệt (heatmap) ngày học — đủ để thấy xu hướng
/// gần đây trên màn hình điện thoại mà không cần cuộn ngang.
const studyHeatmapWeeks = 12;

/// Ngày Thứ Hai đầu tiên của lưới heatmap (cột đầu tiên) — lưới luôn bắt đầu
/// từ đầu tuần để mỗi cột là 1 tuần trọn vẹn Thứ Hai→Chủ Nhật, kể cả tuần
/// hiện tại (các ngày tương lai trong tuần này đơn giản là không được đánh
/// dấu). Dùng chung giữa provider (phạm vi truy vấn) và widget (bố cục ô).
DateTime studyHeatmapGridStart({DateTime? now}) {
  final today = now ?? DateTime.now();
  final endDate = DateTime(today.year, today.month, today.day);
  final mondayOfCurrentWeek = endDate.subtract(
    Duration(days: endDate.weekday - 1),
  );
  return mondayOfCurrentWeek.subtract(
    const Duration(days: (studyHeatmapWeeks - 1) * 7),
  );
}

/// Tập hợp các ngày (giờ địa phương, đã bỏ giờ/phút/giây) mà người dùng có
/// ít nhất 1 hoạt động thật được ghi vào `study_days` — xem
/// `markStudyDayToday` (domain/services/study_day_log.dart) để biết các
/// điểm ghi log.
final studyDaysProvider = FutureProvider.autoDispose<Set<DateTime>>((
  ref,
) async {
  final sb = ref.watch(supabaseProvider);
  final userId = ref.watch(currentUserProvider)?.id;
  if (userId == null) return {};

  final start = studyHeatmapGridStart();
  final startStr =
      '${start.year.toString().padLeft(4, '0')}-'
      '${start.month.toString().padLeft(2, '0')}-'
      '${start.day.toString().padLeft(2, '0')}';

  final rows = await sb
      .from('study_days')
      .select('study_date')
      .eq('user_id', userId)
      .gte('study_date', startStr);

  return {
    for (final r in rows) DateTime.parse(r['study_date'] as String),
  };
});
