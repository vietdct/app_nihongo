import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nihongo/domain/entities/grammar_point.dart';
import 'package:nihongo/domain/entities/grammar_practice_question.dart';
import 'package:nihongo/domain/entities/lesson.dart';
import 'package:nihongo/domain/entities/vocab_meaning.dart';
import 'package:nihongo/domain/entities/vocabulary.dart';
import 'package:nihongo/domain/services/quiz_generator.dart';
import 'package:nihongo/features/lesson/providers/content_providers.dart';
import 'package:nihongo/features/lesson/providers/level_providers.dart';
import 'package:nihongo/features/quiz/providers/grammar_practice_providers.dart';
import 'package:nihongo/features/quiz/providers/quiz_providers.dart';

Vocabulary _v(String word, String reading) => Vocabulary(
      id: word,
      word: word,
      reading: reading,
      levelId: 'lv',
      meanings: [VocabMeaning(meaningVi: 'nghĩa $word')],
    );

GrammarPoint _g(int i) => GrammarPoint(
      id: 'g$i',
      title: '〜パターン$i',
      explanation: 'nghĩa $i',
      levelId: 'lv',
      exampleJp: 'これはパターン$iのれいぶんです。',
    );

GrammarPracticeQuestion _cq(int i) => GrammarPracticeQuestion(
      id: 'c$i',
      levelId: 'lv',
      lessonId: 'L1',
      promptJp: '進捗の詳細は WBS ファイルを（　　）。$i',
      options: const ['ご確認ください', 'ご確認します', 'ご確認になります', 'ご確認いたします'],
      correctIndex: 0,
      explanationVi: 'Lời giải $i',
      source: 'book',
      sourceRef: '第8課 練習① 第4項',
    );

final _vocab = [
  _v('開発環境', 'かいはつかんきょう'),
  _v('障害', 'しょうがい'),
  _v('会議', 'かいぎ'),
  _v('進捗', 'しんちょく'),
  _v('要件', 'ようけん'),
];
final _grammar = [for (var i = 0; i < 6; i++) _g(i)];
final _curated = [for (var i = 0; i < 8; i++) _cq(i)];

ProviderContainer _container(String level, {List<GrammarPracticeQuestion>? curated}) {
  final c = ProviderContainer(overrides: [
    selectedLevelCodeProvider.overrideWith((ref) => level),
    currentLevelIdProvider.overrideWithValue('lv'),
    vocabularyListProvider.overrideWith((ref) => Stream.value(_vocab)),
    grammarListProvider.overrideWith((ref) => Stream.value(_grammar)),
    kanjiListProvider.overrideWith((ref) => Stream.value(const [])),
    lessonItemsProvider.overrideWith(
      (ref, id) => Stream.value([
        for (final v in _vocab) LessonContentItem.vocabulary(v),
        for (final g in _grammar) LessonContentItem.grammar(g),
      ]),
    ),
    grammarPracticeForLevelProvider.overrideWith((ref, id) async => curated ?? _curated),
    grammarPracticeForLessonsProvider.overrideWith((ref, ids) async => curated ?? _curated),
  ]);
  addTearDown(c.dispose);
  return c;
}

Future<List<QuizQuestion>> _load(ProviderContainer c, QuizRequest req) async {
  final sub = c.listen(levelCategoryQuizQuestionsProvider(req), (_, __) {});
  addTearDown(sub.close);
  for (var i = 0; i < 100; i++) {
    await Future<void>.delayed(Duration.zero);
    final v = sub.read();
    if (v.hasValue) return v.requireValue;
    if (v.hasError) fail('${v.error}');
  }
  fail('provider không resolve');
}

void main() {
  const grammarAll = (category: QuizCategory.grammar, lessonIds: null, count: 6);
  const grammarLesson = (category: QuizCategory.grammar, lessonIds: 'L1', count: 6);
  const kanjiAll = (category: QuizCategory.kanji, lessonIds: null, count: 5);
  const kanjiLesson = (category: QuizCategory.kanji, lessonIds: 'L1', count: 5);

  group('chọn chiến lược theo level', () {
    test('IT toàn khóa: Ngữ pháp có câu đã soạn kèm lời giải và nguồn', () async {
      final qs = await _load(_container('IT'), grammarAll);
      final curated = qs.where((q) => q.sourceNote != null).toList();
      expect(curated, isNotEmpty);
      expect(curated.every((q) => q.explanationVi!.startsWith('Lời giải')), isTrue);
    });

    test('IT theo bài: dùng câu đã soạn của đúng bài', () async {
      final qs = await _load(_container('IT'), grammarLesson);
      expect(qs.any((q) => q.sourceNote != null), isTrue);
    });

    test('IT: bảng câu hỏi trống/lỗi vẫn ra đề bằng dạng khác', () async {
      final qs = await _load(_container('IT', curated: const []), grammarAll);
      expect(qs, isNotEmpty);
      expect(qs.every((q) => q.sourceNote == null), isTrue);
    });

    test('N5: không đụng tới câu IT, hành vi cũ', () async {
      final qs = await _load(_container('N5'), grammarAll);
      expect(qs, isNotEmpty);
      expect(qs.every((q) => q.sourceNote == null && q.explanationVi == null), isTrue);
    });

    test('N1: giống N5 — không câu soạn sẵn', () async {
      final qs = await _load(_container('N1'), grammarAll);
      expect(qs.every((q) => q.sourceNote == null), isTrue);
    });

    test('IT: Kanji hỏi cách đọc cả từ, theo bài và toàn khóa', () async {
      for (final req in [kanjiAll, kanjiLesson]) {
        final qs = await _load(_container('IT'), req);
        expect(qs, isNotEmpty);
        for (final q in qs) {
          final v = _vocab.firstWhere((x) => x.word == q.displayJp);
          expect(q.options[q.correctIndex], v.reading);
        }
      }
    });

    test('N5: Kanji không hỏi theo từ (không có Kanji đơn thì rỗng)', () async {
      final qs = await _load(_container('N5'), kanjiAll);
      expect(qs, isEmpty);
    });

    test('IT: Từ vựng vẫn ra đề', () async {
      final qs = await _load(
        _container('IT'),
        (category: QuizCategory.vocabulary, lessonIds: null, count: 4),
      );
      expect(qs, isNotEmpty);
    });
  });
}
