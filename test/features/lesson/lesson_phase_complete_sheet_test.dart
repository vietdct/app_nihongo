import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nihongo/domain/entities/lesson.dart';
import 'package:nihongo/domain/entities/vocab_meaning.dart';
import 'package:nihongo/domain/entities/vocabulary.dart';
import 'package:nihongo/domain/services/quiz_generator.dart';
import 'package:nihongo/features/lesson/lesson_runner_steps.dart';
import 'package:nihongo/features/lesson/widgets/lesson_phase_complete_sheet.dart';

const _q = QuizQuestion(
  promptVi: 'Hỏi',
  displayJp: '語',
  options: ['a', 'b'],
  correctIndex: 0,
);

void main() {
  final vocab = Vocabulary(
    id: 'v1',
    word: '語',
    reading: 'ご',
    levelId: 'n5',
    meanings: const [VocabMeaning(meaningVi: 'từ')],
  );
  final steps = <LessonStep>[
    const LessonIntroStep(),
    LessonUnderstandStep(LessonContentItem.vocabulary(vocab)),
    const LessonListeningStep(_q),
    const LessonListeningStep(_q),
    const LessonExerciseStep(LessonQuizPracticeItem(_q)),
  ];

  test('phaseSummaryLines đếm đúng theo pha', () {
    expect(phaseSummaryLines(steps, LessonPhase.understand),
        ['Đã xem 1 thẻ', 'Từ vựng: 1']);
    expect(phaseSummaryLines(steps, LessonPhase.practice),
        ['Câu nghe: 2', 'Câu luyện tập: 1']);
    expect(phaseSummaryLines(steps, LessonPhase.input), isEmpty);
  });

  testWidgets('sheet hiện tiêu đề, số liệu và trả true khi bấm sang pha kế',
      (tester) async {
    bool? result;
    await tester.pumpWidget(MaterialApp(
      home: Builder(
        builder: (ctx) => TextButton(
          onPressed: () async => result = await showPhaseCompleteSheet(
            ctx,
            done: LessonPhase.practice,
            next: LessonPhase.apply,
            lines: const ['Câu nghe: 2'],
          ),
          child: const Text('go'),
        ),
      ),
    ));
    await tester.tap(find.text('go'));
    await tester.pumpAndSettle();
    expect(find.text('PRACTICE HOÀN THÀNH'), findsOneWidget);
    expect(find.text('Câu nghe: 2'), findsOneWidget);
    await tester.tap(find.text('Sang APPLY →'));
    await tester.pumpAndSettle();
    expect(result, true);
  });
}
