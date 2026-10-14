import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nihongo/shared/motion/chat_motion.dart';

Widget _host(Widget child, {bool reduce = false}) => MaterialApp(
      builder: (context, c) => MediaQuery(
        data: MediaQuery.of(context).copyWith(disableAnimations: reduce),
        child: c!,
      ),
      home: Scaffold(body: Center(child: child)),
    );

void main() {
  group('ChatEntranceTracker', () {
    testWidgets('tin mới "fresh" trong khung hình đó rồi tự hết',
        (tester) async {
      final t = ChatEntranceTracker();
      t.markFresh(['a']);
      expect(t.isFresh('a'), isTrue);
      await tester.pumpWidget(const SizedBox());
      await tester.pump();
      expect(t.isFresh('a'), isFalse);
    });

    test('alias giữ key cũ cho id mới; id không alias dùng chính nó', () {
      final t = ChatEntranceTracker();
      t.alias('real', 'pending-1');
      expect(t.keyOf('real'), 'pending-1');
      expect(t.keyOf('other'), 'other');
      t.alias('same', 'same');
      expect(t.keyOf('same'), 'same');
    });

    testWidgets('đợt thêm sau không bị xoá bởi callback của đợt trước',
        (tester) async {
      final t = ChatEntranceTracker();
      t.markFresh(['a']);
      await tester.pumpWidget(const SizedBox());
      await tester.pump(); // xoá 'a'
      t.markFresh(['b']);
      expect(t.isFresh('b'), isTrue);
      await tester.pump();
      expect(t.isFresh('b'), isFalse);
    });
  });

  group('MessageEntrance', () {
    testWidgets('animate=true: từ mờ lên rõ trong ~220ms, không bounce',
        (tester) async {
      await tester.pumpWidget(
        _host(
          const MessageEntrance(
            animate: true,
            fromRight: true,
            child: Text('hi'),
          ),
        ),
      );
      double op() => tester.widget<Opacity>(find.byType(Opacity)).opacity;
      expect(op(), 0);
      await tester.pump(const Duration(milliseconds: 110));
      expect(op(), inExclusiveRange(0, 1));
      await tester.pump(const Duration(milliseconds: 150));
      expect(op(), 1);
    });

    testWidgets('animate=false: hiện đủ ngay', (tester) async {
      await tester.pumpWidget(
        _host(
          const MessageEntrance(
            animate: false,
            fromRight: false,
            child: Text('hi'),
          ),
        ),
      );
      expect(tester.widget<Opacity>(find.byType(Opacity)).opacity, 1);
    });

    testWidgets(
        'rebuild với animate đổi sang false giữa chừng không giật '
        'cũng không chạy lại', (tester) async {
      Widget build(bool animate) => _host(
            MessageEntrance(
              key: const ValueKey('k'),
              animate: animate,
              fromRight: true,
              child: const Text('hi'),
            ),
          );
      await tester.pumpWidget(build(true));
      await tester.pump(const Duration(milliseconds: 100));
      final mid = tester.widget<Opacity>(find.byType(Opacity)).opacity;
      await tester.pumpWidget(build(false)); // cờ đã hết ở khung sau
      expect(tester.widget<Opacity>(find.byType(Opacity)).opacity, mid);
      await tester.pump(const Duration(milliseconds: 300));
      expect(tester.widget<Opacity>(find.byType(Opacity)).opacity, 1);
      // Rebuild sau khi xong: đứng yên ở 1.
      await tester.pumpWidget(build(true));
      expect(tester.widget<Opacity>(find.byType(Opacity)).opacity, 1);
    });

    testWidgets('giảm chuyển động: hiện ngay', (tester) async {
      await tester.pumpWidget(
        _host(
          const MessageEntrance(
            animate: true,
            fromRight: true,
            child: Text('hi'),
          ),
          reduce: true,
        ),
      );
      expect(tester.widget<Opacity>(find.byType(Opacity)).opacity, 1);
    });
  });

  group('TypingDots', () {
    testWidgets('chạy khi được dựng, dừng hẳn khi bị gỡ (không rò ticker)',
        (tester) async {
      await tester.pumpWidget(_host(const TypingDots(color: Colors.teal)));
      await tester.pump(const Duration(milliseconds: 200));
      expect(tester.hasRunningAnimations, isTrue);
      expect(find.byKey(const ValueKey('typing-dot-1')), findsOneWidget);
      await tester.pumpWidget(_host(const SizedBox()));
      expect(tester.hasRunningAnimations, isFalse);
    });

    testWidgets('chấm nhấp nháy theo pha (độ đậm đổi theo thời gian)',
        (tester) async {
      await tester.pumpWidget(_host(const TypingDots(color: Colors.teal)));
      Color dot() => ((tester
              .widget<Container>(find.byKey(const ValueKey('typing-dot-0')))
              .decoration!) as BoxDecoration)
          .color!;
      final a = dot();
      await tester.pump(const Duration(milliseconds: 140));
      expect(dot(), isNot(a));
    });

    testWidgets('giảm chuyển động: tĩnh, ba chấm vẫn hiện', (tester) async {
      await tester.pumpWidget(
        _host(const TypingDots(color: Colors.teal), reduce: true),
      );
      await tester.pump(const Duration(milliseconds: 500));
      expect(tester.hasRunningAnimations, isFalse);
      for (var i = 0; i < 3; i++) {
        expect(find.byKey(ValueKey('typing-dot-$i')), findsOneWidget);
      }
    });

    testWidgets('bật giảm chuyển động khi đang chạy thì dừng', (tester) async {
      await tester.pumpWidget(_host(const TypingDots(color: Colors.teal)));
      await tester.pump(const Duration(milliseconds: 100));
      expect(tester.hasRunningAnimations, isTrue);
      await tester.pumpWidget(
        _host(const TypingDots(color: Colors.teal), reduce: true),
      );
      await tester.pump();
      expect(tester.hasRunningAnimations, isFalse);
    });

    testWidgets('có nhãn trợ năng "Đang trả lời"', (tester) async {
      await tester.pumpWidget(_host(const TypingDots(color: Colors.teal)));
      expect(find.bySemanticsLabel('Đang trả lời'), findsOneWidget);
    });
  });
}
