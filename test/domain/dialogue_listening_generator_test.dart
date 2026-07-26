import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:nihongo/domain/entities/listening_dialogue.dart';
import 'package:nihongo/domain/services/dialogue_listening_generator.dart';

ListeningDialogue _dialogue(
  String id, {
  int turnCount = 2,
  List<String> options = const ['Đúng', 'Sai 1', 'Sai 2', 'Sai 3'],
  int correctIndex = 0,
}) =>
    ListeningDialogue(
      id: id,
      levelId: 'n5',
      turns: [
        for (var i = 0; i < turnCount; i++)
          ListeningTurn(speaker: i.isEven ? 'A' : 'B', jp: 'câu $id-$i'),
      ],
      questionVi: 'Câu hỏi cho $id?',
      options: options,
      correctIndex: correctIndex,
    );

void main() {
  group('DialogueListeningGenerator', () {
    test('sinh câu hỏi từ hội thoại thật, giữ nguyên turns', () {
      final dialogues = [
        _dialogue('d1', turnCount: 2),
        _dialogue('d2', turnCount: 6),
        _dialogue('d3', turnCount: 4),
      ];

      final questions =
          const DialogueListeningGenerator().generate(dialogues: dialogues);

      expect(questions.length, 3);
      final turnCounts = questions.map((q) => q.dialogueTurns!.length).toSet();
      expect(turnCounts, {2, 6, 4});
    });

    test('correctIndex vẫn trỏ đúng đáp án thật sau khi xáo trộn', () {
      final dialogues = [
        _dialogue('d1', options: const ['A đúng', 'B sai', 'C sai', 'D sai']),
        _dialogue('d2', options: const ['E đúng', 'F sai', 'G sai', 'H sai']),
      ];

      final questions = DialogueListeningGenerator(random: Random(7))
          .generate(dialogues: dialogues);

      for (final q in questions) {
        final expected = q.promptVi.contains('d1') ? 'A đúng' : 'E đúng';
        expect(q.options[q.correctIndex], expected);
      }
    });

    test('honest-empty-state khi có ít hơn 2 hội thoại hợp lệ', () {
      final dialogues = [_dialogue('d1')];

      final questions =
          const DialogueListeningGenerator().generate(dialogues: dialogues);

      expect(questions, isEmpty);
    });

    test('loại hội thoại thiếu turns hoặc thiếu câu hỏi', () {
      const invalid = ListeningDialogue(
        id: 'bad',
        levelId: 'n5',
        turns: [],
        questionVi: 'Câu hỏi?',
        options: ['A', 'B'],
        correctIndex: 0,
      );
      final dialogues = [_dialogue('d1'), _dialogue('d2'), invalid];

      final questions =
          const DialogueListeningGenerator().generate(dialogues: dialogues);

      expect(questions.length, 2);
    });

    test('random chọn tập con mỗi lần gọi khi nhiều hơn questionCount', () {
      final dialogues = [
        for (var i = 0; i < 10; i++) _dialogue('d$i'),
      ];

      final a = DialogueListeningGenerator(random: Random(1))
          .generate(dialogues: dialogues, questionCount: 3);
      final b = DialogueListeningGenerator(random: Random(2))
          .generate(dialogues: dialogues, questionCount: 3);

      expect(a.length, 3);
      expect(b.length, 3);
      expect(a.map((q) => q.promptVi), isNot(equals(b.map((q) => q.promptVi))));
    });
  });
}
