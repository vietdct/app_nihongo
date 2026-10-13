import 'package:flutter_test/flutter_test.dart';
import 'package:nihongo/domain/entities/grammar_point.dart';
import 'package:nihongo/domain/entities/kanji.dart';
import 'package:nihongo/domain/entities/lesson.dart';
import 'package:nihongo/domain/entities/vocab_meaning.dart';
import 'package:nihongo/domain/entities/vocabulary.dart';
import 'package:nihongo/domain/services/lesson_objectives.dart';

Vocabulary _vocab(String id) => Vocabulary(
      id: id,
      word: '語$id',
      reading: 'ご$id',
      levelId: 'n5',
      meanings: const [VocabMeaning(meaningVi: 'nghĩa')],
    );

Kanji _kanji(String id) => Kanji(
      id: id,
      character: '字',
      meaningVi: const ['chữ'],
      levelId: 'n5',
    );

GrammarPoint _grammar(String id, String title) => GrammarPoint(
      id: id,
      title: title,
      explanation: 'giải thích',
      levelId: 'n5',
    );

void main() {
  group('deriveLessonObjectives', () {
    test('honest-empty when no items', () {
      expect(deriveLessonObjectives(const []), isEmpty);
    });

    test('lists real grammar titles, not generic text', () {
      final items = [
        LessonContentItem.grammar(_grammar('g1', 'N1 は N2 です')),
        LessonContentItem.grammar(_grammar('g2', 'N1 が あります')),
      ];
      final objectives = deriveLessonObjectives(items);
      expect(objectives.first, contains('N1 は N2 です'));
      expect(objectives.first, contains('N1 が あります'));
    });

    test('counts vocab and kanji separately', () {
      final items = [
        LessonContentItem.vocabulary(_vocab('v1')),
        LessonContentItem.vocabulary(_vocab('v2')),
        LessonContentItem.kanji(_kanji('k1')),
      ];
      final objectives = deriveLessonObjectives(items);
      expect(objectives, contains('Học 2 từ vựng mới'));
      expect(objectives, contains('Nhận biết 1 chữ Kanji'));
    });
  });

  group('estimateLessonMinutes', () {
    test('scales with item count, never a fixed constant', () {
      final small = [LessonContentItem.vocabulary(_vocab('v1'))];
      final large = List.generate(
        10,
        (i) => LessonContentItem.vocabulary(_vocab('v$i')),
      );
      expect(estimateLessonMinutes(large), greaterThan(estimateLessonMinutes(small)));
    });

    test('empty lesson still has overhead minutes, not zero', () {
      expect(estimateLessonMinutes(const []), greaterThan(0));
    });
  });

  group('deriveLessonDifficulty', () {
    test('buckets by item count', () {
      expect(
        deriveLessonDifficulty(List.filled(3, LessonContentItem.vocabulary(_vocab('v')))),
        LessonPaceDifficulty.easy,
      );
      expect(
        deriveLessonDifficulty(List.filled(10, LessonContentItem.vocabulary(_vocab('v')))),
        LessonPaceDifficulty.medium,
      );
      expect(
        deriveLessonDifficulty(List.filled(20, LessonContentItem.vocabulary(_vocab('v')))),
        LessonPaceDifficulty.hard,
      );
    });
  });

  test('mẫu câu quá dài chỉ nêu số lượng, không nối thành 1 khối chữ', () {
    final items = [
      for (var i = 0; i < 3; i++)
        LessonContentItem.grammar(_grammar('g$i', 'この度は、ご来社くださり、まことにありがとうございます$i')),
    ];
    expect(deriveLessonObjectives(items), ['Nắm vững 3 mẫu câu trọng tâm']);
  });

  test('mẫu câu ngắn vẫn được liệt kê', () {
    final items = [
      LessonContentItem.grammar(_grammar('g1', 'は')),
      LessonContentItem.grammar(_grammar('g2', 'が')),
    ];
    expect(deriveLessonObjectives(items), ['Sử dụng đúng: は, が']);
  });
}
