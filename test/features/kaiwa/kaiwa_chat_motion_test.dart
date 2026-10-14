import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nihongo/domain/entities/kaiwa_message.dart';
import 'package:nihongo/domain/entities/kaiwa_persona.dart';
import 'package:nihongo/domain/entities/kaiwa_scenario.dart';
import 'package:nihongo/features/kaiwa/kaiwa_chat_screen.dart';
import 'package:nihongo/features/kaiwa/providers/kaiwa_chat_service.dart';
import 'package:nihongo/features/lesson/providers/level_providers.dart';
import 'package:nihongo/shared/motion/chat_motion.dart';
import 'package:shared_preferences/shared_preferences.dart';

typedef _Turn = ({KaiwaMessage userMessage, KaiwaMessage aiMessage});

const _persona = KaiwaPersona(
  id: 'p1',
  name: 'Tanaka',
  glyph: '田',
  role: 'Nhân viên',
  gender: 'male',
  personality: 'thân thiện',
  politenessLevel: 'polite',
  description: 'mô tả',
  orderIndex: 0,
  voiceStyle: 'default',
);

const _scenario = KaiwaScenario(
  id: 's1',
  title: 'Gặp gỡ',
  glyph: '会',
  category: 'daily',
  description: 'mô tả',
  levelMin: 'N5',
  systemContext: 'ctx',
  orderIndex: 0,
);

KaiwaMessage _ai(String id, String text) =>
    KaiwaMessage(id: id, role: KaiwaMessageRole.ai, contentJp: text);
KaiwaMessage _user(String id, String text) =>
    KaiwaMessage(id: id, role: KaiwaMessageRole.user, contentJp: text);

/// Service giả: đếm số lần gọi AI, cho test quyết định lúc nào request xong
/// hoặc lỗi. Không chạm Supabase.
class _FakeService implements KaiwaChatService {
  _FakeService({this.history = const []});

  final List<KaiwaMessage> history;
  int startCalls = 0;
  int sendCalls = 0;
  int loadCalls = 0;
  final pending = <Completer<_Turn>>[];

  @override
  Future<({String conversationId, KaiwaMessage aiMessage})> startConversation({
    required KaiwaPersona persona,
    required KaiwaScenario scenario,
    required String levelCode,
    String? levelId,
    String? seedWord,
  }) async {
    startCalls++;
    return (conversationId: 'c1', aiMessage: _ai('greet', 'こんにちは'));
  }

  @override
  Future<List<KaiwaMessage>> loadMessages(String conversationId) async {
    loadCalls++;
    return history;
  }

  @override
  Future<_Turn> sendMessage({
    required String conversationId,
    required KaiwaPersona persona,
    required KaiwaScenario scenario,
    required String levelCode,
    required List<KaiwaMessage> history,
    required String text,
  }) {
    sendCalls++;
    final c = Completer<_Turn>();
    pending.add(c);
    return c.future;
  }

  void succeed(int n, {required String userText, required String aiText}) {
    pending[n].complete(
      (
        userMessage: _user('real-user-$n', userText),
        aiMessage: _ai('ai-$n', aiText),
      ),
    );
  }

  void fail(int n) => pending[n].completeError(Exception('mạng lỗi'));
}

void _fakeTts(WidgetTester tester) {
  tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
    const MethodChannel('flutter_tts'),
    (call) async => call.method == 'getVoices' ? <Object?>[] : 1,
  );
  addTearDown(
    () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('flutter_tts'),
      null,
    ),
  );
}

Future<void> _open(
  WidgetTester tester,
  _FakeService service, {
  String? resumeId,
  bool reduceMotion = false,
  Brightness brightness = Brightness.light,
}) async {
  _fakeTts(tester);
  tester.view.physicalSize = const Size(1170, 2532);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        kaiwaChatServiceProvider.overrideWithValue(service),
        currentLevelIdProvider.overrideWithValue(null),
      ],
      child: MaterialApp(
        theme: ThemeData(brightness: brightness),
        builder: (context, child) => MediaQuery(
          data:
              MediaQuery.of(context).copyWith(disableAnimations: reduceMotion),
          child: child!,
        ),
        home: KaiwaChatScreen(
          persona: _persona,
          scenario: _scenario,
          resumeConversationId: resumeId,
        ),
      ),
    ),
  );
  await tester.pump(); // post-frame: bắt đầu/nạp hội thoại
  await tester.pump(); // future hoàn tất
  // Tắt auto-đọc để test không dính timer 20s của _speak.
  await tester.tap(find.byTooltip('Tắt tự động đọc'));
  await tester.pump();
}

/// Kết thúc test sạch: gỡ cây widget, xả timer 20s còn treo của `_speak`.
Future<void> _finish(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox());
  await tester.pump(const Duration(seconds: 25));
}

Future<void> _type(WidgetTester tester, String text) async {
  await tester.enterText(find.byType(TextField), text);
  await tester.tap(find.byTooltip('Gửi'));
  await tester.pump();
}

/// Độ mờ của bubble chứa [text] (1 = hiện đủ, không đang animate vào).
double _opacityOf(WidgetTester tester, String text) => tester
    .widget<Opacity>(
      find.ancestor(of: find.text(text), matching: find.byType(Opacity)).first,
    )
    .opacity;

final _dots = find.byKey(const ValueKey('typing-dot-0'));

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('entrance animation', () {
    testWidgets('lời chào AI mới animate vào rồi hiện đủ', (tester) async {
      await _open(tester, _FakeService());
      // _open đã pump vài khung: nhưng animation 220ms chạy từ lúc dựng.
      await tester.pumpAndSettle();
      expect(find.text('こんにちは'), findsOneWidget);
      expect(_opacityOf(tester, 'こんにちは'), 1);
      await _finish(tester);
    });

    testWidgets(
        'tin gửi đi: bubble tạm animate, đổi sang id thật KHÔNG dựng '
        'lại và không animate lại', (tester) async {
      final service = _FakeService();
      await _open(tester, service);
      await tester.pumpAndSettle();

      await _type(tester, 'はじめまして');
      await tester.pump(const Duration(milliseconds: 60));
      // Đang trượt vào: chưa đủ độ đậm.
      expect(_opacityOf(tester, 'はじめまして'), lessThan(1));
      // Ba chấm còn chạy trong lúc chờ nên không dùng pumpAndSettle.
      await tester.pump(const Duration(milliseconds: 300));
      expect(_opacityOf(tester, 'はじめまして'), 1);
      final before = tester.state(find.byType(MessageEntrance).last);

      service.succeed(0, userText: 'はじめまして', aiText: 'よろしく');
      await tester.pump();
      // Cùng một State (cùng bubble) dù id đổi tạm → thật.
      final sameBubble = find.ancestor(
        of: find.text('はじめまして'),
        matching: find.byType(MessageEntrance),
      );
      expect(tester.state(sameBubble), same(before));
      expect(_opacityOf(tester, 'はじめまして'), 1);
      // Tin AI mới thì animate.
      await tester.pump(const Duration(milliseconds: 60));
      expect(_opacityOf(tester, 'よろしく'), lessThan(1));
      await tester.pumpAndSettle();
      expect(_opacityOf(tester, 'よろしく'), 1);
      expect(find.text('はじめまして'), findsOneWidget);
      await _finish(tester);
    });

    testWidgets('mở lại hội thoại cũ: toàn bộ lịch sử hiện ngay, không animate',
        (tester) async {
      final service = _FakeService(
        history: [_ai('a', 'もしもし'), _user('b', 'はい'), _ai('c', 'お元気ですか')],
      );
      await _open(tester, service, resumeId: 'old');
      // Chưa pump thêm: nếu có animate thì opacity < 1 ngay khung đầu.
      for (final t in ['もしもし', 'はい', 'お元気ですか']) {
        expect(_opacityOf(tester, t), 1, reason: t);
      }
      expect(service.startCalls, 0);
      expect(service.loadCalls, 1);
      await _finish(tester);
    });

    testWidgets('cuộn lên/xuống và rebuild không làm tin cũ animate lại',
        (tester) async {
      final history = [
        for (var i = 0; i < 40; i++)
          i.isEven ? _ai('m$i', 'ai$i') : _user('m$i', 'user$i'),
      ];
      await _open(tester, _FakeService(history: history), resumeId: 'old');
      await tester.pumpAndSettle();

      final list = find.byType(ListView);
      await tester.drag(list, const Offset(0, 3000));
      await tester.pump();
      for (var i = 0; i < 5; i++) {
        expect(_opacityOf(tester, 'ai0'), 1);
        await tester.pump(const Duration(milliseconds: 16));
      }
      await tester.drag(list, const Offset(0, -3000));
      await tester.pump();
      expect(_opacityOf(tester, 'user39'), 1);

      // Đổi toggle bản dịch → rebuild toàn màn.
      await tester.tap(find.byTooltip('Hiện bản dịch'));
      await tester.pump();
      expect(_opacityOf(tester, 'user39'), 1);
      await _finish(tester);
    });

    testWidgets('giảm chuyển động: tin mới hiện đủ ngay', (tester) async {
      final service = _FakeService();
      await _open(tester, service, reduceMotion: true);
      await _type(tester, 'こんにちは、先生');
      expect(_opacityOf(tester, 'こんにちは、先生'), 1);
      await _finish(tester);
    });
  });

  group('typing indicator', () {
    testWidgets('không có request: không hiện; gửi → hiện; xong → biến mất',
        (tester) async {
      final service = _FakeService();
      await _open(tester, service);
      await tester.pumpAndSettle();
      expect(_dots, findsNothing);

      await _type(tester, 'はい');
      expect(service.sendCalls, 1);
      expect(_dots, findsOneWidget);
      expect(find.byType(TypingDots), findsOneWidget);

      service.succeed(0, userText: 'はい', aiText: 'そうですか');
      await tester.pump();
      expect(_dots, findsNothing);
      await tester.pumpAndSettle();
      expect(tester.hasRunningAnimations, isFalse);
      await _finish(tester);
    });

    testWidgets('chỉ xem lịch sử: không hiện', (tester) async {
      await _open(
        tester,
        _FakeService(history: [_ai('a', 'もしもし')]),
        resumeId: 'old',
      );
      await tester.pumpAndSettle();
      expect(_dots, findsNothing);
      await _finish(tester);
    });

    testWidgets('lỗi: indicator biến mất, tin tạm bị gỡ, câu trả về ô nhập',
        (tester) async {
      final service = _FakeService();
      await _open(tester, service);
      await tester.pumpAndSettle();
      await _type(tester, 'ありがとう');
      expect(_dots, findsOneWidget);

      service.fail(0);
      await tester.pump();
      await tester.pump();
      expect(_dots, findsNothing);
      expect(find.text('ありがとう'), findsOneWidget); // chỉ còn trong ô nhập
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        'ありがとう',
      );
      await tester.pumpAndSettle();
      expect(tester.hasRunningAnimations, isFalse);
      await _finish(tester);
    });

    testWidgets(
        'retry sau lỗi: đúng 1 request mỗi lần bấm, không trùng tin, '
        'chỉ 1 indicator', (tester) async {
      final service = _FakeService();
      await _open(tester, service);
      await tester.pumpAndSettle();

      await _type(tester, 'ありがとう');
      service.fail(0);
      await tester.pumpAndSettle();
      expect(service.sendCalls, 1);
      // SnackBar báo lỗi đang che nút Gửi: đợi nó tự đóng.
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();

      // Người dùng bấm gửi lại (text đã quay về ô nhập).
      await tester.tap(find.byTooltip('Gửi'));
      await tester.pump();
      expect(service.sendCalls, 2);
      expect(_dots, findsOneWidget);

      // Đang chờ: bấm gửi tiếp không tạo request thứ 3 (nút bị khoá).
      await tester.tap(find.byTooltip('Gửi'), warnIfMissed: false);
      await tester.pump();
      expect(service.sendCalls, 2);

      service.succeed(1, userText: 'ありがとう', aiText: 'どういたしまして');
      await tester.pumpAndSettle();
      expect(_dots, findsNothing);
      expect(find.text('ありがとう'), findsOneWidget);
      expect(find.text('どういたしまして'), findsOneWidget);
      await _finish(tester);
    });

    testWidgets('rebuild/animation không sinh request mới', (tester) async {
      final service = _FakeService();
      await _open(tester, service);
      await _type(tester, 'はい');
      for (var i = 0; i < 30; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }
      await tester.tap(find.byTooltip('Hiện bản dịch'));
      await tester.pump();
      expect(service.sendCalls, 1);
      expect(service.startCalls, 1);
      service.succeed(0, userText: 'はい', aiText: 'ええ');
      await tester.pumpAndSettle();
      await _finish(tester);
    });

    testWidgets(
        'giảm chuyển động: ba chấm tĩnh nhưng vẫn hiện, không có '
        'animation lặp', (tester) async {
      final service = _FakeService();
      await _open(tester, service, reduceMotion: true);
      await tester.pumpAndSettle();
      await _type(tester, 'はい');
      // Đợi hết cuộn/ink splash của nút Gửi rồi mới kết luận ba chấm tĩnh.
      await tester.pump(const Duration(seconds: 2));
      expect(_dots, findsOneWidget);
      expect(find.byKey(const ValueKey('typing-dot-2')), findsOneWidget);
      expect(tester.hasRunningAnimations, isFalse);
      service.succeed(0, userText: 'はい', aiText: 'ええ');
      await tester.pumpAndSettle();
      await _finish(tester);
    });

    testWidgets('bình thường: ba chấm chuyển động; dừng hẳn khi hết chờ',
        (tester) async {
      final service = _FakeService();
      await _open(tester, service);
      await tester.pumpAndSettle();
      await _type(tester, 'はい');
      await tester.pump(const Duration(milliseconds: 300));
      expect(tester.hasRunningAnimations, isTrue);
      service.succeed(0, userText: 'はい', aiText: 'ええ');
      await tester.pumpAndSettle(); // sẽ treo nếu ticker còn lặp
      expect(tester.hasRunningAnimations, isFalse);
      await _finish(tester);
    });

    testWidgets('dark mode dựng được ba chấm', (tester) async {
      final service = _FakeService();
      await _open(tester, service, brightness: Brightness.dark);
      await _type(tester, 'はい');
      expect(_dots, findsOneWidget);
      service.succeed(0, userText: 'はい', aiText: 'ええ');
      await tester.pumpAndSettle();
      await _finish(tester);
    });
  });

  group('vòng đời', () {
    testWidgets(
        'rời màn hình khi request đang chạy rồi response đến: '
        'không lỗi, không gọi lại', (tester) async {
      final service = _FakeService();
      await _open(tester, service);
      await tester.pumpAndSettle();
      await _type(tester, 'はい');
      expect(_dots, findsOneWidget);

      // Gỡ màn hình giữa lúc ba chấm đang chạy (không để ticker rò rỉ).
      await tester.pumpWidget(const SizedBox());
      service.succeed(0, userText: 'はい', aiText: 'ええ');
      await tester.pump(const Duration(seconds: 25));
      expect(tester.takeException(), isNull);
      expect(service.sendCalls, 1);
    });

    testWidgets('lỗi đến sau khi đã rời màn hình: không lỗi', (tester) async {
      final service = _FakeService();
      await _open(tester, service);
      await tester.pumpAndSettle();
      await _type(tester, 'はい');
      await tester.pumpWidget(const SizedBox());
      service.fail(0);
      await tester.pump(const Duration(seconds: 25));
      expect(tester.takeException(), isNull);
    });

    testWidgets(
        'AI trả lời dài: giữ đúng chính sách auto-scroll hiện có (cuộn xuống), '
        'không exception', (tester) async {
      final history = [
        for (var i = 0; i < 40; i++)
          i.isEven ? _ai('m$i', 'ai$i') : _user('m$i', 'user$i'),
      ];
      final service = _FakeService(history: history);
      await _open(tester, service, resumeId: 'old');
      await tester.pumpAndSettle();
      // Người dùng đang đọc lịch sử cũ rồi gửi tin.
      await tester.drag(find.byType(ListView), const Offset(0, 3000));
      await tester.pump();
      final scrolledUpTo = tester
          .state<ScrollableState>(
            find.descendant(
              of: find.byType(ListView),
              matching: find.byType(Scrollable),
            ),
          )
          .position
          .pixels;
      await _type(tester, 'last');
      await tester.pump(const Duration(milliseconds: 400));
      service.succeed(0, userText: 'last', aiText: 'x' * 400);
      await tester.pumpAndSettle();

      final position = tester
          .state<ScrollableState>(
            find.descendant(
              of: find.byType(ListView),
              matching: find.byType(Scrollable),
            ),
          )
          .position;
      // Chính sách có sẵn: sau khi AI trả lời thì cuộn xuống tin mới. (Với
      // ListView lazy, đích animateTo chỉ là ước lượng nên có thể chưa chạm
      // đáy tuyệt đối — hành vi này giống hệt trước khi thêm animation.)
      expect(position.pixels, greaterThan(scrolledUpTo));
      expect(find.textContaining('xxxx'), findsOneWidget);
      expect(tester.takeException(), isNull);
      expect(_dots, findsNothing);
      await _finish(tester);
    });
  });
}
