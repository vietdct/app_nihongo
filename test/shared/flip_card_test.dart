import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nihongo/shared/flip_card.dart';

Widget _app({
  Key? cardKey,
  bool reduceMotion = false,
  int rebuild = 0,
}) =>
    MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(disableAnimations: reduceMotion),
        child: Scaffold(
          body: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('rebuild $rebuild'),
                SizedBox(
                  width: 200,
                  height: 120,
                  child: FlipCard(
                    key: cardKey,
                    front: const Center(child: Text('MẶT TRƯỚC')),
                    back: const Center(child: Text('MẶT SAU')),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

/// Góc xoay hiệu dụng của nội dung đang hiển thị (0 = không bị lật/ngược).
double _contentAngle(WidgetTester tester, String text) {
  final rotation = find
      .ancestor(of: find.text(text), matching: find.byType(Transform))
      .evaluate()
      .map((e) => (e.widget as Transform).transform)
      .firstWhere((m) => m.entry(3, 2) != 0);
  // rotateY(a) → m[0][0] = cos(a); chữ không bị ngược khi cos > 0.
  return rotation.entry(0, 0);
}

void main() {
  testWidgets('chạm: lật sang mặt sau rồi về mặt trước; chữ không bị ngược',
      (tester) async {
    await tester.pumpWidget(_app());
    expect(find.text('MẶT TRƯỚC'), findsOneWidget);
    expect(find.text('MẶT SAU'), findsNothing);

    await tester.tap(find.byType(FlipCard));
    await tester.pumpAndSettle();
    expect(find.text('MẶT SAU'), findsOneWidget);
    expect(find.text('MẶT TRƯỚC'), findsNothing);
    expect(_contentAngle(tester, 'MẶT SAU'), closeTo(1, 1e-6));

    await tester.tap(find.byType(FlipCard));
    await tester.pumpAndSettle();
    expect(find.text('MẶT TRƯỚC'), findsOneWidget);
    expect(_contentAngle(tester, 'MẶT TRƯỚC'), closeTo(1, 1e-6));
  });

  testWidgets('giữa lúc lật chỉ có 1 mặt trong cây (không nhân đôi nội dung)',
      (tester) async {
    await tester.pumpWidget(_app());
    await tester.tap(find.byType(FlipCard));
    for (var i = 0; i < 24; i++) {
      await tester.pump(const Duration(milliseconds: 16));
      final shown = find.text('MẶT TRƯỚC').evaluate().length +
          find.text('MẶT SAU').evaluate().length;
      expect(shown, 1);
    }
  });

  testWidgets('parent rebuild khi đang ở mặt sau: giữ nguyên mặt sau',
      (tester) async {
    const key = ValueKey('card-1');
    await tester.pumpWidget(_app(cardKey: key));
    await tester.tap(find.byType(FlipCard));
    await tester.pumpAndSettle();

    await tester.pumpWidget(_app(cardKey: key, rebuild: 1));
    await tester.pumpAndSettle();
    expect(find.text('MẶT SAU'), findsOneWidget);
  });

  testWidgets('đổi key sang thẻ khác: bắt đầu lại ở mặt trước', (tester) async {
    await tester.pumpWidget(_app(cardKey: const ValueKey('card-1')));
    await tester.tap(find.byType(FlipCard));
    await tester.pumpAndSettle();
    expect(find.text('MẶT SAU'), findsOneWidget);

    await tester.pumpWidget(_app(cardKey: const ValueKey('card-2')));
    await tester.pumpAndSettle();
    expect(find.text('MẶT TRƯỚC'), findsOneWidget);
  });

  testWidgets('giảm chuyển động: đổi mặt ngay, không có animation chạy',
      (tester) async {
    await tester.pumpWidget(_app(reduceMotion: true));
    await tester.tap(find.byType(FlipCard));
    await tester.pump();
    expect(find.text('MẶT SAU'), findsOneWidget);
    expect(tester.hasRunningAnimations, isFalse);
  });

  testWidgets('gỡ thẻ giữa lúc đang lật: không lỗi', (tester) async {
    await tester.pumpWidget(_app());
    await tester.tap(find.byType(FlipCard));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pumpWidget(const MaterialApp(home: SizedBox()));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('thẻ có nhãn truy cập dạng nút kèm gợi ý lật', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(_app());
    expect(
      tester.getSemantics(find.byType(FlipCard)),
      matchesSemantics(
        isButton: true,
        hasTapAction: true,
        onTapHint: 'Lật xem mặt sau',
        label: 'MẶT TRƯỚC',
        hasFocusAction: false,
      ),
    );
    handle.dispose();
  });
}
