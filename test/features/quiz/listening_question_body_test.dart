import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nihongo/core/services/dialogue_player.dart';
import 'package:nihongo/domain/entities/listening_dialogue.dart';
import 'package:nihongo/domain/services/quiz_generator.dart';
import 'package:nihongo/features/quiz/widgets/listening_question_body.dart';

const _secret1 = 'こちらの会議室はIT部門の専用です';
const _secret2 = 'はい、承知しました';

const _question = QuizQuestion(
  promptVi: '会議室を使うにはどうすればよいですか。',
  displayJp: '',
  options: ['予約する', '許可を取る', '借りる', '断る'],
  correctIndex: 0,
  dialogueTurns: [
    ListeningTurn(speaker: 'A', jp: _secret1),
    ListeningTurn(speaker: 'B', jp: _secret2),
  ],
);

Widget _host(
  ListeningPhase phase,
  AnimationController controller,
  DialoguePlayer player,
) {
  return MaterialApp(
    home: Scaffold(
      body: ListeningQuestionBody(
        title: 'Nghe hiểu IT',
        index: 0,
        total: 12,
        hearts: 5,
        timerController: controller,
        timerSeconds: 60,
        question: _question,
        player: player,
        phase: phase,
        selectedOption: phase.isAnswered ? 1 : null,
        hiddenOptions: const {},
        hintUsed: false,
        isCorrect: false,
        timedOut: phase == ListeningPhase.timeout,
        xpGained: null,
        combo: 0,
        scrollController: ScrollController(),
        onClose: () {},
        onVoicePicker: () {},
        onSelect: (_) {},
        onHint: () {},
        onShowScript: () {},
        onContinue: () {},
      ),
    ),
  );
}

void main() {
  late AnimationController controller;
  late DialoguePlayer player;

  setUp(() {
    controller = AnimationController(
      vsync: const TestVSync(),
      duration: const Duration(seconds: 60),
    )..value = 1.0;
    player = DialoguePlayer();
  });

  tearDown(() {
    controller.dispose();
    player.dispose();
  });

  for (final phase in [
    ListeningPhase.listening,
    ListeningPhase.answered,
    ListeningPhase.timeout,
  ]) {
    testWidgets('script KHÔNG được dựng ở giai đoạn ${phase.name}',
        (tester) async {
      await tester.pumpWidget(_host(phase, controller, player));
      await tester.pump();
      expect(find.textContaining(_secret1), findsNothing);
      expect(find.textContaining(_secret2), findsNothing);
      expect(find.text('Script'), findsNothing);
    });
  }

  testWidgets('giai đoạn nghe chỉ có placeholder "Script đã ẩn"',
      (tester) async {
    await tester
        .pumpWidget(_host(ListeningPhase.listening, controller, player));
    await tester.pump();
    expect(find.text('Script đã ẩn'), findsOneWidget);
  });

  testWidgets('sau khi trả lời có nút Scriptを見る nhưng chưa có script',
      (tester) async {
    await tester.pumpWidget(_host(ListeningPhase.answered, controller, player));
    await tester.pump();
    expect(find.text('Scriptを見る'), findsOneWidget);
    expect(find.text('Script đã ẩn'), findsNothing);
  });

  testWidgets('giai đoạn reviewing mới dựng script', (tester) async {
    await tester
        .pumpWidget(_host(ListeningPhase.reviewing, controller, player));
    await tester.pump();
    expect(find.textContaining(_secret1), findsOneWidget);
    expect(find.textContaining(_secret2), findsOneWidget);
  });

  test('chỉ reviewing mới được hiện script', () {
    expect(
      [for (final p in ListeningPhase.values) if (p.showScript) p],
      [ListeningPhase.reviewing],
    );
  });
}
