import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nihongo/core/network/supabase_providers.dart';
import 'package:nihongo/domain/entities/lesson.dart';
import 'package:nihongo/domain/entities/vocab_meaning.dart';
import 'package:nihongo/domain/entities/vocabulary.dart';
import 'package:nihongo/shared/motion/confetti_burst.dart';
import 'package:nihongo/features/lesson/widgets/lesson_review_view.dart';
import 'package:nihongo/features/vocabulary/providers/vocab_progress_providers.dart';
import 'package:nihongo/shared/motion/animated_count.dart';
import 'package:nihongo/shared/motion/pop_in.dart';

Widget _app(Widget child, {bool reduce = false}) => MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(disableAnimations: reduce),
        child: Scaffold(body: Center(child: child)),
      ),
    );

AnimatedCount _count(int? v, {int? from, String prefix = ''}) => AnimatedCount(
      value: v,
      from: from,
      prefix: prefix,
      style: const TextStyle(fontSize: 20),
    );

int _shown(WidgetTester tester) {
  final t = tester.widget<Text>(
    find.descendant(
      of: find.byType(AnimatedCount),
      matching: find.byType(Text),
    ),
  );
  return int.parse(t.data!.replaceAll(RegExp(r'[^0-9]'), ''));
}

double _scale(WidgetTester tester) => tester
    .widget<Transform>(
      find
          .descendant(
            of: find.byType(AnimatedCount),
            matching: find.byType(Transform),
          )
          .first,
    )
    .transform
    .entry(0, 0);

void main() {
  group('AnimatedCount', () {
    testWidgets('chưa có giá trị: hiện dấu –; lần đầu có giá trị hiện thẳng',
        (tester) async {
      await tester.pumpWidget(_app(_count(null)));
      expect(find.text('–'), findsOneWidget);

      await tester.pumpWidget(_app(_count(120)));
      // Không biết giá trị trước → không đếm giả từ 0.
      expect(find.text('120'), findsOneWidget);
      expect(tester.hasRunningAnimations, isFalse);
    });

    testWidgets('giá trị đổi khi đang sống: đếm 120 → 135, kết thúc đúng 135',
        (tester) async {
      await tester.pumpWidget(_app(_count(120)));
      await tester.pumpWidget(_app(_count(135)));
      await tester.pump(const Duration(milliseconds: 200));
      final mid = _shown(tester);
      expect(mid, inInclusiveRange(120, 135));
      expect(mid, isNot(135));

      await tester.pumpAndSettle();
      expect(_shown(tester), 135);
    });

    testWidgets('rebuild cùng giá trị: không chạy lại animation',
        (tester) async {
      await tester.pumpWidget(_app(_count(50)));
      await tester.pumpWidget(_app(_count(50)));
      await tester.pumpWidget(_app(_count(50)));
      expect(tester.hasRunningAnimations, isFalse);
      expect(_shown(tester), 50);
    });

    testWidgets('nhiều cập nhật liên tiếp: giá trị cuối luôn đúng',
        (tester) async {
      await tester.pumpWidget(_app(_count(10)));
      await tester.pumpWidget(_app(_count(20)));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pumpWidget(_app(_count(35)));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pumpWidget(_app(_count(30)));
      await tester.pumpAndSettle();
      expect(_shown(tester), 30);
    });

    testWidgets('null → giá trị (tải xong) rồi đổi: chỉ đếm khi đã có giá trị',
        (tester) async {
      await tester.pumpWidget(_app(_count(null)));
      await tester.pumpWidget(_app(_count(200)));
      expect(tester.hasRunningAnimations, isFalse);
      expect(_shown(tester), 200);

      await tester.pumpWidget(_app(_count(215)));
      await tester.pump(const Duration(milliseconds: 100));
      expect(tester.hasRunningAnimations, isTrue);
      await tester.pumpAndSettle();
      expect(_shown(tester), 215);
    });

    testWidgets('from: 0 đếm từ 0 tới số đã nhận (XP của phiên), có tiền tố',
        (tester) async {
      await tester.pumpWidget(_app(_count(40, from: 0, prefix: '+')));
      expect(_shown(tester), 0);
      await tester.pumpAndSettle();
      expect(find.text('+40'), findsOneWidget);
    });

    testWidgets('chỉ nảy khi tăng; giảm hoặc giữ nguyên thì không nảy',
        (tester) async {
      await tester.pumpWidget(_app(_count(10)));
      await tester.pumpWidget(_app(_count(12)));
      await tester.pump(const Duration(milliseconds: 180));
      expect(_scale(tester), greaterThan(1.01));
      await tester.pumpAndSettle();
      expect(_scale(tester), closeTo(1, 1e-9));

      await tester.pumpWidget(_app(_count(5)));
      await tester.pump(const Duration(milliseconds: 180));
      expect(_scale(tester), closeTo(1, 1e-9));
      await tester.pumpAndSettle();
    });

    testWidgets('giảm chuyển động: hiện thẳng giá trị mới, không animation',
        (tester) async {
      await tester.pumpWidget(_app(_count(10), reduce: true));
      await tester.pumpWidget(_app(_count(99), reduce: true));
      await tester.pump();
      expect(_shown(tester), 99);
      expect(tester.hasRunningAnimations, isFalse);
    });

    testWidgets('gỡ widget giữa lúc đếm: không lỗi', (tester) async {
      await tester.pumpWidget(_app(_count(10)));
      await tester.pumpWidget(_app(_count(90)));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pumpWidget(_app(const SizedBox()));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  });

  group('PopIn', () {
    testWidgets('chạy 1 lần rồi dừng; rebuild không chạy lại', (tester) async {
      Widget w() => _app(const PopIn(child: Icon(Icons.check)));
      await tester.pumpWidget(w());
      await tester.pump(const Duration(milliseconds: 100));
      expect(tester.hasRunningAnimations, isTrue);
      await tester.pumpAndSettle();
      expect(tester.hasRunningAnimations, isFalse);

      await tester.pumpWidget(w());
      expect(tester.hasRunningAnimations, isFalse);
    });

    testWidgets('enabled=false hoặc giảm chuyển động: hiện thẳng',
        (tester) async {
      await tester.pumpWidget(
        _app(const PopIn(enabled: false, child: Icon(Icons.check))),
      );
      expect(tester.hasRunningAnimations, isFalse);
      await tester.pumpWidget(
        _app(const PopIn(child: Icon(Icons.check)), reduce: true),
      );
      expect(tester.hasRunningAnimations, isFalse);
      expect(find.byIcon(Icons.check), findsOneWidget);
    });
  });

  group('LessonReviewView — hoàn thành bài', () {
    testWidgets('hàng đợi rỗng từ đầu: không phải sự kiện hoàn thành, tĩnh',
        (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: _app(
            const SizedBox(
              height: 500,
              width: 360,
              child: LessonReviewView(
                items: <LessonContentItem>[],
                lessonId: 'l1',
                lessonTitle: 'Bài 1',
              ),
            ),
          ),
        ),
      );
      expect(find.text('Hoàn thành bài học!'), findsWidgets);
      expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);
      expect(tester.hasRunningAnimations, isFalse);
    });

    testWidgets(
        'vừa ôn xong trong phiên: có check nảy + confetti (không chặn nút)',
        (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentUserProvider.overrideWithValue(null),
            vocabProgressControllerProvider.overrideWithValue(null),
          ],
          child: _app(
            const SizedBox(
              height: 600,
              width: 360,
              child: LessonReviewView(
                items: [
                  LessonContentItem.vocabulary(
                    Vocabulary(
                      id: 'v1',
                      word: '会議',
                      reading: 'かいぎ',
                      levelId: 'l',
                      meanings: [VocabMeaning(meaningVi: 'Cuộc họp')],
                    ),
                  ),
                ],
                lessonId: 'l1',
                lessonTitle: 'Bài 1',
              ),
            ),
          ),
        ),
      );
      expect(find.byType(ConfettiBurst), findsNothing);

      await tester.tap(find.text('Hiện đáp án'));
      await tester.pump();
      await tester.tap(find.text('Nhớ rõ'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('Hoàn thành bài học!'), findsOneWidget);
      expect(find.byType(ConfettiBurst), findsOneWidget);
      expect(tester.hasRunningAnimations, isTrue);
      // Nút vẫn bấm được trong lúc confetti rơi.
      expect(
        tester
            .widget<FilledButton>(
              find.widgetWithText(FilledButton, 'Hoàn thành bài học'),
            )
            .onPressed,
        isNotNull,
      );

      await tester.pumpAndSettle(const Duration(milliseconds: 100));
      expect(tester.hasRunningAnimations, isFalse);
    });
  });
}
