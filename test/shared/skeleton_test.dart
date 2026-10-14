import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nihongo/domain/entities/jlpt_level.dart';
import 'package:nihongo/domain/entities/lesson.dart';
import 'package:nihongo/features/lesson/lesson_list_screen.dart';
import 'package:nihongo/features/lesson/providers/content_providers.dart';
import 'package:nihongo/features/lesson/providers/level_providers.dart';
import 'package:nihongo/shared/skeleton.dart';
import 'package:nihongo/shared/skeleton_layouts.dart';
import 'package:nihongo/shared/state_views.dart';

Widget _app(
  Widget child, {
  bool reduce = false,
  Brightness brightness = Brightness.light,
  Size? size,
}) =>
    MaterialApp(
      theme: ThemeData(brightness: brightness),
      home: MediaQuery(
        data: MediaQueryData(
          disableAnimations: reduce,
          size: size ?? const Size(390, 844),
        ),
        child: Scaffold(body: child),
      ),
    );

Color _boxColor(WidgetTester tester) {
  final container = tester.widget<Container>(
    find
        .descendant(
          of: find.byType(SkeletonBox),
          matching: find.byType(Container),
        )
        .first,
  );
  return (container.decoration! as BoxDecoration).color!;
}

void main() {
  group('SkeletonScope / SkeletonBox', () {
    testWidgets('nhấp nhẹ: màu đổi theo thời gian, dùng 1 controller chung',
        (tester) async {
      await tester.pumpWidget(
        _app(
          const SkeletonScope(
            child: Column(
              children: [
                SkeletonBox(width: 80),
                SkeletonBox(width: 120),
                SkeletonBox(width: 60),
              ],
            ),
          ),
        ),
      );
      final c0 = _boxColor(tester);
      await tester.pump(const Duration(milliseconds: 700));
      final c1 = _boxColor(tester);
      expect(c1, isNot(c0));
      expect(tester.hasRunningAnimations, isTrue);
    });

    testWidgets('gỡ skeleton (tải xong): animation dừng hẳn', (tester) async {
      await tester.pumpWidget(
        _app(const SkeletonScope(child: SkeletonBox(width: 80))),
      );
      await tester.pump(const Duration(milliseconds: 300));
      expect(tester.hasRunningAnimations, isTrue);

      await tester.pumpWidget(_app(const Text('Nội dung thật')));
      await tester.pumpAndSettle();
      expect(tester.hasRunningAnimations, isFalse);
      expect(find.byType(SkeletonBox), findsNothing);
    });

    testWidgets('giảm chuyển động: skeleton tĩnh, không animation',
        (tester) async {
      await tester.pumpWidget(
        _app(const SkeletonScope(child: SkeletonBox(width: 80)), reduce: true),
      );
      final c0 = _boxColor(tester);
      await tester.pump(const Duration(milliseconds: 700));
      expect(_boxColor(tester), c0);
      expect(tester.hasRunningAnimations, isFalse);
    });

    testWidgets('đứng ngoài scope: hiện tĩnh', (tester) async {
      await tester.pumpWidget(_app(const SkeletonBox(width: 80)));
      expect(tester.hasRunningAnimations, isFalse);
    });

    testWidgets('màu riêng cho sáng/tối, tối không sáng hơn nền chip',
        (tester) async {
      await tester.pumpWidget(
        _app(const SkeletonBox(width: 80), reduce: true),
      );
      final light = _boxColor(tester);
      await tester.pumpWidget(
        _app(
          const SkeletonBox(width: 80),
          reduce: true,
          brightness: Brightness.dark,
        ),
      );
      await tester.pumpAndSettle(); // chờ theme chuyển xong
      final dark = _boxColor(tester);
      expect(dark, isNot(light));
      expect(dark.computeLuminance(), lessThan(light.computeLuminance()));
      expect(dark.computeLuminance(), lessThan(0.05));
    });

    testWidgets('trình đọc màn hình chỉ có 1 nhãn "Đang tải nội dung"',
        (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _app(
          const SkeletonScope(
            child: Column(
              children: [
                SkeletonBox(width: 80),
                SkeletonBox(width: 120),
              ],
            ),
          ),
          reduce: true,
        ),
      );
      expect(find.bySemanticsLabel('Đang tải nội dung'), findsOneWidget);
      handle.dispose();
    });

    testWidgets('hình tròn và chữ nhật có kích thước đúng', (tester) async {
      await tester.pumpWidget(
        _app(
          const Column(
            children: [
              SkeletonBox(width: 40, height: 40, circle: true),
              SkeletonBox(width: 100, height: 16),
            ],
          ),
        ),
      );
      final sizes = tester
          .widgetList<SkeletonBox>(find.byType(SkeletonBox))
          .map((b) => tester.getSize(find.byWidget(b)))
          .toList();
      expect(sizes, [const Size(40, 40), const Size(100, 16)]);
    });
  });

  group('layout skeleton không overflow', () {
    for (final entry in <String, Widget>{
      'LessonListSkeleton': const LessonListSkeleton(),
      'ListCardSkeleton': const ListCardSkeleton(trailingPill: true),
      'KanjiGridSkeleton': const KanjiGridSkeleton(),
      'SectionedHomeSkeleton': const SectionedHomeSkeleton(),
      'SectionedHomeSkeleton (IT)': const SectionedHomeSkeleton(
        showSearchBar: false,
        cardHeights: [120, 96, 96],
      ),
    }.entries) {
      for (final dark in [false, true]) {
        testWidgets('${entry.key} ${dark ? "tối" : "sáng"} ở iPhone nhỏ 320px',
            (tester) async {
          await tester.pumpWidget(
            _app(
              entry.value,
              brightness: dark ? Brightness.dark : Brightness.light,
              size: const Size(320, 568),
            ),
          );
          await tester.pump(const Duration(milliseconds: 500));
          expect(tester.takeException(), isNull);
          expect(find.byType(CircularProgressIndicator), findsNothing);
        });
      }
    }
  });

  group('LessonListScreen — loading / data / empty / error', () {
    Future<StreamController<List<Lesson>>> pumpScreen(
      WidgetTester tester,
    ) async {
      final controller = StreamController<List<Lesson>>();
      addTearDown(controller.close);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            selectedLevelCodeProvider.overrideWith((ref) => 'N5'),
            // Đồng bộ nền đã xong thành công: để kiểm trạng thái của riêng
            // luồng danh sách (rỗng chỉ được kết luận sau đồng bộ thành công).
            jlptLevelsProvider.overrideWith(
              (ref) async => const [
                JlptLevel(id: 'l5', code: 'N5', title: 'N5', orderIndex: 0),
              ],
            ),
            contentRefreshProvider.overrideWith((ref) async {}),
            lessonsProvider.overrideWith((ref) => controller.stream),
          ],
          child: _app(const LessonListScreen()),
        ),
      );
      return controller;
    }

    testWidgets('đang tải: hiện skeleton, không có vòng xoay', (tester) async {
      await pumpScreen(tester);
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byType(LessonListSkeleton), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('có dữ liệu: skeleton biến mất, hiện nội dung thật',
        (tester) async {
      final c = await pumpScreen(tester);
      c.add(const [
        Lesson(id: 'l1', title: 'Bài 1', levelId: 'x', orderIndex: 1),
      ]);
      await tester.pumpAndSettle();
      expect(find.byType(LessonListSkeleton), findsNothing);
      expect(find.text('Bài 1'), findsOneWidget);
      expect(tester.hasRunningAnimations, isFalse);
    });

    testWidgets('rỗng: hiện trạng thái rỗng, không còn skeleton',
        (tester) async {
      final c = await pumpScreen(tester);
      c.add(const []);
      await tester.pumpAndSettle();
      expect(find.byType(LessonListSkeleton), findsNothing);
      expect(find.textContaining('Chưa có bài học nào'), findsOneWidget);
    });

    testWidgets('lỗi: hiện lỗi (không nhầm thành rỗng), không kẹt skeleton',
        (tester) async {
      final c = await pumpScreen(tester);
      c.addError(Exception('mất kết nối'));
      await tester.pumpAndSettle();
      expect(find.byType(LessonListSkeleton), findsNothing);
      expect(find.byType(ErrorState), findsOneWidget);
      expect(find.textContaining('Exception'), findsNothing);
      expect(find.textContaining('Chưa có bài học nào'), findsNothing);
    });
  });
}
