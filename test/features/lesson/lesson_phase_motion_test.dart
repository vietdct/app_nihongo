import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nihongo/features/lesson/lesson_runner_steps.dart';
import 'package:nihongo/features/lesson/widgets/lesson_phase_complete_sheet.dart';
import 'package:nihongo/features/lesson/widgets/lesson_progress_header.dart';

Widget _header(LessonPhase phase, {bool reduce = false}) => MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(disableAnimations: reduce),
        child: Scaffold(
          body: LessonProgressHeader(currentPhase: phase, onBack: () {}),
        ),
      ),
    );

Widget _sheetHost({bool reduce = false, void Function(bool?)? onResult}) =>
    MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(disableAnimations: reduce),
        child: Scaffold(
          body: Builder(
            builder: (context) => Center(
              child: ElevatedButton(
                onPressed: () async {
                  final r = await showPhaseCompleteSheet(
                    context,
                    done: LessonPhase.understand,
                    next: LessonPhase.practice,
                    lines: const ['Đã xem 3 thẻ', 'Từ vựng: 3'],
                  );
                  onResult?.call(r);
                },
                child: const Text('Mở'),
              ),
            ),
          ),
        ),
      ),
    );

void main() {
  group('LessonProgressHeader', () {
    testWidgets(
        'đổi pha: nhãn chuyển sang pha mới, chỉ còn 1 nhãn sau khi xong',
        (tester) async {
      await tester.pumpWidget(_header(LessonPhase.input));
      expect(find.text('1/5 · INPUT'), findsOneWidget);

      await tester.pumpWidget(_header(LessonPhase.understand));
      await tester.pump(const Duration(milliseconds: 100));
      // Đang chuyển: nhãn cũ mờ dần, nhãn mới hiện dần.
      expect(find.text('2/5 · UNDERSTAND'), findsOneWidget);
      await tester.pumpAndSettle();
      expect(find.text('1/5 · INPUT'), findsNothing);
      expect(find.text('2/5 · UNDERSTAND'), findsOneWidget);
    });

    testWidgets('rebuild cùng pha: không chạy animation', (tester) async {
      await tester.pumpWidget(_header(LessonPhase.practice));
      await tester.pumpAndSettle();
      await tester.pumpWidget(_header(LessonPhase.practice));
      expect(tester.hasRunningAnimations, isFalse);
    });

    testWidgets('giảm chuyển động: đổi pha ngay, không animation',
        (tester) async {
      await tester.pumpWidget(_header(LessonPhase.input, reduce: true));
      await tester.pumpWidget(_header(LessonPhase.apply, reduce: true));
      await tester.pump();
      expect(find.text('4/5 · APPLY'), findsOneWidget);
      expect(find.text('1/5 · INPUT'), findsNothing);
      expect(tester.hasRunningAnimations, isFalse);
    });
  });

  group('showPhaseCompleteSheet', () {
    testWidgets('mở sheet: check nảy 1 lần rồi dừng; nút sang pha kế trả true',
        (tester) async {
      bool? result;
      await tester.pumpWidget(_sheetHost(onResult: (r) => result = r));
      await tester.tap(find.text('Mở'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 150));
      expect(find.text('UNDERSTAND HOÀN THÀNH'), findsOneWidget);
      expect(find.text('Đã xem 3 thẻ'), findsOneWidget);
      await tester.pumpAndSettle();
      expect(tester.hasRunningAnimations, isFalse);

      await tester.tap(find.text('Sang PRACTICE →'));
      await tester.pumpAndSettle();
      expect(result, isTrue);
    });

    testWidgets('đóng sheet không chọn sang pha: trả null, không đổi gì',
        (tester) async {
      bool? result = true;
      await tester.pumpWidget(_sheetHost(onResult: (r) => result = r));
      await tester.tap(find.text('Mở'));
      await tester.pumpAndSettle();
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();
      expect(result, isNull);
    });

    testWidgets('giảm chuyển động: nội dung hiện đủ ngay', (tester) async {
      await tester.pumpWidget(_sheetHost(reduce: true));
      await tester.tap(find.text('Mở'));
      await tester.pumpAndSettle();
      expect(find.text('UNDERSTAND HOÀN THÀNH'), findsOneWidget);
      expect(find.text('Từ vựng: 3'), findsOneWidget);
    });
  });
}
