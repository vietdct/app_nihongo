import 'package:flutter_test/flutter_test.dart';
import 'package:nihongo/domain/services/kaiwa_streak.dart';

void main() {
  group('computeKaiwaStreak', () {
    final now = DateTime(2026, 7, 28, 20);

    test('rỗng trả về 0', () {
      expect(computeKaiwaStreak(const [], now: now), 0);
    });

    test('có hoạt động hôm nay và liên tiếp các ngày trước đó', () {
      final activity = [
        DateTime(2026, 7, 28, 9),
        DateTime(2026, 7, 27, 21),
        DateTime(2026, 7, 26, 8),
      ];
      expect(computeKaiwaStreak(activity, now: now), 3);
    });

    test('chưa nói chuyện hôm nay nhưng có hôm qua vẫn còn tính streak', () {
      final activity = [
        DateTime(2026, 7, 27, 21),
        DateTime(2026, 7, 26, 8),
      ];
      expect(computeKaiwaStreak(activity, now: now), 2);
    });

    test('lỡ mất 1 ngày thì streak đứt, chỉ tính từ ngày gần nhất trở về', () {
      final activity = [
        DateTime(2026, 7, 25, 21),
        DateTime(2026, 7, 24, 8),
      ];
      expect(computeKaiwaStreak(activity, now: now), 0);
    });

    test('nhiều mốc thời gian trong cùng 1 ngày chỉ tính 1 ngày', () {
      final activity = [
        DateTime(2026, 7, 28, 8),
        DateTime(2026, 7, 28, 9),
        DateTime(2026, 7, 28, 22),
      ];
      expect(computeKaiwaStreak(activity, now: now), 1);
    });

    test('mốc UTC nhưng đúng thời điểm hiện tại vẫn tính là hôm nay (bug quy đổi múi giờ)', () {
      final rightNowUtc = DateTime.now().toUtc();
      expect(computeKaiwaStreak([rightNowUtc]), 1);
    });
  });
}
