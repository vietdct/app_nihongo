import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nihongo/shared/motion/animated_progress_bar.dart';
import 'package:nihongo/shared/motion/fade_switcher.dart';
import 'package:nihongo/shared/motion/press_scale.dart';

Widget _app(Widget child, {bool reduceMotion = false}) => MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(disableAnimations: reduceMotion),
        child: Scaffold(body: child),
      ),
    );

double _barValue(WidgetTester tester) => tester
    .widget<LinearProgressIndicator>(find.byType(LinearProgressIndicator))
    .value!;

AnimatedProgressBar _bar(double v) => AnimatedProgressBar(
      value: v,
      minHeight: 6,
      backgroundColor: Colors.grey,
      color: Colors.teal,
    );

void main() {
  group('PressScale', () {
    testWidgets('không chặn onTap của con, chỉ gọi đúng 1 lần', (tester) async {
      var taps = 0;
      await tester.pumpWidget(
        _app(
          PressScale(
            child: InkWell(
              onTap: () => taps++,
              child: const SizedBox(width: 200, height: 80, child: Text('Thẻ')),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Thẻ'));
      await tester.pumpAndSettle();
      expect(taps, 1);
    });

    testWidgets('co lại khi giữ và trở về 1 khi thả', (tester) async {
      await tester.pumpWidget(
        _app(
          const Center(
            child: PressScale(child: SizedBox(width: 200, height: 80)),
          ),
        ),
      );
      double scale() =>
          tester.widget<AnimatedScale>(find.byType(AnimatedScale)).scale;
      expect(scale(), 1);

      final gesture = await tester.startGesture(
        tester.getCenter(find.byType(SizedBox).first),
      );
      await tester.pump(const Duration(milliseconds: 150));
      expect(scale(), lessThan(1));

      await gesture.up();
      await tester.pump();
      expect(scale(), 1);
    });

    testWidgets('kéo cuộn thì thả về kích thước gốc', (tester) async {
      await tester.pumpWidget(
        _app(
          ListView(
            children: [
              const PressScale(child: SizedBox(height: 80, child: Text('A'))),
              for (var i = 0; i < 20; i++) const SizedBox(height: 80),
            ],
          ),
        ),
      );
      double scale() =>
          tester.widget<AnimatedScale>(find.byType(AnimatedScale)).scale;
      final gesture =
          await tester.startGesture(tester.getCenter(find.text('A')));
      await tester.pump(const Duration(milliseconds: 150));
      expect(scale(), lessThan(1));
      await gesture.moveBy(const Offset(0, -60));
      await tester.pump();
      expect(scale(), 1);
      await gesture.up();
    });

    testWidgets('giảm chuyển động hoặc enabled=false: không bọc animation',
        (tester) async {
      await tester.pumpWidget(
        _app(
          const PressScale(child: SizedBox(width: 50, height: 50)),
          reduceMotion: true,
        ),
      );
      expect(find.byType(AnimatedScale), findsNothing);

      await tester.pumpWidget(
        _app(
          const PressScale(
            enabled: false,
            child: SizedBox(width: 50, height: 50),
          ),
        ),
      );
      expect(find.byType(AnimatedScale), findsNothing);
    });
  });

  group('AnimatedProgressBar', () {
    testWidgets('lần đầu hiện thẳng giá trị, không chạy từ 0', (tester) async {
      await tester.pumpWidget(_app(_bar(0.6)));
      expect(_barValue(tester), closeTo(0.6, 1e-9));
    });

    testWidgets('đổi giá trị thì chạy mượt rồi dừng đúng giá trị mới',
        (tester) async {
      await tester.pumpWidget(_app(_bar(0.2)));
      await tester.pumpWidget(_app(_bar(0.8)));
      await tester.pump(const Duration(milliseconds: 100));
      final mid = _barValue(tester);
      expect(mid, greaterThan(0.2));
      expect(mid, lessThan(0.8));
      await tester.pumpAndSettle();
      expect(_barValue(tester), closeTo(0.8, 1e-9));
    });

    testWidgets('rebuild cùng giá trị không chạy lại animation',
        (tester) async {
      await tester.pumpWidget(_app(_bar(0.5)));
      await tester.pumpWidget(_app(_bar(0.5)));
      expect(tester.hasRunningAnimations, isFalse);
      expect(_barValue(tester), closeTo(0.5, 1e-9));
    });

    testWidgets('giá trị ngoài khoảng hoặc NaN được kẹp về 0–1',
        (tester) async {
      await tester.pumpWidget(_app(_bar(1.7)));
      expect(_barValue(tester), 1);
      await tester.pumpWidget(_app(_bar(-0.3)));
      await tester.pumpAndSettle();
      expect(_barValue(tester), 0);
      await tester.pumpWidget(_app(_bar(double.nan)));
      await tester.pumpAndSettle();
      expect(_barValue(tester), 0);
    });

    testWidgets('giảm chuyển động: nhảy thẳng tới giá trị mới', (tester) async {
      await tester.pumpWidget(_app(_bar(0.2), reduceMotion: true));
      await tester.pumpWidget(_app(_bar(0.9), reduceMotion: true));
      await tester.pump();
      expect(_barValue(tester), closeTo(0.9, 1e-9));
    });
  });

  group('FadeSwitcher', () {
    testWidgets(
        'đổi key thì chuyển sang nội dung mới, không nhân đôi sau khi xong',
        (tester) async {
      Widget page(String key, String text) => FadeSwitcher(
            child: Center(key: ValueKey(key), child: Text(text)),
          );
      await tester.pumpWidget(_app(page('a', 'Đang tải')));
      expect(find.text('Đang tải'), findsOneWidget);

      await tester.pumpWidget(_app(page('b', 'Dữ liệu')));
      await tester.pump(const Duration(milliseconds: 80));
      expect(find.text('Đang tải'), findsOneWidget);
      expect(find.text('Dữ liệu'), findsOneWidget);

      await tester.pumpAndSettle();
      expect(find.text('Đang tải'), findsNothing);
      expect(find.text('Dữ liệu'), findsOneWidget);
    });

    testWidgets('cùng key chỉ rebuild thì không chạy animation',
        (tester) async {
      Widget page(String text) => FadeSwitcher(
            child: Center(key: const ValueKey('a'), child: Text(text)),
          );
      await tester.pumpWidget(_app(page('Một')));
      await tester.pumpWidget(_app(page('Hai')));
      expect(tester.hasRunningAnimations, isFalse);
      expect(find.text('Hai'), findsOneWidget);
    });

    testWidgets('giữ ràng buộc của cha: nội dung vẫn đầy chiều cao body',
        (tester) async {
      await tester.pumpWidget(
        _app(
          const FadeSwitcher(
            child: SizedBox.expand(
              key: ValueKey('x'),
              child: ColoredBox(color: Colors.red),
            ),
          ),
        ),
      );
      final size = tester.getSize(find.byType(ColoredBox).last);
      final body = tester.getSize(find.byType(Scaffold));
      expect(size.height, body.height);
      expect(size.width, body.width);
    });

    testWidgets('giảm chuyển động: đổi ngay, không còn nội dung cũ',
        (tester) async {
      Widget page(String key, String text) => FadeSwitcher(
            child: Center(key: ValueKey(key), child: Text(text)),
          );
      await tester.pumpWidget(_app(page('a', 'Cũ'), reduceMotion: true));
      await tester.pumpWidget(_app(page('b', 'Mới'), reduceMotion: true));
      await tester.pump();
      expect(find.text('Cũ'), findsNothing);
      expect(find.text('Mới'), findsOneWidget);
    });
  });
}
