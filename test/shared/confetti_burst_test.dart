import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nihongo/shared/motion/confetti_burst.dart';

Widget _app({bool enabled = true, bool reduce = false, VoidCallback? onTap}) =>
    MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(disableAnimations: reduce),
        child: Scaffold(
          body: Stack(
            children: [
              Center(
                child: ElevatedButton(
                  onPressed: onTap,
                  child: const Text('Tiếp tục'),
                ),
              ),
              Positioned.fill(child: ConfettiBurst(enabled: enabled)),
            ],
          ),
        ),
      ),
    );

void main() {
  testWidgets('chạy đúng 1 lần rồi tự biến mất, không lặp khi rebuild',
      (tester) async {
    await tester.pumpWidget(_app());
    await tester.pump(const Duration(milliseconds: 500));
    expect(tester.hasRunningAnimations, isTrue);
    expect(find.byType(Opacity), findsWidgets);

    await tester.pumpAndSettle(const Duration(milliseconds: 100));
    expect(tester.hasRunningAnimations, isFalse);
    expect(find.byType(Opacity), findsNothing);

    await tester.pumpWidget(_app());
    await tester.pump(const Duration(milliseconds: 100));
    expect(tester.hasRunningAnimations, isFalse);
  });

  testWidgets('không chặn chạm: nút bên dưới vẫn bấm được khi đang rơi',
      (tester) async {
    var taps = 0;
    await tester.pumpWidget(_app(onTap: () => taps++));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text('Tiếp tục'));
    expect(taps, 1);
    await tester.pumpAndSettle(const Duration(milliseconds: 100));
  });

  testWidgets('giảm chuyển động hoặc enabled=false: không hiện, không chạy',
      (tester) async {
    await tester.pumpWidget(_app(reduce: true));
    await tester.pump(const Duration(milliseconds: 300));
    expect(tester.hasRunningAnimations, isFalse);
    expect(find.byType(Opacity), findsNothing);

    await tester.pumpWidget(_app(enabled: false));
    await tester.pump(const Duration(milliseconds: 300));
    expect(tester.hasRunningAnimations, isFalse);
    expect(find.byType(Opacity), findsNothing);
  });

  testWidgets('gỡ widget giữa lúc rơi: không lỗi', (tester) async {
    await tester.pumpWidget(_app());
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpWidget(const MaterialApp(home: SizedBox()));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
