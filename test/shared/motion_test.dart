import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nihongo/shared/motion/animated_progress_bar.dart';
import 'package:nihongo/shared/motion/answer_feedback.dart';
import 'package:nihongo/shared/motion/enter_transition.dart';
import 'package:nihongo/shared/motion/fade_switcher.dart';
import 'package:nihongo/shared/motion/playing_indicator.dart';
import 'package:nihongo/shared/motion/press_scale.dart';
import 'package:nihongo/shared/motion/shake_once.dart';

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

  group('ShakeOnce', () {
    Widget host(bool trigger, {bool reduce = false}) => _app(
          Center(
            child: ShakeOnce(
              trigger: trigger,
              child: const SizedBox(width: 100, height: 40),
            ),
          ),
          reduceMotion: reduce,
        );

    testWidgets('chỉ chạy khi trigger bật, rồi dừng và về vị trí cũ',
        (tester) async {
      await tester.pumpWidget(host(false));
      expect(tester.hasRunningAnimations, isFalse);
      final x0 = tester.getTopLeft(find.byType(SizedBox).last).dx;

      await tester.pumpWidget(host(true));
      await tester.pump(const Duration(milliseconds: 60));
      expect(tester.hasRunningAnimations, isTrue);
      expect(tester.getTopLeft(find.byType(SizedBox).last).dx, isNot(x0));

      await tester.pumpAndSettle();
      expect(tester.getTopLeft(find.byType(SizedBox).last).dx, x0);
    });

    testWidgets('rebuild khi trigger vẫn true không rung lại', (tester) async {
      await tester.pumpWidget(host(true));
      await tester.pumpWidget(host(true));
      expect(tester.hasRunningAnimations, isFalse);
    });

    testWidgets('giảm chuyển động: không rung', (tester) async {
      await tester.pumpWidget(host(false, reduce: true));
      await tester.pumpWidget(host(true, reduce: true));
      await tester.pump(const Duration(milliseconds: 60));
      expect(tester.hasRunningAnimations, isFalse);
    });
  });

  group('EnterTransition', () {
    Widget host(String key, {bool reduce = false}) => _app(
          EnterTransition(
            key: ValueKey(key),
            child: const Text('Nội dung'),
          ),
          reduceMotion: reduce,
        );
    double opacity(WidgetTester tester) =>
        tester.widget<Opacity>(find.byType(Opacity)).opacity;

    testWidgets('mới tạo thì fade từ 0 lên 1', (tester) async {
      await tester.pumpWidget(host('a'));
      expect(opacity(tester), lessThan(1));
      await tester.pumpAndSettle();
      expect(opacity(tester), 1);
    });

    testWidgets('đổi key chạy lại, rebuild cùng key thì không', (tester) async {
      await tester.pumpWidget(host('a'));
      await tester.pumpAndSettle();
      await tester.pumpWidget(host('a'));
      expect(tester.hasRunningAnimations, isFalse);
      await tester.pumpWidget(host('b'));
      expect(tester.hasRunningAnimations, isTrue);
      await tester.pumpAndSettle();
      expect(find.text('Nội dung'), findsOneWidget);
    });

    testWidgets('giảm chuyển động: hiện thẳng, không bọc Opacity',
        (tester) async {
      await tester.pumpWidget(host('a', reduce: true));
      expect(find.byType(Opacity), findsNothing);
      expect(find.text('Nội dung'), findsOneWidget);
    });
  });

  group('AnswerOptionFrame / AnswerResultIcon', () {
    testWidgets('không chặn onTap của đáp án', (tester) async {
      var taps = 0;
      await tester.pumpWidget(_app(
        AnswerOptionFrame(
          opacity: 1,
          wrong: false,
          pressable: true,
          child: InkWell(
            onTap: () => taps++,
            child:
                const SizedBox(width: 200, height: 50, child: Text('Đáp án')),
          ),
        ),
      ));
      await tester.tap(find.text('Đáp án'));
      await tester.pumpAndSettle();
      expect(taps, 1);
    });

    testWidgets('icon đúng/sai có nhãn truy cập, không chỉ dựa vào màu',
        (tester) async {
      await tester.pumpWidget(_app(const AnswerResultIcon(correct: true)));
      expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);
      expect(find.bySemanticsLabel('Đáp án đúng'), findsOneWidget);
      await tester.pumpWidget(_app(const AnswerResultIcon(correct: false)));
      expect(find.byIcon(Icons.cancel_rounded), findsOneWidget);
      await tester.pumpAndSettle();
    });
  });

  group('PlayingRing / SwapIcon', () {
    Widget ring(bool active, {bool reduce = false}) => _app(
          Center(
            child: PlayingRing(
              active: active,
              color: Colors.orange,
              child: const SizedBox(width: 60, height: 60),
            ),
          ),
          reduceMotion: reduce,
        );

    testWidgets('đang phát: vòng sóng chạy; hết phát: dừng hẳn (không lặp mãi)',
        (tester) async {
      await tester.pumpWidget(ring(false));
      await tester.pumpAndSettle();
      expect(
          find.byType(IgnorePointer).evaluate().where((e) {
            return e.findAncestorWidgetOfExactType<PlayingRing>() != null;
          }),
          isEmpty);

      await tester.pumpWidget(ring(true));
      await tester.pump(const Duration(milliseconds: 300));
      expect(tester.hasRunningAnimations, isTrue);

      await tester.pumpWidget(ring(false));
      await tester.pumpAndSettle();
      expect(tester.hasRunningAnimations, isFalse);
    });

    testWidgets('giảm chuyển động: vòng tĩnh, không có animation chạy',
        (tester) async {
      await tester.pumpWidget(ring(true, reduce: true));
      await tester.pumpAndSettle();
      expect(tester.hasRunningAnimations, isFalse);
      expect(find.byType(DecoratedBox), findsOneWidget);
    });

    testWidgets('gỡ widget khi đang phát: không còn animation/lỗi',
        (tester) async {
      await tester.pumpWidget(ring(true));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pumpWidget(_app(const SizedBox()));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    testWidgets('SwapIcon đổi icon theo state, tức thì khi giảm chuyển động',
        (tester) async {
      Widget w(IconData i, bool reduce) => _app(
            SwapIcon(icon: i, size: 24, color: Colors.black),
            reduceMotion: reduce,
          );
      await tester.pumpWidget(w(Icons.play_arrow_rounded, true));
      await tester.pumpWidget(w(Icons.pause_rounded, true));
      await tester.pump();
      expect(find.byIcon(Icons.pause_rounded), findsOneWidget);
      expect(find.byIcon(Icons.play_arrow_rounded), findsNothing);

      await tester.pumpWidget(w(Icons.play_arrow_rounded, false));
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.play_arrow_rounded), findsOneWidget);
      expect(find.byIcon(Icons.pause_rounded), findsNothing);
    });
  });
}
