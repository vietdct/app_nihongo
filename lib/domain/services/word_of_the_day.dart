import '../entities/vocabulary.dart';

/// Chọn 1 từ vựng "hôm nay" — deterministic theo ngày (đổi mỗi ngày, cùng 1
/// từ trong suốt 1 ngày) và cấp độ hiện tại (đổi từ khi đổi cấp độ, không lẫn
/// giữa các cấp), luôn lấy từ chính danh sách [pool] đã có — không bịa từ
/// mới. Tách từ vòng lặp inline cũ ở `home_screen.dart` để dùng lại được ở cả
/// Home lẫn Vocabulary Home và có unit test.
Vocabulary? pickWordOfTheDay({
  required List<Vocabulary> pool,
  required String levelId,
  DateTime? now,
}) {
  if (pool.isEmpty) return null;
  final date = now ?? DateTime.now();
  final dayIndex = date.difference(DateTime(date.year)).inDays;
  final levelSeed = levelId.codeUnits.fold<int>(0, (sum, c) => sum + c);
  final index = (dayIndex + levelSeed) % pool.length;
  return pool[index];
}
