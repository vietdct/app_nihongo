import 'package:flutter_test/flutter_test.dart';
import 'package:nihongo/domain/entities/grammar_point.dart';
import 'package:nihongo/domain/entities/lesson.dart';
import 'package:nihongo/domain/entities/vocab_meaning.dart';
import 'package:nihongo/domain/entities/vocabulary.dart';
import 'package:nihongo/domain/services/grammar_practice_generator.dart';
import 'package:nihongo/domain/services/lesson_mission_generator.dart';
import 'package:nihongo/domain/services/quiz_generator.dart';
import 'package:nihongo/features/lesson/lesson_runner_steps.dart';

Vocabulary _vocab(String id) => Vocabulary(
      id: id,
      word: '語$id',
      reading: 'ご$id',
      levelId: 'n5',
      meanings: const [VocabMeaning(meaningVi: 'nghĩa')],
    );

QuizQuestion _question() => const QuizQuestion(
      promptVi: 'Từ này có nghĩa là gì?',
      displayJp: '語',
      options: ['nghĩa 1', 'nghĩa 2'],
      correctIndex: 0,
    );

GrammarExercise _exercise() => const GrammarExercise(
      type: GrammarExerciseType.matchSentence,
      source: GrammarPoint(
        id: 'g1',
        title: 'は',
        explanation: 'giải thích',
        levelId: 'n5',
      ),
      options: ['câu 1', 'câu 2'],
      correctIndex: 0,
    );

const _mission = LessonMission(
  lessonTitle: 'Bài 1',
  targetVocab: [
    Vocabulary(id: 'v1', word: '語1', reading: 'ご1', levelId: 'n5', meanings: [VocabMeaning(meaningVi: 'nghĩa')]),
  ],
  targetGrammar: [
    GrammarPoint(id: 'g1', title: 'は', explanation: 'giải thích', levelId: 'n5'),
  ],
);

void main() {
  group('buildLessonSteps', () {
    test('honest-empty when no items, regardless of practice data', () {
      final steps = buildLessonSteps(
        items: const [],
        listeningQuestions: [_question()],
        practiceItems: [LessonQuizPracticeItem(_question())],
      );
      expect(steps, isEmpty);
    });

    test('omits Listening/Exercise steps when no practice data available, ends with Review', () {
      final items = [LessonContentItem.vocabulary(_vocab('v1'))];
      final steps = buildLessonSteps(items: items);
      expect(steps.whereType<LessonListeningStep>(), isEmpty);
      expect(steps.whereType<LessonExerciseStep>(), isEmpty);
      expect(steps.last, isA<LessonReviewStep>());
      expect((steps.last as LessonReviewStep).items, items);
    });

    test('places Listening then Exercise then Mission then Review steps after Understand', () {
      final items = [LessonContentItem.vocabulary(_vocab('v1'))];
      final steps = buildLessonSteps(
        items: items,
        listeningQuestions: [_question()],
        practiceItems: [LessonQuizPracticeItem(_question()), LessonGrammarPracticeItem(_exercise())],
        mission: _mission,
      );

      final types = steps.map((s) => s.runtimeType).toList();
      expect(types, [
        LessonIntroStep,
        LessonObjectivesStep,
        LessonUnderstandStep,
        LessonListeningStep,
        LessonExerciseStep,
        LessonExerciseStep,
        LessonMissionStep,
        LessonReviewStep,
      ]);
    });

    test('omits Mission step when mission is null', () {
      final steps = buildLessonSteps(items: [LessonContentItem.vocabulary(_vocab('v1'))]);
      expect(steps.whereType<LessonMissionStep>(), isEmpty);
    });

    test('Review step uses reviewItems when provided, falls back to items otherwise', () {
      final items = [LessonContentItem.vocabulary(_vocab('v1')), LessonContentItem.vocabulary(_vocab('v2'))];
      final shuffled = [items[1], items[0]];

      final withOverride = buildLessonSteps(items: items, reviewItems: shuffled);
      expect((withOverride.last as LessonReviewStep).items, shuffled);

      final withoutOverride = buildLessonSteps(items: items);
      expect((withoutOverride.last as LessonReviewStep).items, items);
    });
  });

  group('phaseOfStep', () {
    test('Listening and Exercise steps are in the Practice phase', () {
      expect(phaseOfStep(LessonListeningStep(_question())), LessonPhase.practice);
      expect(phaseOfStep(LessonExerciseStep(LessonQuizPracticeItem(_question()))), LessonPhase.practice);
    });

    test('Mission step is in the Apply phase', () {
      expect(phaseOfStep(const LessonMissionStep(_mission)), LessonPhase.apply);
    });

    test('Review step is in the Review phase', () {
      expect(phaseOfStep(const LessonReviewStep([])), LessonPhase.review);
    });
  });
}
