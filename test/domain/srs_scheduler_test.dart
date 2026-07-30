import 'package:flutter_test/flutter_test.dart';
import 'package:nihongo/domain/services/srs_scheduler.dart';

void main() {
  group('computeNextSchedule', () {
    test('forgot luôn reset interval về 1 ngày dù trước đó dài bao nhiêu', () {
      final result = computeNextSchedule(
        previousIntervalDays: 40,
        previousEaseFactor: 2.6,
        grade: SrsGrade.forgot,
      );

      expect(result.intervalDays, 1);
    });

    test('good luôn tăng interval so với trước (trừ lần ôn đầu tiên)', () {
      final result = computeNextSchedule(
        previousIntervalDays: 6,
        previousEaseFactor: 2.5,
        grade: SrsGrade.good,
      );

      expect(result.intervalDays, greaterThan(6));
    });

    test('hard tăng interval chậm hơn good với cùng dữ liệu đầu vào', () {
      final hard = computeNextSchedule(
        previousIntervalDays: 10,
        previousEaseFactor: 2.5,
        grade: SrsGrade.hard,
      );
      final good = computeNextSchedule(
        previousIntervalDays: 10,
        previousEaseFactor: 2.5,
        grade: SrsGrade.good,
      );

      expect(hard.intervalDays, lessThan(good.intervalDays));
    });

    test('lần ôn đầu tiên (interval null) không chia cho 0, vẫn ra interval hợp lệ', () {
      final result = computeNextSchedule(
        previousIntervalDays: null,
        previousEaseFactor: null,
        grade: SrsGrade.good,
      );

      expect(result.intervalDays, greaterThanOrEqualTo(1));
      expect(result.intervalDays.isFinite, isTrue);
    });

    test('ease luôn nằm trong khoảng [1.3, 3.0] dù chấm forgot liên tục', () {
      double? interval;
      double? ease;
      for (var i = 0; i < 30; i++) {
        final result = computeNextSchedule(
          previousIntervalDays: interval,
          previousEaseFactor: ease,
          grade: SrsGrade.forgot,
        );
        interval = result.intervalDays;
        ease = result.easeFactor;
        expect(ease, greaterThanOrEqualTo(1.3));
        expect(ease, lessThanOrEqualTo(3.0));
      }
    });

    test('ease luôn nằm trong khoảng [1.3, 3.0] dù chấm good liên tục', () {
      double? interval;
      double? ease;
      for (var i = 0; i < 30; i++) {
        final result = computeNextSchedule(
          previousIntervalDays: interval,
          previousEaseFactor: ease,
          grade: SrsGrade.good,
        );
        interval = result.intervalDays;
        ease = result.easeFactor;
        expect(ease, greaterThanOrEqualTo(1.3));
        expect(ease, lessThanOrEqualTo(3.0));
      }
    });

    test('dueAt = now + intervalDays ngày', () {
      final now = DateTime(2026, 1, 1);
      final result = computeNextSchedule(
        previousIntervalDays: null,
        previousEaseFactor: null,
        grade: SrsGrade.good,
        now: now,
      );

      final expectedDue = now.add(Duration(days: result.intervalDays.round()));
      expect(
        result.dueAt.difference(expectedDue).inMinutes.abs(),
        lessThan(2),
      );
    });
  });
}
