import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/supabase_providers.dart';
import '../../../domain/entities/jlpt_level.dart';

/// jlpt_levels là bảng tham chiếu rất nhỏ, hiếm đổi — không cần qua Drift,
/// fetch thẳng từ Supabase là đủ (khác với vocabulary/kanji/lessons vốn
/// nhiều và cần offline). Sắp theo order_index: N5 → N1.
final jlptLevelsProvider = FutureProvider<List<JlptLevel>>((ref) async {
  final supabase = ref.watch(supabaseProvider);
  final rows = await supabase.from('jlpt_levels').select().order('order_index');
  return [
    for (final r in rows)
      JlptLevel(
        id: r['id'] as String,
        code: r['code'] as String,
        title: r['title'] as String,
        orderIndex: r['order_index'] as int,
      ),
  ];
});

/// Cấp độ người dùng đang duyệt (mặc định N5). Đổi giá trị này sẽ tự động
/// làm mới toàn bộ nội dung (bài học/từ vựng/kanji) hiển thị, vì các
/// provider nội dung đều watch currentLevelIdProvider bên dưới.
final selectedLevelCodeProvider = StateProvider<String>((ref) => 'N5');

/// null khi danh sách cấp độ chưa tải xong hoặc mã cấp độ không khớp —
/// UI cần xử lý null bằng trạng thái loading/rỗng, không giả định luôn có giá trị.
final currentLevelIdProvider = Provider<String?>((ref) {
  final levels = ref.watch(jlptLevelsProvider).valueOrNull;
  if (levels == null) return null;
  final code = ref.watch(selectedLevelCodeProvider);
  for (final level in levels) {
    if (level.code == code) return level.id;
  }
  return null;
});
