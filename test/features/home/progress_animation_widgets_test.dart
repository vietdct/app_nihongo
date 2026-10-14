import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nihongo/core/network/supabase_providers.dart';
import 'package:nihongo/domain/entities/profile.dart';
import 'package:nihongo/features/home/providers/profile_providers.dart';
import 'package:nihongo/features/home/providers/progress_change_providers.dart';
import 'package:nihongo/features/home/widgets/daily_goal_card.dart';
import 'package:nihongo/features/home/widgets/streak_milestone_glow.dart';
import 'package:nihongo/features/profile/providers/study_heatmap_providers.dart';

Profile _profile(int streak) => Profile(
      displayName: 'A',
      xp: 0,
      streakCount: streak,
      longestStreakCount: streak,
      createdAt: DateTime(2026),
    );

final _now = DateTime.now();
final _today = DateTime(_now.year, _now.month, _now.day);
DateTime _day(int offset) => _today.subtract(Duration(days: offset));

final _profileSrc =
    StateProvider<Future<Profile?> Function()>((ref) => () async => null);
final _daysSrc = StateProvider<Future<Set<DateTime>> Function()>(
  (ref) => () async => <DateTime>{},
);

/// Giống Home: lấy ngày học từ provider thật rồi đưa cho thẻ; streak bọc
/// trong viền sáng mốc.
class _HomeLike extends ConsumerWidget {
  const _HomeLike();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final days = ref.watch(studyDaysProvider).valueOrNull;
    final streak = ref.watch(profileProvider).valueOrNull?.streakCount;
    return Column(
      children: [
        StreakMilestoneGlow(child: Text('streak=${streak ?? '–'}')),
        DailyGoalCard(studyDays: days),
      ],
    );
  }
}

class _Rig {
  _Rig({int? streak, Set<DateTime>? days}) {
    container = ProviderContainer(
      overrides: [
        currentUserProvider.overrideWith((ref) => null),
        profileProvider.overrideWith((ref) => ref.watch(_profileSrc)()),
        studyDaysProvider.overrideWith((ref) => ref.watch(_daysSrc)()),
      ],
    );
    if (streak != null) {
      container.read(_profileSrc.notifier).state = () async => _profile(streak);
    }
    if (days != null) {
      container.read(_daysSrc.notifier).state = () async => days;
    }
  }

  late final ProviderContainer container;
  ProgressEvents get events => container.read(progressChangeTrackerProvider);

  void streak(int v) =>
      container.read(_profileSrc.notifier).state = () async => _profile(v);
  void days(Set<DateTime> v) =>
      container.read(_daysSrc.notifier).state = () async => v;
}

Widget _app(
  _Rig rig, {
  required Widget home,
  bool reduce = false,
  Brightness brightness = Brightness.light,
}) =>
    UncontrolledProviderScope(
      container: rig.container,
      child: MaterialApp(
        theme: ThemeData(brightness: brightness),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(disableAnimations: reduce),
          child: child!,
        ),
        home: Scaffold(body: home),
      ),
    );

Future<_Rig> _open(
  WidgetTester tester, {
  int? streak,
  Set<DateTime>? days,
  bool reduce = false,
  Brightness brightness = Brightness.light,
  Widget home = const _HomeLike(),
}) async {
  final rig = _Rig(streak: streak, days: days);
  addTearDown(rig.container.dispose);
  await tester.pumpWidget(
    _app(rig, home: home, reduce: reduce, brightness: brightness),
  );
  await _settleData(tester);
  return rig;
}

/// Cho dữ liệu đi hết chuỗi provider → tracker → widget → post-frame, chưa
/// làm animation tiến (mỗi pump 0ms).
Future<void> _settleData(WidgetTester tester) async {
  for (var i = 0; i < 6; i++) {
    await tester.pump();
  }
}

final _glow = find.byKey(const ValueKey('streak-milestone-glow'));
Finder get _dotFades => find.descendant(
      of: find.byType(DailyGoalCard),
      matching: find.byType(Opacity),
    );

void main() {
  group('Ba tình huống bắt buộc', () {
    testWidgets('1) mở app: streak 7 + lịch có dữ liệu → KHÔNG hiệu ứng',
        (tester) async {
      final rig = await _open(
        tester,
        streak: 7,
        days: {_day(0), _day(1), _day(2)},
      );
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('streak=7'), findsOneWidget);
      expect(_glow, findsNothing);
      expect(_dotFades, findsNothing);
      expect(tester.hasRunningAnimations, isFalse);
      expect(rig.events, ProgressEvents.none);
    });

    testWidgets('2) cùng phiên 6→7: mốc 7 hiện đúng một lần', (tester) async {
      final rig = await _open(tester, streak: 6, days: {_day(1)});
      expect(_glow, findsNothing);

      rig.streak(7);
      await _settleData(tester);
      await tester.pump(const Duration(milliseconds: 150));
      expect(find.text('streak=7'), findsOneWidget);
      expect(_glow, findsOneWidget);
      expect(rig.events.milestone, isNull); // đã tiêu thụ

      await tester.pump(const Duration(milliseconds: 800));
      expect(_glow, findsNothing);
      expect(tester.hasRunningAnimations, isFalse);
    });

    testWidgets('3) refresh / dựng lại / chuyển tab: vẫn 7 → không phát lại',
        (tester) async {
      final rig = await _open(tester, streak: 6, days: {_day(1)});
      rig.streak(7);
      await _settleData(tester);
      await tester.pump(const Duration(milliseconds: 900));
      expect(_glow, findsNothing);

      // Refresh nhiều lần cùng giá trị.
      for (var i = 0; i < 3; i++) {
        rig.streak(7);
        await _settleData(tester);
        await tester.pump(const Duration(milliseconds: 100));
        expect(_glow, findsNothing);
      }
      // Dựng lại toàn bộ Home (dispose/recreate, cùng phiên = cùng container).
      await tester.pumpWidget(_app(rig, home: const SizedBox()));
      await tester.pump();
      await tester.pumpWidget(_app(rig, home: const _HomeLike()));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(_glow, findsNothing);
      expect(tester.hasRunningAnimations, isFalse);
    });
  });

  group('Ngày học mới', () {
    testWidgets('ngày mới animate đúng ô đó một lần, ô cũ không đổi',
        (tester) async {
      final rig = await _open(tester, streak: 3, days: {_day(2), _day(1)});
      expect(_dotFades, findsNothing);

      rig.days({_day(2), _day(1), _day(0)});
      await _settleData(tester);
      await tester.pump(const Duration(milliseconds: 80));
      expect(_dotFades, findsOneWidget); // chỉ 1 ô đang fade
      await tester.pump(const Duration(milliseconds: 400));
      expect(_dotFades, findsNothing);
      expect(tester.hasRunningAnimations, isFalse);
      expect(rig.events.newDays, isEmpty);

      // Refresh cùng dữ liệu: không phát lại.
      rig.days({_day(2), _day(1), _day(0)});
      await _settleData(tester);
      await tester.pump(const Duration(milliseconds: 80));
      expect(_dotFades, findsNothing);
    });

    testWidgets(
        'ngày bị xoá không animate; nhiều ngày mới cùng lúc: mỗi ô '
        'một fade, không controller cho các ô khác', (tester) async {
      final rig = await _open(tester, days: {_day(0), _day(1)});
      rig.days({_day(0)}); // xoá 1 ngày
      await _settleData(tester);
      await tester.pump(const Duration(milliseconds: 80));
      expect(_dotFades, findsNothing);

      rig.days({_day(0), _day(1), _day(2)}); // 2 ngày (1 mới thêm lại + 2)
      await _settleData(tester);
      await tester.pump(const Duration(milliseconds: 80));
      expect(_dotFades, findsNWidgets(2));
      await tester.pump(const Duration(milliseconds: 500));
      expect(_dotFades, findsNothing);
    });
  });

  group('Hiển thị: sự kiện chờ tới khi được nhìn thấy', () {
    Widget tabs(int index) => IndexedStack(
          index: index,
          children: [
            for (var i = 0; i < 2; i++)
              TickerMode(
                enabled: i == index,
                child: i == 0 ? const _HomeLike() : const Text('tab khác'),
              ),
          ],
        );

    testWidgets(
        'đang ở tab khác: không phát, quay lại thì phát đúng một '
        'lần, đi/về tiếp không phát lại', (tester) async {
      final rig = await _open(
        tester,
        streak: 6,
        days: {_day(1)},
        home: tabs(0),
      );
      await tester.pumpWidget(_app(rig, home: tabs(1)));
      await tester.pump();

      rig.streak(7);
      rig.days({_day(1), _day(0)});
      await _settleData(tester);
      await tester.pump(const Duration(milliseconds: 100));
      expect(_glow, findsNothing); // không phát khi đang ẩn
      expect(_dotFades, findsNothing);
      expect(rig.events.milestone, 7); // giữ lại, không mất
      expect(rig.events.newDays, {_day(0)});

      await tester.pumpWidget(_app(rig, home: tabs(0)));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 120));
      expect(_glow, findsOneWidget);
      expect(_dotFades, findsOneWidget);
      expect(rig.events.milestone, isNull);
      expect(rig.events.newDays, isEmpty);
      await tester.pump(const Duration(seconds: 1));
      expect(tester.hasRunningAnimations, isFalse);

      // Đi/về tab nữa: không phát lại.
      await tester.pumpWidget(_app(rig, home: tabs(1)));
      await tester.pump();
      await tester.pumpWidget(_app(rig, home: tabs(0)));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 120));
      expect(_glow, findsNothing);
      expect(_dotFades, findsNothing);
    });

    testWidgets('màn khác đẩy lên che Home: giữ sự kiện, pop về thì phát',
        (tester) async {
      final rig = await _open(tester, streak: 6, days: {_day(1)});
      final navigator = tester.state<NavigatorState>(find.byType(Navigator));
      navigator.push(
        MaterialPageRoute<void>(
          builder: (_) => const Scaffold(body: Text('đè')),
        ),
      );
      await tester.pumpAndSettle();

      rig.streak(7); // VD nộp Mini Test xong khi Home bị che
      await _settleData(tester);
      await tester.pump(const Duration(milliseconds: 100));
      expect(rig.events.milestone, 7); // chưa ai nhìn thấy → chưa tiêu thụ

      navigator.pop();
      await tester.pumpAndSettle(const Duration(milliseconds: 50));
      // Pop xong Home hiển thị lại → phát (hoặc đang phát) đúng một lần.
      expect(rig.events.milestone, isNull);
    });
  });

  group('Giảm chuyển động & theme', () {
    testWidgets(
        'giảm chuyển động: dữ liệu cập nhật, không hiệu ứng, sự kiện '
        'được nhận và không phát lại khi tắt giảm chuyển động', (tester) async {
      final rig = await _open(
        tester,
        streak: 6,
        days: {_day(1)},
        reduce: true,
      );
      rig.streak(7);
      rig.days({_day(1), _day(0)});
      await _settleData(tester);
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('streak=7'), findsOneWidget);
      expect(_glow, findsNothing);
      expect(_dotFades, findsNothing);
      expect(tester.hasRunningAnimations, isFalse);
      expect(rig.events, ProgressEvents.none); // đã nhận, không giữ để phát sau

      await tester.pumpWidget(
        _app(rig, home: const _HomeLike()),
      ); // tắt giảm chuyển động
      await tester.pump(const Duration(milliseconds: 100));
      expect(_glow, findsNothing);
      expect(_dotFades, findsNothing);
    });

    for (final b in Brightness.values) {
      testWidgets('hiệu ứng chạy và hiển thị đúng giá trị ($b)',
          (tester) async {
        final rig = await _open(
          tester,
          streak: 2,
          days: {_day(1)},
          brightness: b,
        );
        rig.streak(3);
        rig.days({_day(1), _day(0)});
        await _settleData(tester);
        await tester.pump(const Duration(milliseconds: 120));
        expect(find.text('streak=3'), findsOneWidget);
        expect(_glow, findsOneWidget);
        expect(_dotFades, findsOneWidget);
        expect(find.text('2/7'), findsOneWidget);
        await tester.pump(const Duration(seconds: 1));
      });
    }
  });
}
