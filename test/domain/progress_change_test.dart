import 'package:flutter_test/flutter_test.dart';
import 'package:nihongo/domain/services/progress_change.dart';

void main() {
  group('streakMilestoneReached', () {
    test('2→3, 6→7, 29→30 là mốc vừa đạt', () {
      expect(streakMilestoneReached(2, 3), 3);
      expect(streakMilestoneReached(6, 7), 7);
      expect(streakMilestoneReached(29, 30), 30);
    });

    test('không phải mốc: 3→4, 0→1, 7→8, 8→9', () {
      expect(streakMilestoneReached(3, 4), isNull);
      expect(streakMilestoneReached(0, 1), isNull);
      expect(streakMilestoneReached(7, 8), isNull);
      expect(streakMilestoneReached(8, 9), isNull);
    });

    test('baseline (chưa có snapshot trước) không bao giờ là mốc', () {
      for (final v in [3, 7, 30]) {
        expect(streakMilestoneReached(null, v), isNull);
      }
    });

    test('giữ nguyên hoặc giảm không phải mốc', () {
      expect(streakMilestoneReached(7, 7), isNull);
      expect(streakMilestoneReached(6, 6), isNull);
      expect(streakMilestoneReached(8, 7), isNull);
      expect(streakMilestoneReached(30, 3), isNull);
    });

    test('nhảy cóc không suy ra mốc trung gian: 6→8, 2→7, 1→30, 0→3', () {
      expect(streakMilestoneReached(6, 8), isNull);
      expect(streakMilestoneReached(2, 7), isNull);
      expect(streakMilestoneReached(1, 30), isNull);
      expect(streakMilestoneReached(0, 3), isNull);
    });

    test('chỉ hỗ trợ 3/7/30', () {
      expect(streakMilestones, {3, 7, 30});
      for (final v in [1, 2, 4, 5, 6, 10, 14, 21, 29, 31, 100]) {
        expect(streakMilestoneReached(v - 1, v), isNull, reason: '$v');
      }
    });
  });

  group('study days', () {
    test('chuẩn hoá về ngày, bỏ giờ phút và trùng lặp', () {
      final days = normalizeStudyDays([
        DateTime(2026, 10, 14),
        DateTime(2026, 10, 14, 15, 30),
        DateTime(2026, 10, 15, 0, 0, 1),
      ]);
      expect(days, {DateTime(2026, 10, 14), DateTime(2026, 10, 15)});
    });

    test('ngày mới = có ở snapshot sau, chưa có ở snapshot trước', () {
      final a = {DateTime(2026, 10, 13), DateTime(2026, 10, 14)};
      final b = {
        DateTime(2026, 10, 13),
        DateTime(2026, 10, 14),
        DateTime(2026, 10, 15),
      };
      expect(newStudyDays(a, b), {DateTime(2026, 10, 15)});
      expect(newStudyDays(b, b), isEmpty);
    });

    test('ngày bị xoá không sinh ngày mới', () {
      final a = {DateTime(2026, 10, 13), DateTime(2026, 10, 14)};
      final b = {DateTime(2026, 10, 13)};
      expect(newStudyDays(a, b), isEmpty);
    });
  });
}
