import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nihongo/domain/entities/lesson.dart';
import 'package:nihongo/features/lesson/lesson_list_screen.dart';
import 'package:nihongo/features/lesson/providers/content_providers.dart';
import 'package:nihongo/features/lesson/providers/level_providers.dart';
import 'package:nihongo/shared/motion/stagger.dart';

Widget _app(Widget child, {bool reduce = false}) => MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(
          disableAnimations: reduce,
          size: const Size(390, 844),
        ),
        child: Scaffold(body: child),
      ),
    );

Widget _list(
  int count, {
  Key? groupKey,
  bool active = true,
  int maxItems = 8,
  ScrollController? controller,
}) =>
    StaggerGroup(
      key: groupKey,
      active: active,
      maxItems: maxItems,
      child: ListView.builder(
        controller: controller,
        itemCount: count,
        itemBuilder: (_, i) => StaggerItem(
          index: i,
          child: SizedBox(height: 60, child: Text('Mục $i')),
        ),
      ),
    );

/// Opacity hiệu dụng của mục (1 nếu không được bọc stagger).
double _opacity(WidgetTester tester, int i) {
  final finder = find.ancestor(
    of: find.text('Mục $i'),
    matching: find.byType(Opacity),
  );
  if (finder.evaluate().isEmpty) return 1;
  return tester.widget<Opacity>(finder.first).opacity;
}

bool _wrapped(WidgetTester tester, int i) => find
    .ancestor(of: find.text('Mục $i'), matching: find.byType(Opacity))
    .evaluate()
    .isNotEmpty;

void main() {
  group('StaggerGroup / StaggerItem', () {
    testWidgets('lần đầu: các mục hiện lần lượt từ trên xuống rồi dừng',
        (tester) async {
      await tester.pumpWidget(_app(_list(6)));
      expect(
          [for (var i = 0; i < 6; i++) _opacity(tester, i)], everyElement(0.0));

      await tester.pump(const Duration(milliseconds: 100));
      final mid = [for (var i = 0; i < 6; i++) _opacity(tester, i)];
      // Mục trước luôn hiện rõ hơn hoặc bằng mục sau.
      for (var i = 1; i < mid.length; i++) {
        expect(mid[i - 1], greaterThanOrEqualTo(mid[i]));
      }
      expect(mid.first, greaterThan(0));
      expect(mid.last, lessThan(1));

      await tester.pumpAndSettle();
      expect(
          [for (var i = 0; i < 6; i++) _opacity(tester, i)], everyElement(1.0));
      expect(tester.hasRunningAnimations, isFalse);
    });

    testWidgets('rebuild sau khi xong: không chạy lại, nội dung giữ nguyên',
        (tester) async {
      await tester.pumpWidget(_app(_list(5)));
      await tester.pumpAndSettle();
      for (var n = 0; n < 3; n++) {
        await tester.pumpWidget(_app(_list(5)));
        expect(tester.hasRunningAnimations, isFalse);
        expect(_opacity(tester, 0), 1.0);
      }
    });

    testWidgets('chỉ maxItems mục đầu được bọc; mục còn lại hiện ngay',
        (tester) async {
      await tester.pumpWidget(_app(_list(12, maxItems: 4)));
      await tester.pump();
      for (var i = 0; i < 12; i++) {
        expect(_wrapped(tester, i), i < 4, reason: 'mục $i');
      }
      // Mục ngoài giới hạn không bị ẩn chờ animation.
      expect(_opacity(tester, 7), 1.0);
      await tester.pumpAndSettle();
    });

    testWidgets('cuộn xuống/lên: mục cũ không chạy lại, mục mới hiện ngay',
        (tester) async {
      final controller = ScrollController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(_app(_list(60, controller: controller)));
      await tester.pumpAndSettle();

      controller.jumpTo(1200);
      await tester.pump();
      expect(tester.hasRunningAnimations, isFalse);
      expect(_opacity(tester, 25), 1.0);

      controller.jumpTo(0);
      await tester.pump();
      expect(tester.hasRunningAnimations, isFalse);
      expect(_opacity(tester, 0), 1.0);
    });

    testWidgets('số mục đổi (lọc/gõ tìm kiếm): không chạy lại', (tester) async {
      await tester.pumpWidget(_app(_list(20)));
      await tester.pumpAndSettle();
      await tester.pumpWidget(_app(_list(3)));
      expect(tester.hasRunningAnimations, isFalse);
      expect(_opacity(tester, 1), 1.0);
      await tester.pumpWidget(_app(_list(20)));
      expect(tester.hasRunningAnimations, isFalse);
      expect(_opacity(tester, 5), 1.0);
    });

    testWidgets('rỗng rồi có lại dưới cùng group: không chạy lại',
        (tester) async {
      Widget body(bool empty) => StaggerGroup(
            child: empty
                ? const Center(child: Text('Không có'))
                : ListView(
                    children: [
                      for (var i = 0; i < 4; i++)
                        StaggerItem(index: i, child: Text('Mục $i')),
                    ],
                  ),
          );
      await tester.pumpWidget(_app(body(false)));
      await tester.pumpAndSettle();
      await tester.pumpWidget(_app(body(true)));
      await tester.pumpWidget(_app(body(false)));
      expect(tester.hasRunningAnimations, isFalse);
      expect(_opacity(tester, 0), 1.0);
    });

    testWidgets('active=false chưa chạy, lần đầu true mới chạy đúng 1 lần',
        (tester) async {
      await tester.pumpWidget(_app(_list(3, active: false)));
      await tester.pump(const Duration(seconds: 1));
      expect(tester.hasRunningAnimations, isFalse);
      expect(_opacity(tester, 0), 0.0);

      await tester.pumpWidget(_app(_list(3)));
      await tester.pump(const Duration(milliseconds: 100));
      expect(tester.hasRunningAnimations, isTrue);
      await tester.pumpAndSettle();
      expect(_opacity(tester, 2), 1.0);

      // false → true lần nữa: không chạy lại.
      await tester.pumpWidget(_app(_list(3, active: false)));
      await tester.pumpWidget(_app(_list(3)));
      expect(tester.hasRunningAnimations, isFalse);
      expect(_opacity(tester, 0), 1.0);
    });

    testWidgets('dataset mới (key mới): chạy lượt mới, không dùng state cũ',
        (tester) async {
      await tester.pumpWidget(_app(_list(4, groupKey: const ValueKey('N5'))));
      await tester.pumpAndSettle();
      await tester.pumpWidget(_app(_list(4, groupKey: const ValueKey('N4'))));
      await tester.pump();
      expect(_opacity(tester, 0), 0.0);
      await tester.pumpAndSettle();
      expect(_opacity(tester, 3), 1.0);
    });

    testWidgets('giảm chuyển động: hiện ngay, không delay, không animation',
        (tester) async {
      await tester.pumpWidget(_app(_list(6), reduce: true));
      expect(
          [for (var i = 0; i < 6; i++) _opacity(tester, i)], everyElement(1.0));
      expect(tester.hasRunningAnimations, isFalse);
    });

    testWidgets('mục vẫn bấm được khi đang animate', (tester) async {
      var taps = 0;
      await tester.pumpWidget(
        _app(
          StaggerGroup(
            child: ListView(
              children: [
                StaggerItem(
                  index: 0,
                  child: ElevatedButton(
                    onPressed: () => taps++,
                    child: const Text('Mở bài'),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 30));
      await tester.tap(find.text('Mở bài'));
      expect(taps, 1);
      await tester.pumpAndSettle();
    });

    testWidgets('gỡ giữa lúc đang chạy: không lỗi, không animation kẹt',
        (tester) async {
      await tester.pumpWidget(_app(_list(6)));
      await tester.pump(const Duration(milliseconds: 80));
      await tester.pumpWidget(_app(const SizedBox()));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(tester.hasRunningAnimations, isFalse);
    });

    testWidgets('mục ngoài group: hiện bình thường', (tester) async {
      await tester.pumpWidget(
        _app(const StaggerItem(index: 0, child: Text('Mục 0'))),
      );
      expect(find.byType(Opacity), findsNothing);
      expect(find.text('Mục 0'), findsOneWidget);
    });
  });

  group('LessonListScreen — stagger', () {
    Future<StreamController<List<Lesson>>> open(
      WidgetTester tester, {
      bool reduce = false,
    }) async {
      final controller = StreamController<List<Lesson>>();
      addTearDown(controller.close);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            selectedLevelCodeProvider.overrideWith((ref) => 'N5'),
            lessonsProvider.overrideWith((ref) => controller.stream),
          ],
          child: _app(const LessonListScreen(), reduce: reduce),
        ),
      );
      return controller;
    }

    final lessons = [
      for (var i = 1; i <= 12; i++)
        Lesson(id: 'l$i', title: 'Bài $i', levelId: 'x', orderIndex: i),
    ];

    testWidgets('dữ liệu về: chỉ 8 bài đầu animate, thứ tự giữ nguyên',
        (tester) async {
      final c = await open(tester);
      c.add(lessons);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 60));
      expect(tester.hasRunningAnimations, isTrue);

      final animated = find
          .descendant(
            of: find.byType(ListView),
            matching: find.byType(Opacity),
          )
          .evaluate()
          .length;
      expect(animated, lessThanOrEqualTo(8));

      await tester.pumpAndSettle();
      final dy = [
        for (var i = 1; i <= 5; i++) tester.getTopLeft(find.text('Bài $i')).dy,
      ];
      expect(dy, [...dy]..sort());
    });

    testWidgets('stream phát lại cùng dữ liệu: không chạy lại stagger',
        (tester) async {
      final c = await open(tester);
      c.add(lessons);
      await tester.pumpAndSettle();
      c.add(lessons);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      expect(tester.hasRunningAnimations, isFalse);
      expect(find.text('Bài 1'), findsOneWidget);
    });

    testWidgets('giảm chuyển động: hiện ngay', (tester) async {
      final c = await open(tester, reduce: true);
      c.add(lessons);
      await tester.pump();
      await tester.pump();
      expect(tester.hasRunningAnimations, isFalse);
      expect(find.text('Bài 1'), findsOneWidget);
      final op = tester.widget<Opacity>(
        find
            .ancestor(of: find.text('Bài 1'), matching: find.byType(Opacity))
            .first,
      );
      expect(op.opacity, 1.0);
    });
  });
}
