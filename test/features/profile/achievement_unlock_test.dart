import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nihongo/core/network/supabase_providers.dart';
import 'package:nihongo/domain/entities/profile.dart';
import 'package:nihongo/domain/entities/treasure_box.dart';
import 'package:nihongo/features/home/providers/profile_providers.dart';
import 'package:nihongo/features/kaiwa/providers/kaiwa_conversation_providers.dart';
import 'package:nihongo/features/kanji/providers/kanji_progress_providers.dart';
import 'package:nihongo/features/profile/pages/achievements_screen.dart';
import 'package:nihongo/features/profile/providers/achievements_providers.dart';
import 'package:nihongo/features/profile/providers/study_heatmap_providers.dart';
import 'package:nihongo/features/profile/providers/treasure_box_providers.dart';
import 'package:nihongo/features/profile/widgets/achievement_badge.dart';
import 'package:nihongo/features/vocabulary/providers/vocab_progress_providers.dart';

Profile _profile({int xp = 0, int longest = 0}) => Profile(
      displayName: 'Test',
      xp: xp,
      streakCount: 1,
      longestStreakCount: longest,
      createdAt: DateTime(2026, 1, 1),
    );

const _xp500 = 'Kinh nghiệm:500 XP';
const _streak7 = 'Chuỗi học:7 ngày';

/// Nguồn dữ liệu giả cho 4 provider mà huy hiệu phụ thuộc; đổi giá trị rồi
/// `invalidate` để mô phỏng "profile tải lại sau khi làm quiz".
class _Env {
  Profile? profile = _profile();
  Completer<void>? kaiwaGate;

  ProviderContainer build() => ProviderContainer(
        overrides: [
          currentUserProvider.overrideWithValue(null),
          profileProvider.overrideWith((ref) async => profile),
          vocabProgressProvider.overrideWith((ref) async => const {}),
          kanjiProgressProvider.overrideWith((ref) async => const {}),
          studyDaysProvider.overrideWith((ref) async => <DateTime>{}),
          treasureBoxesProvider.overrideWith((ref) async => <TreasureBox>[]),
          kaiwaConversationsProvider.overrideWith((ref) async {
            await kaiwaGate?.future;
            return const [];
          }),
        ],
      );
}

Future<void> _settle() async {
  for (var i = 0; i < 6; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

void main() {
  late _Env env;
  late ProviderContainer container;

  Set<String> pending() => container.read(achievementUnlockTrackerProvider);

  Future<void> start() async {
    container = env.build();
    addTearDown(container.dispose);
    container.listen(achievementUnlockTrackerProvider, (_, __) {});
    await _settle();
  }

  Future<void> reload() async {
    container.invalidate(profileProvider);
    await _settle();
  }

  setUp(() => env = _Env());

  group('AchievementUnlockTracker', () {
    test('huy hiệu đã đạt từ trước (lần tải đầu) không bị coi là mới',
        () async {
      env.profile = _profile(xp: 900, longest: 10);
      await start();
      expect(pending(), isEmpty);
      await reload();
      expect(pending(), isEmpty);
    });

    test('đang tải rồi tải xong không phải sự kiện mở khóa', () async {
      env.profile = _profile(xp: 900);
      env.kaiwaGate = Completer<void>();
      await start();
      expect(container.read(loadedAchievementsProvider), isNull);
      expect(pending(), isEmpty);
      env.kaiwaGate!.complete();
      await _settle();
      expect(container.read(loadedAchievementsProvider), isNotNull);
      expect(pending(), isEmpty);
    });

    test('vượt ngưỡng sau lần tải đầy đủ đầu: báo đúng huy hiệu mới', () async {
      env.profile = _profile(xp: 480);
      await start();
      expect(pending(), isEmpty);

      env.profile = _profile(xp: 520);
      await reload();
      expect(pending(), {_xp500});
    });

    test('tải lại cùng dữ liệu / tụt rồi lên lại không báo lặp', () async {
      env.profile = _profile(xp: 480);
      await start();
      env.profile = _profile(xp: 520);
      await reload();
      container
          .read(achievementUnlockTrackerProvider.notifier)
          .consume([_xp500]);
      expect(pending(), isEmpty);

      await reload();
      expect(pending(), isEmpty);

      env.profile = _profile(xp: 100);
      await reload();
      env.profile = _profile(xp: 520);
      await reload();
      expect(pending(), isEmpty);
    });

    test('nhiều huy hiệu cùng lúc; consume chỉ bỏ các id đã xem', () async {
      env.profile = _profile(xp: 480, longest: 3);
      await start();
      env.profile = _profile(xp: 520, longest: 7);
      await reload();
      expect(pending(), {_xp500, _streak7});

      container
          .read(achievementUnlockTrackerProvider.notifier)
          .consume([_xp500]);
      expect(pending(), {_streak7});
    });

    test('chưa đăng nhập / chưa có profile: không có snapshot, không báo',
        () async {
      env.profile = null;
      await start();
      expect(container.read(loadedAchievementsProvider), isNull);
      expect(pending(), isEmpty);
    });

    test('không đổi điều kiện: buildAchievements giữ đúng ngưỡng cũ', () {
      final a = buildAchievements(
        longestStreak: 7,
        xp: 500,
        knownVocab: 50,
        knownKanji: 10,
        hasKaiwa: true,
      );
      expect(a.where((x) => x.earned).length, 5);
      final none = buildAchievements(
        longestStreak: 6,
        xp: 499,
        knownVocab: 49,
        knownKanji: 9,
        hasKaiwa: false,
      );
      expect(none.where((x) => x.earned), isEmpty);
    });
  });

  group('AchievementBadge', () {
    Widget badge({required bool earned, required bool celebrate}) =>
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: AchievementBadge(
                earned: earned,
                celebrate: celebrate,
                icon: Icons.bolt_rounded,
                label: '500 XP',
                sub: 'Kinh nghiệm',
              ),
            ),
          ),
        );

    testWidgets('celebrate + đã đạt: chạy 1 lần rồi dừng, rebuild không lặp',
        (tester) async {
      await tester.pumpWidget(badge(earned: true, celebrate: true));
      await tester.pump(const Duration(milliseconds: 200));
      expect(tester.hasRunningAnimations, isTrue);
      await tester.pumpAndSettle();
      expect(tester.hasRunningAnimations, isFalse);

      await tester.pumpWidget(badge(earned: true, celebrate: true));
      await tester.pumpWidget(badge(earned: true, celebrate: false));
      await tester.pumpWidget(badge(earned: true, celebrate: true));
      expect(tester.hasRunningAnimations, isFalse);
    });

    testWidgets('không celebrate hoặc chưa đạt: không animation',
        (tester) async {
      await tester.pumpWidget(badge(earned: true, celebrate: false));
      expect(tester.hasRunningAnimations, isFalse);
      await tester.pumpWidget(badge(earned: false, celebrate: true));
      expect(tester.hasRunningAnimations, isFalse);
    });

    testWidgets('celebrate chờ dữ liệu: chạy khi earned chuyển false → true',
        (tester) async {
      await tester.pumpWidget(badge(earned: false, celebrate: true));
      expect(tester.hasRunningAnimations, isFalse);
      await tester.pumpWidget(badge(earned: true, celebrate: true));
      await tester.pump(const Duration(milliseconds: 200));
      expect(tester.hasRunningAnimations, isTrue);
      await tester.pumpAndSettle();
    });

    testWidgets('giảm chuyển động: không animation', (tester) async {
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: badge(earned: true, celebrate: true),
        ),
      );
      expect(tester.hasRunningAnimations, isFalse);
    });
  });

  group('AchievementsScreen', () {
    Widget screen(ProviderContainer c, Key key) => UncontrolledProviderScope(
          container: c,
          child: MaterialApp(home: AchievementsScreen(key: key)),
        );

    testWidgets(
        'huy hiệu vừa mở khóa nảy 1 lần rồi được đánh dấu đã xem; mở lại không lặp',
        (tester) async {
      env.profile = _profile(xp: 480);
      final c = env.build();
      addTearDown(c.dispose);
      c.listen(achievementUnlockTrackerProvider, (_, __) {});

      await tester.pumpWidget(screen(c, const ValueKey('a')));
      await tester.pumpAndSettle();
      expect(tester.hasRunningAnimations, isFalse);

      // Làm quiz xong → profile tải lại với XP vượt 500.
      env.profile = _profile(xp: 520);
      c.invalidate(profileProvider);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pump(const Duration(milliseconds: 200));
      expect(tester.hasRunningAnimations, isTrue);
      await tester.pumpAndSettle();
      expect(tester.hasRunningAnimations, isFalse);
      expect(c.read(achievementUnlockTrackerProvider), isEmpty);

      // Rời rồi mở lại màn Thành tích: không có gì để ăn mừng nữa.
      await tester.pumpWidget(screen(c, const ValueKey('b')));
      await tester.pump(const Duration(milliseconds: 200));
      expect(tester.hasRunningAnimations, isFalse);
    });

    testWidgets('mở màn khi huy hiệu đã đạt từ trước: không hiệu ứng',
        (tester) async {
      env.profile = _profile(xp: 900, longest: 10);
      final c = env.build();
      addTearDown(c.dispose);
      await tester.pumpWidget(screen(c, const ValueKey('a')));
      await tester.pump(const Duration(milliseconds: 300));
      expect(tester.hasRunningAnimations, isFalse);
      expect(c.read(achievementUnlockTrackerProvider), isEmpty);
    });
  });
}
