import 'package:flutter_test/flutter_test.dart';
import 'package:nihongo/domain/entities/grammar_point.dart';
import 'package:nihongo/domain/entities/lesson.dart';
import 'package:nihongo/domain/entities/vocab_meaning.dart';
import 'package:nihongo/domain/entities/vocabulary.dart';
import 'package:nihongo/domain/services/lesson_mission_generator.dart';

const _lesson = Lesson(id: 'l1', title: 'Bài 1', levelId: 'n5', orderIndex: 1);

Vocabulary _vocab(String id) => Vocabulary(
      id: id,
      word: '言葉$id',
      reading: 'ことば$id',
      levelId: 'n5',
      meanings: const [VocabMeaning(meaningVi: 'nghĩa')],
    );

const GrammarPoint _grammarBase = GrammarPoint(
  id: 'g0',
  title: 'は',
  explanation: 'giải thích',
  levelId: 'n5',
);

GrammarPoint _grammar(String id) => GrammarPoint(
      id: id,
      title: 'mẫu $id',
      explanation: 'giải thích',
      levelId: 'n5',
    );

void main() {
  group('generateLessonMission', () {
    test('chọn tối đa 3 từ vựng + 2 ngữ pháp từ nội dung thật', () {
      final items = [
        for (var i = 0; i < 5; i++) LessonContentItem.vocabulary(_vocab('v$i')),
        for (var i = 0; i < 4; i++) LessonContentItem.grammar(_grammar('g$i')),
      ];

      final mission = generateLessonMission(lesson: _lesson, items: items);

      expect(mission, isNotNull);
      expect(mission!.lessonTitle, 'Bài 1');
      expect(mission.targetVocab.length, 3);
      expect(mission.targetGrammar.length, 2);
      expect(mission.targetVocab.map((v) => v.id), ['v0', 'v1', 'v2']);
      expect(mission.targetGrammar.map((g) => g.id), ['g0', 'g1']);
    });

    test('honest-empty khi bài không có ngữ pháp', () {
      final items = [LessonContentItem.vocabulary(_vocab('v0'))];

      expect(generateLessonMission(lesson: _lesson, items: items), isNull);
    });

    test('honest-empty khi bài không có từ vựng', () {
      const items = [LessonContentItem.grammar(_grammarBase)];

      expect(generateLessonMission(lesson: _lesson, items: items), isNull);
    });

    test('honest-empty khi bài không có nội dung nào', () {
      expect(generateLessonMission(lesson: _lesson, items: const []), isNull);
    });

    test('bài có ít hơn mức tối đa vẫn dùng hết những gì có', () {
      final items = [
        LessonContentItem.vocabulary(_vocab('v0')),
        LessonContentItem.grammar(_grammar('g0')),
      ];

      final mission = generateLessonMission(lesson: _lesson, items: items);

      expect(mission!.targetVocab.length, 1);
      expect(mission.targetGrammar.length, 1);
      expect(mission.totalTargets, 2);
    });
  });
}
