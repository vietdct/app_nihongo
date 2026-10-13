import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nihongo/core/services/dialogue_player.dart';
import 'package:nihongo/domain/entities/listening_dialogue.dart';
import 'package:nihongo/shared/dialogue_script_view.dart';

List<ListeningTurn> turns(String speakers) => [
      for (var i = 0; i < speakers.length; i++)
        ListeningTurn(speaker: speakers[i], jp: 'câu $i'),
    ];

Future<DialoguePlayer> pump(
  WidgetTester tester,
  List<ListeningTurn> t, {
  bool controls = false,
}) async {
  final player = DialoguePlayer();
  addTearDown(player.dispose);
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: controls
              ? DialogueAudioControls(turns: t, player: player)
              : DialogueScriptCard(turns: t, player: player),
        ),
      ),
    ),
  );
  return player;
}

void main() {
  testWidgets('script 1 người nói: không hiện avatar người nói',
      (tester) async {
    await pump(tester, turns('AAA'));
    expect(find.byType(CircleAvatar), findsNothing);
    expect(find.text('câu 2'), findsOneWidget);
  });

  testWidgets('script 3 người nói: avatar A/B/C, mỗi dòng có nút nghe riêng',
      (tester) async {
    await pump(tester, turns('ABCA'));
    expect(find.byType(CircleAvatar), findsNWidgets(4));
    for (final s in ['A', 'B', 'C']) {
      expect(find.text(s), findsWidgets);
    }
    expect(find.byTooltip('Nghe lượt này'), findsNWidgets(4));
    // 3 người → 3 màu khác nhau.
    expect(
      {for (var i = 0; i < 3; i++) speakerStyle(i).color}.length,
      3,
    );
  });

  testWidgets('đang phát: nhãn có người nói và tiến độ toàn hội thoại',
      (tester) async {
    final player = await pump(tester, turns('ABA'), controls: true);
    player.state.value = DialoguePlayState.playing;
    player.currentTurn.value = 1;
    await tester.pump();
    expect(find.text('Đang phát · B · 2/3'), findsOneWidget);
  });

  testWidgets('1 người nói: nhãn không kèm tên người nói', (tester) async {
    final player = await pump(tester, turns('AA'), controls: true);
    player.state.value = DialoguePlayState.playing;
    player.currentTurn.value = 0;
    await tester.pump();
    expect(find.text('Đang phát · 1/2'), findsOneWidget);
  });
}
