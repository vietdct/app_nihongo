import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nihongo/domain/services/quiz_generator.dart';
import 'package:nihongo/features/quiz/providers/quiz_providers.dart';
import 'package:nihongo/features/quiz/quiz_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _withExplanation = QuizQuestion(
  promptVi: 'Chọn cách diễn đạt đúng để điền vào chỗ trống',
  displayJp: '進捗の詳細は WBS ファイルを（　　）。',
  options: ['ご確認ください', 'ご確認します', 'ご確認になります', 'ご確認いたします'],
  correctIndex: 0,
  explanationVi: 'Đề nghị người nghe xem tài liệu: ご + 漢語 + ください.',
  sourceNote: 'Câu trích từ sách · 第8課 練習① 第4項',
);

const _noExplanation = QuizQuestion(
  promptVi: 'Chọn nghĩa đúng',
  displayJp: '障害',
  options: ['Tiến độ', 'Sự cố', 'Cuộc họp', 'Bàn giao'],
  correctIndex: 1,
);

Future<void> _open(WidgetTester tester, QuizQuestion q) async {
  tester.view.physicalSize = const Size(1170, 2532);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [quizXpControllerProvider.overrideWithValue(null)],
      child: MaterialApp(
        home: QuizScreen(questions: [q, q], title: 'Luyện tập'),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('flutter_tts'),
      (call) async => call.method == 'getVoices' ? [] : 1,
    );
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(const MethodChannel('flutter_tts'), null);
  });

  testWidgets('chưa trả lời: không hiện lời giải; sau khi chọn: hiện lời giải và nguồn',
      (tester) async {
    await _open(tester, _withExplanation);
    expect(find.byKey(const ValueKey('quiz-explanation')), findsNothing);
    expect(find.textContaining('ご + 漢語'), findsNothing);

    await tester.tap(find.text('ご確認します'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byKey(const ValueKey('quiz-explanation')), findsOneWidget);
    expect(find.textContaining('ご + 漢語 + ください'), findsOneWidget);
    expect(find.textContaining('第8課 練習① 第4項'), findsOneWidget);
  });

  testWidgets('câu không có lời giải: không hiện khung giải thích (không bịa)',
      (tester) async {
    await _open(tester, _noExplanation);
    await tester.tap(find.text('Sự cố'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byKey(const ValueKey('quiz-explanation')), findsNothing);
  });
}
