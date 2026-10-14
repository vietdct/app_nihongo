import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nihongo/domain/services/quiz_generator.dart';
import 'package:nihongo/features/quiz/providers/quiz_providers.dart';
import 'package:nihongo/features/quiz/quiz_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _q1 = QuizQuestion(
  promptVi: 'Chọn nghĩa đúng',
  displayJp: '障害',
  options: ['Tiến độ', 'Sự cố', 'Cuộc họp', 'Bàn giao'],
  correctIndex: 1,
);

const _q2 = QuizQuestion(
  promptVi: 'Chọn nghĩa đúng',
  displayJp: '会議',
  options: ['Cuộc họp', 'Sự cố', 'Báo cáo', 'Bàn giao'],
  correctIndex: 0,
);

Future<void> _open(
  WidgetTester tester, {
  bool reduceMotion = false,
}) async {
  tester.view.physicalSize = const Size(1170, 2532);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [quizXpControllerProvider.overrideWithValue(null)],
      child: MaterialApp(
        builder: (context, child) => MediaQuery(
          data:
              MediaQuery.of(context).copyWith(disableAnimations: reduceMotion),
          child: child!,
        ),
        home: const QuizScreen(questions: [_q1, _q2], title: 'Luyện tập'),
      ),
    ),
  );
  await _settle(tester);
}

/// Chạy hết animation ngắn (timer đếm ngược của câu vẫn chạy nên không dùng
/// pumpAndSettle).
Future<void> _settle(WidgetTester tester) async {
  await tester.pump(const Duration(milliseconds: 400));
  await tester.pump(const Duration(milliseconds: 400));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('trả lời sai: đáp án sai có icon X, đáp án đúng có icon tick',
      (tester) async {
    await _open(tester);
    expect(find.byIcon(Icons.check_circle_rounded), findsNothing);
    expect(find.byIcon(Icons.cancel_rounded), findsNothing);

    await tester.tap(find.text('Tiến độ'));
    await _settle(tester);

    expect(find.byIcon(Icons.cancel_rounded), findsOneWidget);
    expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);
    expect(find.text('Tiếp tục'), findsOneWidget);
  });

  testWidgets('trả lời đúng: chỉ có icon tick', (tester) async {
    await _open(tester);
    await tester.tap(find.text('Sự cố'));
    await _settle(tester);
    expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);
    expect(find.byIcon(Icons.cancel_rounded), findsNothing);
  });

  testWidgets(
      'bấm liên tiếp 2 đáp án chỉ ghi nhận đáp án đầu (không trả lời 2 lần)',
      (tester) async {
    await _open(tester);
    await tester.tap(find.text('Tiến độ'));
    await tester.pump(const Duration(milliseconds: 20));
    await tester.tap(find.text('Sự cố').first);
    await _settle(tester);

    // Vẫn là câu sai: 1 icon X ở đáp án đã chọn đầu tiên, 1 tick ở đáp án đúng.
    expect(find.byIcon(Icons.cancel_rounded), findsOneWidget);
    expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);
  });

  testWidgets('sang câu mới: chỉ còn nội dung câu mới, không còn icon cũ',
      (tester) async {
    await _open(tester);
    await tester.tap(find.text('Sự cố'));
    await _settle(tester);
    await tester.tap(find.text('Tiếp tục'));
    // Giữa chuyển động chỉ có 1 bản nội dung câu hỏi (không chồng bản cũ).
    await tester.pump(const Duration(milliseconds: 60));
    expect(find.text('障害'), findsNothing);
    expect(find.text('会議'), findsOneWidget);
    expect(find.byIcon(Icons.check_circle_rounded), findsNothing);
    await _settle(tester);
    expect(find.text('Cuộc họp'), findsOneWidget);
  });

  testWidgets('giảm chuyển động: vẫn trả lời/chuyển câu bình thường',
      (tester) async {
    await _open(tester, reduceMotion: true);
    await tester.tap(find.text('Tiến độ'));
    await tester.pump();
    expect(find.byIcon(Icons.cancel_rounded), findsOneWidget);
    expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);
    await tester.tap(find.text('Tiếp tục'));
    await tester.pump();
    expect(find.text('会議'), findsOneWidget);
  });
}
