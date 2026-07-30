import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:nihongo/domain/entities/grammar_point.dart';
import 'package:nihongo/domain/services/grammar_practice_generator.dart';

GrammarPoint _grammar(
  String id,
  String title, {
  String? exampleJp,
  List<String> practiceTokens = const [],
  int? practiceBlankIndex,
}) =>
    GrammarPoint(
      id: id,
      title: title,
      explanation: 'giải thích',
      levelId: 'n5',
      exampleJp: exampleJp,
      practiceTokens: practiceTokens,
      practiceBlankIndex: practiceBlankIndex,
    );

void main() {
  group('generatePracticeSession', () {
    test('honest-empty khi pool có ít hơn 2 mẫu có exampleJp', () {
      final pool = [_grammar('g1', 'A', exampleJp: 'これです。')];

      final session = generatePracticeSession(pool: pool);

      expect(session, isEmpty);
    });

    test('mẫu có practiceBlankIndex hợp lệ luôn ra bài fillBlank', () {
      final pool = [
        _grammar(
          'g1',
          'N1 は N2 です',
          exampleJp: 'わたしは学生です。',
          practiceTokens: ['わたし', 'は', '学生', 'です'],
          practiceBlankIndex: 1,
        ),
        _grammar(
          'g2',
          'N1 も N2 です',
          exampleJp: 'わたしも学生です。',
          practiceTokens: ['わたし', 'も', '学生', 'です'],
          practiceBlankIndex: 1,
        ),
      ];

      final session = generatePracticeSession(pool: pool, random: Random(1));

      for (final ex in session) {
        expect(ex.type, GrammarExerciseType.fillBlank);
        expect(ex.blankPrompt, contains('___'));
        expect(ex.options[ex.correctIndex],
            ex.source.practiceTokens[ex.source.practiceBlankIndex!],);
      }
    });

    test(
        'mẫu có practiceTokens (≥3 từ) nhưng không có blankIndex ra bài wordOrder, tiles trùng khớp practiceTokens',
        () {
      final pool = [
        _grammar(
          'g1',
          'N と N',
          exampleJp: '土曜日と日曜日は休みです。',
          practiceTokens: ['土曜日', 'と', '日曜日', 'は', '休み', 'です'],
        ),
        _grammar('g2', 'B', exampleJp: 'それです。'),
      ];

      final session = generatePracticeSession(pool: pool, random: Random(2));

      final wordOrderEx =
          session.firstWhere((e) => e.source.id == 'g1');
      expect(wordOrderEx.type, GrammarExerciseType.wordOrder);
      expect(
        wordOrderEx.tiles.toSet(),
        {'土曜日', 'と', '日曜日', 'は', '休み', 'です'},
      );
      expect(wordOrderEx.tiles.length, 6);
    });

    test('mẫu không có practiceTokens ra bài matchSentence, đáp án đúng nằm trong options', () {
      final pool = [
        _grammar('g1', 'A', exampleJp: 'これはペンです。'),
        _grammar('g2', 'B', exampleJp: 'それは本です。'),
        _grammar('g3', 'C', exampleJp: 'あれは車です。'),
      ];

      final session = generatePracticeSession(pool: pool, random: Random(3));

      for (final ex in session) {
        expect(ex.type, GrammarExerciseType.matchSentence);
        expect(ex.options[ex.correctIndex], ex.source.exampleJp);
      }
    });

    test('fillBlank/matchSentence luôn có đáp án đúng nằm trong options qua nhiều seed', () {
      final pool = [
        _grammar('g1', 'A', exampleJp: 'これはペンです。'),
        _grammar('g2', 'B', exampleJp: 'それは本です。'),
        _grammar('g3', 'C', exampleJp: 'あれは車です。'),
        _grammar(
          'g4',
          'D',
          exampleJp: 'わたしは学生です。',
          practiceTokens: ['わたし', 'は', '学生', 'です'],
          practiceBlankIndex: 1,
        ),
        _grammar(
          'g5',
          'E',
          exampleJp: 'わたしも学生です。',
          practiceTokens: ['わたし', 'も', '学生', 'です'],
          practiceBlankIndex: 1,
        ),
      ];

      for (var seed = 0; seed < 20; seed++) {
        final session =
            generatePracticeSession(pool: pool, random: Random(seed));
        for (final ex in session) {
          if (ex.type == GrammarExerciseType.wordOrder) continue;
          expect(ex.correctIndex, greaterThanOrEqualTo(0));
          expect(ex.correctIndex, lessThan(ex.options.length));
        }
      }
    });

    test('không sinh quá exerciseCount câu hỏi', () {
      final pool = [
        _grammar('g1', 'A', exampleJp: 'これはペンです。'),
        _grammar('g2', 'B', exampleJp: 'それは本です。'),
        _grammar('g3', 'C', exampleJp: 'あれは車です。'),
      ];

      final session =
          generatePracticeSession(pool: pool, exerciseCount: 2, random: Random(4));

      expect(session.length, 2);
    });
  });
}
