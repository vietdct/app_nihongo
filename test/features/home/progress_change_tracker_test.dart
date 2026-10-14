import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nihongo/core/network/supabase_providers.dart';
import 'package:nihongo/domain/entities/profile.dart';
import 'package:nihongo/features/home/providers/profile_providers.dart';
import 'package:nihongo/features/home/providers/progress_change_providers.dart';
import 'package:nihongo/features/profile/providers/study_heatmap_providers.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Profile _profile(int streak) => Profile(
      displayName: 'A',
      xp: 0,
      streakCount: streak,
      longestStreakCount: streak,
      createdAt: DateTime(2026),
    );

final _d1 = DateTime(2026, 10, 12);
final _d2 = DateTime(2026, 10, 13);
final _d3 = DateTime(2026, 10, 14);

/// Nguồn dữ liệu điều khiển được: mỗi lần đổi `src`, provider thật dựng lại
/// (loading có giá trị cũ → data/error), giống `ref.invalidate` ngoài đời.
final _profileSrc =
    StateProvider<Future<Profile?> Function()>((ref) => () async => null);
final _daysSrc = StateProvider<Future<Set<DateTime>> Function()>(
  (ref) => () async => <DateTime>{},
);
final _userSrc = StateProvider<User?>((ref) => null);

class _Rig {
  _Rig() {
    container = ProviderContainer(
      overrides: [
        currentUserProvider.overrideWith((ref) => ref.watch(_userSrc)),
        // Giống provider thật: phụ thuộc tài khoản nên tải lại khi đổi người.
        profileProvider.overrideWith((ref) {
          ref.watch(_userSrc);
          return ref.watch(_profileSrc)();
        }),
        studyDaysProvider.overrideWith((ref) {
          ref.watch(_userSrc);
          return ref.watch(_daysSrc)();
        }),
      ],
    );
  }

  late final ProviderContainer container;
  late final ProviderSubscription<ProgressEvents> _keep;

  ProgressChangeTracker get tracker =>
      container.read(progressChangeTrackerProvider.notifier);
  ProgressEvents get events => container.read(progressChangeTrackerProvider);

  /// Tạo tracker như khi Home lần đầu dựng (giữ sống cả phiên).
  void start() {
    _keep = container.listen(progressChangeTrackerProvider, (_, __) {});
  }

  Future<void> settle() async {
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);
  }

  Future<void> streak(int v) async {
    container.read(_profileSrc.notifier).state = () async => _profile(v);
    await settle();
  }

  Future<void> streakError() async {
    container.read(_profileSrc.notifier).state =
        () async => throw Exception('mất mạng');
    await settle();
  }

  Future<void> days(Set<DateTime> v) async {
    container.read(_daysSrc.notifier).state = () async => v;
    await settle();
  }

  Future<void> daysError() async {
    container.read(_daysSrc.notifier).state =
        () async => throw Exception('mất mạng');
    await settle();
  }

  void dispose() {
    _keep.close();
    container.dispose();
  }
}

Future<_Rig> _rig({int? streak, Set<DateTime>? days}) async {
  final r = _Rig();
  addTearDown(r.dispose);
  if (streak != null) {
    r.container.read(_profileSrc.notifier).state = () async => _profile(streak);
  }
  if (days != null) {
    r.container.read(_daysSrc.notifier).state = () async => days;
  }
  r.start();
  await r.settle();
  return r;
}

void main() {
  group('Lần tải đầu chỉ tạo baseline', () {
    test('streak 3/7/30 và ngày học có sẵn: không sự kiện', () async {
      for (final v in [3, 7, 30]) {
        final r = await _rig(streak: v, days: {_d1, _d2, _d3});
        expect(r.events.milestone, isNull, reason: 'streak $v');
        expect(r.events.newDays, isEmpty);
      }
    });

    test('loading trước snapshot đầu không tạo baseline giả', () async {
      final r = _Rig();
      addTearDown(r.dispose);
      r.container.read(_profileSrc.notifier).state =
          () => Future<Profile?>.delayed(
                const Duration(milliseconds: 50),
                () => _profile(7),
              );
      r.start();
      await r.settle();
      expect(r.events.milestone, isNull);
      await Future<void>.delayed(const Duration(milliseconds: 80));
      expect(r.events.milestone, isNull); // 7 là baseline, không phải mốc
      await r.streak(8);
      expect(r.events.milestone, isNull);
    });

    test('lỗi trước snapshot đầu rồi thành công: vẫn chỉ baseline', () async {
      final r = _Rig();
      addTearDown(r.dispose);
      r.container.read(_profileSrc.notifier).state =
          () async => throw Exception('x');
      r.container.read(_daysSrc.notifier).state =
          () async => throw Exception('x');
      r.start();
      await r.settle();
      expect(r.events.milestone, isNull);
      expect(r.events.newDays, isEmpty);
      await r.streak(7);
      await r.days({_d1, _d2});
      expect(r.events.milestone, isNull);
      expect(r.events.newDays, isEmpty);
    });
  });

  group('Thay đổi thật giữa hai snapshot thành công', () {
    test('6→7 tạo đúng một mốc 7; lấy rồi không phát lại', () async {
      final r = await _rig(streak: 6);
      await r.streak(7);
      expect(r.events.milestone, 7);
      expect(r.tracker.takeMilestone(), 7);
      expect(r.events.milestone, isNull);
      expect(r.tracker.takeMilestone(), isNull); // listener thứ hai không nhận
      // Refresh cùng giá trị: không sự kiện.
      await r.streak(7);
      await r.streak(7);
      expect(r.events.milestone, isNull);
    });

    test('2→3 và 29→30', () async {
      var r = await _rig(streak: 2);
      await r.streak(3);
      expect(r.events.milestone, 3);
      r = await _rig(streak: 29);
      await r.streak(30);
      expect(r.events.milestone, 30);
    });

    test('3→4 và 7→7 và 6→6 không có mốc', () async {
      final r = await _rig(streak: 3);
      await r.streak(4);
      expect(r.events.milestone, isNull);
      final r2 = await _rig(streak: 7);
      await r2.streak(7);
      expect(r2.events.milestone, isNull);
      final r3 = await _rig(streak: 6);
      await r3.streak(6);
      expect(r3.events.milestone, isNull);
    });

    test('6→8 không suy ra mốc 7; 1→30 không chuỗi mốc giả', () async {
      final r = await _rig(streak: 6);
      await r.streak(8);
      expect(r.events.milestone, isNull);
      final r2 = await _rig(streak: 1);
      await r2.streak(30);
      expect(r2.events.milestone, isNull);
    });

    test('ngày mới xuất hiện tạo đúng một sự kiện; ngày cũ thì không',
        () async {
      final r = await _rig(days: {_d1, _d2});
      await r.days({_d1, _d2, _d3});
      expect(r.events.newDays, {_d3});
      expect(r.tracker.takeNewDays(), {_d3});
      expect(r.events.newDays, isEmpty);
      await r.days({_d1, _d2, _d3}); // refresh cùng dữ liệu
      expect(r.events.newDays, isEmpty);
    });

    test('so sánh theo giá trị ngày: giờ giấc/object khác không tạo ngày mới',
        () async {
      final r = await _rig(days: {_d1});
      await r.days({DateTime(2026, 10, 12, 9, 30)}); // cùng ngày, object khác
      expect(r.events.newDays, isEmpty);
    });

    test('ngày bị xoá không sinh ngày mới; thêm lại sau đó thì là ngày mới',
        () async {
      final r = await _rig(days: {_d1, _d2});
      await r.days({_d1});
      expect(r.events.newDays, isEmpty);
      await r.days({_d1, _d2});
      expect(r.events.newDays, {_d2});
    });

    test('ngày mới KHÔNG suy ra mốc streak (và ngược lại)', () async {
      final r = await _rig(streak: 6, days: {_d1});
      await r.days({_d1, _d2});
      expect(r.events.milestone, isNull);
      await r.streak(7);
      expect(r.events.newDays, {_d2}); // vẫn giữ nguyên, độc lập
      expect(r.events.milestone, 7);
    });

    test(
        'nhiều sự kiện chưa tiêu thụ: ngày gộp, mốc giữ cái mới nhất, bộ '
        'nhớ không tăng vô hạn', () async {
      final r = await _rig(streak: 2, days: {_d1});
      await r.streak(3);
      await r.days({_d1, _d2});
      await r.days({_d1, _d2, _d3});
      expect(r.events.newDays, {_d2, _d3});
      expect(r.events.milestone, 3);
      r.tracker.takeNewDays();
      r.tracker.takeMilestone();
      expect(r.events.newDays, isEmpty);
      expect(r.events.milestone, isNull);
    });
  });

  group('Loading / error / refresh', () {
    test('error giữa hai snapshot: không sự kiện, baseline còn nguyên',
        () async {
      final r = await _rig(streak: 6, days: {_d1});
      await r.streakError();
      await r.daysError();
      expect(r.events.milestone, isNull);
      expect(r.events.newDays, isEmpty);
      // Snapshot thành công sau lỗi so với baseline thành công TRƯỚC lỗi.
      await r.streak(7);
      await r.days({_d1, _d2});
      expect(r.events.milestone, 7);
      expect(r.events.newDays, {_d2});
    });

    test(
        'lỗi refresh không biến baseline thành dữ liệu lỗi: 7, lỗi, 7 → '
        'không sự kiện', () async {
      final r = await _rig(streak: 7);
      await r.streakError();
      await r.streak(7);
      expect(r.events.milestone, isNull);
    });

    test('đang tải lại (còn giá trị cũ) không phải snapshot mới', () async {
      final r = await _rig(streak: 6);
      r.container.read(_profileSrc.notifier).state =
          () => Future<Profile?>.delayed(
                const Duration(milliseconds: 40),
                () => _profile(7),
              );
      await r.settle();
      expect(r.events.milestone, isNull); // chưa có snapshot mới
      await Future<void>.delayed(const Duration(milliseconds: 80));
      expect(r.events.milestone, 7); // đúng 1 lần khi dữ liệu về
    });

    test('profile null (chưa đăng nhập) không phải snapshot', () async {
      final r = _Rig();
      addTearDown(r.dispose);
      r.start();
      await r.settle();
      await r.streak(7);
      expect(r.events.milestone, isNull);
    });
  });

  group('Vòng đời', () {
    test('đổi tài khoản tạo baseline mới (không so sánh chéo người dùng)',
        () async {
      final r = _Rig();
      addTearDown(r.dispose);
      // Người dùng 1 có streak 6, người dùng 2 có streak 7.
      r.container.read(_profileSrc.notifier).state =
          () async => _profile(r.container.read(_userSrc) == null ? 6 : 7);
      r.start();
      await r.settle();
      r.container.read(_userSrc.notifier).state = const User(
        id: 'user-2',
        appMetadata: {},
        userMetadata: {},
        aud: 'a',
        createdAt: '2026-01-01',
      );
      await r.settle();
      // 6 (người cũ) → 7 (người mới) KHÔNG được coi là 6→7 của cùng người.
      expect(r.events.milestone, isNull);
    });

    test('tracker sống qua việc UI dựng lại: baseline không đổi', () async {
      final r = await _rig(streak: 6);
      // "Home dispose/recreate": không động vào tracker, chỉ đọc lại state.
      expect(r.events, ProgressEvents.none);
      await r.streak(7);
      expect(r.events.milestone, 7);
      // Home dựng lại và đọc tiếp: sự kiện chưa tiêu thụ vẫn còn, không nhân
      // đôi; sau khi tiêu thụ thì không quay lại.
      expect(r.events.milestone, 7);
      r.tracker.takeMilestone();
      expect(r.events.milestone, isNull);
    });
  });
}
