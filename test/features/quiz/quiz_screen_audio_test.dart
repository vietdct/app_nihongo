import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nihongo/domain/entities/listening_dialogue.dart';
import 'package:nihongo/domain/services/quiz_generator.dart';
import 'package:nihongo/features/quiz/providers/quiz_providers.dart';
import 'package:nihongo/features/quiz/quiz_screen.dart';
import 'package:nihongo/features/quiz/widgets/countdown_ring.dart';
import 'package:nihongo/features/quiz/widgets/listening_question_body.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Giả lập plugin flutter_tts: đếm `speak`/`stop`, mỗi lượt đọc kéo dài tới khi
/// `stop` hoặc test cho kết thúc.
class _FakeTts {
  final spoken = <String>[];
  var stops = 0;
  Completer<void>? _current;

  Future<Object?> handle(MethodCall call) async {
    switch (call.method) {
      case 'getVoices':
        return [
          {'name': 'Kyoko', 'locale': 'ja-JP', 'gender': 'female'},
        ];
      case 'speak':
        spoken.add(call.arguments as String);
        final c = _current = Completer<void>();
        await c.future;
      case 'stop':
        stops++;
        final c = _current;
        _current = null;
        if (c != null && !c.isCompleted) c.complete();
    }
    return 1;
  }
}

const _single = QuizQuestion(
  promptVi: 'Chọn nghĩa đúng',
  displayJp: '障害',
  options: ['Tiến độ', 'Sự cố', 'Cuộc họp', 'Bàn giao'],
  correctIndex: 1,
);

const _single2 = QuizQuestion(
  promptVi: 'Chọn nghĩa đúng',
  displayJp: '会議',
  options: ['Cuộc họp', 'Sự cố', 'Báo cáo', 'Bàn giao'],
  correctIndex: 0,
);

const _cloze = QuizQuestion(
  promptVi: 'Điền từ thích hợp vào chỗ trống',
  displayJp: '内容を＿＿＿します。',
  options: ['確認', '進捗', '課題', '納期'],
  correctIndex: 0,
);

const _dialogue = QuizQuestion(
  promptVi: '会議室を使うにはどうすればよいですか。',
  displayJp: '',
  options: ['予約する', '許可を取る', '借りる', '断る'],
  correctIndex: 0,
  dialogueTurns: [
    ListeningTurn(speaker: 'A', jp: 'こちらの会議室は予約が必要です'),
    ListeningTurn(speaker: 'B', jp: 'はい、承知しました'),
  ],
);

Future<void> _open(WidgetTester tester, List<QuizQuestion> questions) async {
  tester.view.physicalSize = const Size(1170, 2532);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      // Không có người dùng đăng nhập → không cộng XP, không chạm Supabase.
      overrides: [quizXpControllerProvider.overrideWithValue(null)],
      child: MaterialApp(
        home: QuizScreen(questions: questions, title: 'Luyện tập'),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late _FakeTts fake;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    fake = _FakeTts();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
            const MethodChannel('flutter_tts'), fake.handle);
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(const MethodChannel('flutter_tts'), null);
  });

  testWidgets('câu thường: mở câu không phát âm, bấm loa mới phát 1 lần',
      (tester) async {
    await _open(tester, [_single, _single2]);
    // Quá mốc 3s mà bản cũ từng chờ rồi tự phát.
    await tester.pump(const Duration(seconds: 5));
    expect(fake.spoken, isEmpty);

    await tester.tap(find.byIcon(Icons.volume_up_rounded).first);
    await tester.pump(const Duration(milliseconds: 100));
    expect(fake.spoken, ['障害']);
  });

  testWidgets('câu thường: chọn đáp án không tự phát', (tester) async {
    await _open(tester, [_single, _single2]);
    await tester.tap(find.text('Sự cố'));
    await tester.pump(const Duration(seconds: 5));
    expect(fake.spoken, isEmpty);
  });

  testWidgets('câu điền chỗ trống: chưa trả lời không có nút loa, trả lời rồi '
      'đọc câu hoàn chỉnh', (tester) async {
    await _open(tester, [_cloze, _single2]);
    await tester.pump(const Duration(seconds: 5));
    expect(find.byIcon(Icons.volume_up_rounded), findsNothing);
    expect(fake.spoken, isEmpty);

    await tester.tap(find.text('確認'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(fake.spoken, isEmpty);

    await tester.tap(find.byIcon(Icons.volume_up_rounded).first);
    await tester.pump(const Duration(milliseconds: 100));
    expect(fake.spoken, ['内容を確認します。']);
  });

  testWidgets('hội thoại nghe hiểu: không tự phát khi mở câu, kể cả sau 5s',
      (tester) async {
    await _open(tester, [_dialogue, _dialogue]);
    await tester.pump(const Duration(seconds: 5));
    expect(fake.spoken, isEmpty);
  });

  testWidgets('hội thoại nghe hiểu: bấm Play mới phát, đúng lượt thoại đầu',
      (tester) async {
    await _open(tester, [_dialogue, _dialogue]);
    await tester.tap(find.byIcon(Icons.play_arrow_rounded).first);
    await tester.pump(const Duration(milliseconds: 300));
    expect(fake.spoken, ['こちらの会議室は予約が必要です']);
  });

  testWidgets('đang phát rồi trả lời: dừng âm thanh, không phát thêm',
      (tester) async {
    await _open(tester, [_single, _single2]);
    await tester.tap(find.byIcon(Icons.volume_up_rounded).first);
    await tester.pump(const Duration(milliseconds: 100));
    final stopsBefore = fake.stops;

    await tester.tap(find.text('Sự cố'));
    await tester.pump(const Duration(seconds: 5));
    expect(fake.stops, greaterThan(stopsBefore));
    expect(fake.spoken, ['障害']);
  });

  /// Giá trị đồng hồ: câu nghe đọc từ [ListeningQuestionBody], câu thường từ
  /// [CountdownRing] — cùng 1 AnimationController của QuizScreen.
  double ring(WidgetTester tester) {
    final body = find.byType(ListeningQuestionBody);
    if (body.evaluate().isNotEmpty) {
      return tester.widget<ListeningQuestionBody>(body).timerController.value;
    }
    return tester
        .widget<CountdownRing>(find.byType(CountdownRing))
        .controller
        .value;
  }

  testWidgets('câu nghe: đồng hồ đứng yên cho tới khi bấm Play lần đầu',
      (tester) async {
    await _open(tester, [_dialogue, _dialogue]);
    await tester.pump(const Duration(seconds: 5));
    expect(ring(tester), 1.0);

    await tester.tap(find.byIcon(Icons.play_arrow_rounded).first);
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(seconds: 1));
    expect(ring(tester), lessThan(1.0));
  });

  testWidgets('câu thường: đồng hồ chạy ngay như cũ', (tester) async {
    await _open(tester, [_single, _single2]);
    await tester.pump(const Duration(seconds: 2));
    expect(ring(tester), lessThan(1.0));
  });
}
