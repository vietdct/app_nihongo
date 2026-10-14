import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nihongo/shared/jp_speak_button.dart';
import 'package:nihongo/shared/motion/playing_indicator.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Giả lập plugin flutter_tts: `speak` kéo dài tới khi test cho kết thúc (hoặc
/// báo lỗi), đếm số lần `speak` để chắc không có audio tự phát.
class _FakeTts {
  final spoken = <String>[];
  Completer<void>? current;
  bool fail = false;

  Future<Object?> handle(MethodCall call) async {
    switch (call.method) {
      case 'getVoices':
        return [
          {'name': 'Kyoko', 'locale': 'ja-JP', 'gender': 'female'},
        ];
      case 'speak':
        spoken.add(call.arguments as String);
        if (fail) throw PlatformException(code: 'tts', message: 'lỗi giả lập');
        final c = current = Completer<void>();
        await c.future;
      case 'stop':
        final c = current;
        current = null;
        if (c != null && !c.isCompleted) c.complete();
    }
    return 1;
  }
}

bool _ringActive(WidgetTester tester) =>
    tester.widget<PlayingRing>(find.byType(PlayingRing)).active;

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

  Widget app({bool reduce = false}) => MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(disableAnimations: reduce),
          child: const Scaffold(
            body: Center(child: JpSpeakButton(text: '会議')),
          ),
        ),
      );

  Future<void> pumpSome(WidgetTester tester, [int ms = 300]) async {
    await tester.runAsync(() => Future<void>.delayed(
          const Duration(milliseconds: 50),
        ));
    await tester.pump(Duration(milliseconds: ms));
  }

  testWidgets('mở màn không tự đọc; chỉ chạm nút mới đọc', (tester) async {
    await tester.pumpWidget(app());
    await pumpSome(tester);
    expect(fake.spoken, isEmpty);
    expect(_ringActive(tester), isFalse);
    expect(tester.hasRunningAnimations, isFalse);
  });

  testWidgets('đang phát: vòng sóng chạy; phát xong thì dừng hẳn',
      (tester) async {
    await tester.pumpWidget(app());
    await tester.tap(find.byType(IconButton));
    await pumpSome(tester);
    expect(fake.spoken, ['会議']);
    expect(_ringActive(tester), isTrue);
    expect(tester.hasRunningAnimations, isTrue);

    fake.current!.complete();
    await pumpSome(tester);
    expect(_ringActive(tester), isFalse);
    await tester.pumpAndSettle();
    expect(tester.hasRunningAnimations, isFalse);
  });

  testWidgets('lỗi khi phát: trạng thái đang phát được tắt, không văng lỗi',
      (tester) async {
    fake.fail = true;
    await tester.pumpWidget(app());
    await tester.tap(find.byType(IconButton));
    await pumpSome(tester);
    expect(tester.takeException(), isNull);
    expect(_ringActive(tester), isFalse);
  });

  testWidgets('chạm liên tiếp khi đang phát chỉ đọc 1 lần', (tester) async {
    await tester.pumpWidget(app());
    await tester.tap(find.byType(IconButton));
    await pumpSome(tester);
    await tester.tap(find.byType(IconButton));
    await pumpSome(tester);
    expect(fake.spoken.length, 1);
    fake.current!.complete();
    await pumpSome(tester);
  });

  testWidgets('rời màn khi đang phát: không lỗi, không setState sau dispose',
      (tester) async {
    await tester.pumpWidget(app());
    await tester.tap(find.byType(IconButton));
    await pumpSome(tester);
    await tester.pumpWidget(const MaterialApp(home: SizedBox()));
    await pumpSome(tester);
    expect(tester.takeException(), isNull);
  });

  testWidgets('giảm chuyển động: vòng tĩnh, không animation chạy',
      (tester) async {
    await tester.pumpWidget(app(reduce: true));
    await tester.tap(find.byType(IconButton));
    await pumpSome(tester);
    // Chờ hết hiệu ứng gợn khi chạm (ink splash) rồi mới kiểm tra vòng sóng.
    await tester.pump(const Duration(seconds: 1));
    expect(_ringActive(tester), isTrue);
    expect(tester.hasRunningAnimations, isFalse);
    fake.current!.complete();
    await pumpSome(tester);
  });
}
