import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nihongo/domain/entities/listening_dialogue.dart';
import 'package:nihongo/domain/services/quiz_generator.dart';
import 'package:nihongo/features/review/jlpt_exam/exam_runner_screen.dart';
import 'package:nihongo/features/review/jlpt_exam/providers/jlpt_exam_content_providers.dart';
import 'package:nihongo/features/review/jlpt_exam/providers/jlpt_exam_session_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Giả lập plugin flutter_tts: ghi lại các lần `speak`/`stop`.
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

QuizQuestion _listening(String a) => QuizQuestion(
      promptVi: '会議室を使うにはどうすればよいですか。',
      displayJp: '',
      options: const ['予約する', '許可を取る', '借りる', '断る'],
      correctIndex: 0,
      dialogueTurns: [
        ListeningTurn(speaker: 'A', jp: a),
        const ListeningTurn(speaker: 'B', jp: 'はい、承知しました'),
      ],
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late _FakeTts fake;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    fake = _FakeTts();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('flutter_tts'),
      fake.handle,
    );
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(const MethodChannel('flutter_tts'), null);
  });

  /// Gỡ màn hình rồi chờ qua khoảng nghỉ giữa lượt thoại, để không còn Timer dở.
  Future<void> close(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 2));
  }

  Future<void> open(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [examSessionRepositoryProvider.overrideWithValue(null)],
        child: MaterialApp(
          home: ExamRunnerScreen(
            levelId: 'n5',
            mode: 'mini',
            overrideSections: [
              ExamRunSection(
                type: 'listening',
                timeMinutes: 10,
                questions: [_listening('câu-1'), _listening('câu-2')],
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('thi thử: vào câu nghe hiểu không tự phát, kể cả sau 5s',
      (tester) async {
    await open(tester);
    await tester.pump(const Duration(seconds: 5));
    expect(fake.spoken, isEmpty);
    await close(tester);
  });

  testWidgets('thi thử: bấm Nghe chỉ đọc hội thoại, không đọc câu hỏi',
      (tester) async {
    await open(tester);
    await tester.tap(find.text('Nghe'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(fake.spoken, ['câu-1']);
  });

  testWidgets(
      'thi thử: chuyển câu dừng tiếng đang đọc và không tự phát câu mới',
      (tester) async {
    await open(tester);
    await tester.tap(find.text('Nghe'));
    await tester.pump(const Duration(milliseconds: 300));
    final stopsBefore = fake.stops;

    await tester.tap(find.byIcon(Icons.chevron_right_rounded).first);
    await tester.pump(const Duration(seconds: 5));
    expect(fake.stops, greaterThan(stopsBefore));
    expect(fake.spoken, ['câu-1']);
    await close(tester);
  });
}
