import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:nihongo/domain/entities/grammar_point.dart';
import 'package:nihongo/domain/entities/grammar_practice_question.dart';
import 'package:nihongo/domain/entities/vocab_meaning.dart';
import 'package:nihongo/domain/entities/vocabulary.dart';
import 'package:nihongo/domain/services/practice_strategy.dart';
import 'package:nihongo/domain/services/quiz_generator.dart';

Vocabulary _v(
  String word,
  String reading, {
  String meaning = 'nghĩa',
  String? exampleJp,
  String? exampleVi,
  String? pos,
}) =>
    Vocabulary(
      id: word + reading,
      word: word,
      reading: reading,
      levelId: 'it',
      partOfSpeech: pos,
      meanings: [
        VocabMeaning(
          meaningVi: meaning,
          exampleJp: exampleJp,
          exampleVi: exampleVi,
        ),
      ],
    );

GrammarPoint _g(String id, String title, String? example) => GrammarPoint(
      id: id,
      title: title,
      explanation: 'nghĩa $id',
      levelId: 'it',
      exampleJp: example,
    );

GrammarPracticeQuestion _cq(
  String id, {
  List<String> options = const ['ご確認ください', 'ご確認します', 'ご確認になります', 'ご確認いたします'],
  int correct = 0,
}) =>
    GrammarPracticeQuestion(
      id: id,
      levelId: 'it',
      promptJp: '進捗の詳細は WBS ファイルを（　　）。$id',
      options: options,
      correctIndex: correct,
      explanationVi: 'Lời giải $id',
      source: 'book',
      sourceRef: '第8課 練習① 第4項',
    );

final _itVocab = [
  _v('開発環境', 'かいはつかんきょう', meaning: 'môi trường phát triển'),
  _v('障害', 'しょうがい', meaning: 'sự cố'),
  _v('会議', 'かいぎ', meaning: 'cuộc họp'),
  _v('進捗', 'しんちょく', meaning: 'tiến độ'),
  _v('要件', 'ようけん', meaning: 'yêu cầu'),
  _v('テスト', 'てすと', meaning: 'kiểm thử'), // không có Kanji
];

void main() {
  group('chọn chiến lược theo level', () {
    test('IT → it, còn lại → jlpt', () {
      expect(practiceProfileFor('IT'), PracticeProfile.it);
      for (final c in ['N5', 'N4', 'N3', 'N2', 'N1', null]) {
        expect(practiceProfileFor(c), PracticeProfile.jlpt);
      }
    });

    test('đúng lớp chiến lược cho từng level', () {
      expect(
        practiceStrategyFor(PracticeProfile.it),
        isA<ItPracticeStrategy>(),
      );
      expect(
        practiceStrategyFor(PracticeProfile.jlpt),
        isA<JlptPracticeStrategy>(),
      );
    });
  });

  group('câu Ngữ pháp điền chỗ trống đã soạn', () {
    final gen = QuizGenerator(random: Random(3));

    test('giữ đáp án đúng sau khi xáo, kèm lời giải và nguồn', () {
      final qs = gen.generateCuratedGrammarCloze(
        pool: [_cq('a'), _cq('b'), _cq('c')],
        questionCount: 3,
      );
      expect(qs, hasLength(3));
      for (final q in qs) {
        expect(q.options.toSet(), {
          'ご確認ください',
          'ご確認します',
          'ご確認になります',
          'ご確認いたします',
        });
        expect(q.options[q.correctIndex], 'ご確認ください');
        expect(q.explanationVi, startsWith('Lời giải'));
        expect(q.sourceNote, contains('第8課 練習① 第4項'));
        expect(q.sourceNote, contains('trích từ sách'));
      }
    });

    test('vị trí đáp án đúng thay đổi giữa các câu', () {
      final pool = [for (var i = 0; i < 40; i++) _cq('q$i')];
      final qs = gen.generateCuratedGrammarCloze(pool: pool, questionCount: 40);
      expect(qs.map((q) => q.correctIndex).toSet().length, greaterThan(1));
    });

    test('bỏ câu dữ liệu hỏng (nhiễu trùng / đáp án ngoài danh sách)', () {
      final qs = gen.generateCuratedGrammarCloze(
        pool: [
          _cq('ok'),
          _cq('dup', options: const ['a', 'a', 'b', 'c']),
          _cq('out', correct: 9),
        ],
      );
      expect(qs, hasLength(1));
      expect(qs.single.displayJp, contains('ok'));
    });

    test('tryParse bỏ dòng thiếu dữ liệu thay vì ném lỗi', () {
      expect(GrammarPracticeQuestion.tryParse({'id': 'x'}), isNull);
      expect(
        GrammarPracticeQuestion.tryParse({
          'id': 'x',
          'level_id': 'l',
          'prompt_jp': '（　　）',
          'options': ['a', 'b'],
          'correct_index': 1,
        }),
        isNotNull,
      );
    });
  });

  group('chiến lược Ngữ pháp', () {
    final items = [
      _g('1', '〜について', 'プロジェクトについて説明します。'),
      _g('2', '〜場合は', 'エラーが出た場合は連絡します。'),
      _g('3', '〜ために', '品質のためにレビューします。'),
      _g('4', '〜前に', '会議の前に準備します。'),
    ];
    final curated = [for (var i = 0; i < 6; i++) _cq('c$i')];

    test('IT: ưu tiên câu đã soạn, có lời giải', () {
      final qs = ItPracticeStrategy(
        QuizGenerator(random: Random(1)),
        random: Random(1),
      ).grammar(items, 6, curated: curated);
      expect(qs, hasLength(6));
      expect(qs.where((q) => q.explanationVi != null), isNotEmpty);
    });

    test('IT: chưa có dữ liệu soạn sẵn thì vẫn ra đề, không lời giải bịa', () {
      final qs = ItPracticeStrategy(
        QuizGenerator(random: Random(1)),
        random: Random(1),
      ).grammar(items, 4);
      expect(qs, isNotEmpty);
      expect(qs.every((q) => q.explanationVi == null), isTrue);
    });

    test('N5–N1: không dùng câu IT dù được truyền vào', () {
      final qs = JlptPracticeStrategy(QuizGenerator(random: Random(1)))
          .grammar(items, 4, curated: curated);
      expect(qs, isNotEmpty);
      expect(qs.every((q) => q.explanationVi == null), isTrue);
      expect(qs.every((q) => q.sourceNote == null), isTrue);
    });
  });

  group('Kanji IT: cách đọc cả từ', () {
    test('đáp án đúng là cách đọc thật, 4 lựa chọn khác nhau', () {
      final qs = generateWordReadingQuestions(
        pool: _itVocab,
        questionCount: 10,
        random: Random(5),
      );
      expect(qs, isNotEmpty);
      for (final q in qs) {
        final v = _itVocab.firstWhere((x) => x.word == q.displayJp);
        expect(q.options, hasLength(4));
        expect(q.options.toSet(), hasLength(4));
        expect(q.options[q.correctIndex], v.reading);
        expect(q.explanationVi, contains(v.reading));
        // Không lộ cách đọc trước khi trả lời.
        expect(q.readingFurigana, isNull);
      }
    });

    test('bỏ từ không có Kanji', () {
      final qs = generateWordReadingQuestions(
        pool: _itVocab,
        questionCount: 20,
        random: Random(5),
      );
      expect(qs.any((q) => q.displayJp == 'テスト'), isFalse);
    });

    test('bỏ từ có nhiều cách đọc trong dữ liệu (tránh 2 đáp án đúng)', () {
      final pool = [
        _v('今日', 'きょう'),
        _v('今日', 'こんにち'),
        ..._itVocab,
      ];
      final qs = generateWordReadingQuestions(
        pool: pool,
        questionCount: 20,
        random: Random(5),
      );
      expect(qs.any((q) => q.displayJp == '今日'), isFalse);
    });

    test('biến thể cách đọc: nhầm nguyên âm, trường âm, đục/trong, っ', () {
      final v = readingVariants('かいはつかんきょう');
      expect(v, contains('かいほつかんきょう')); // は → ほ
      expect(v, contains('かいはつかんきょ')); // ょう → ょ
      expect(v, contains('かいはつけんきょう')); // か → け
      expect(v, isNot(contains('かいはつかんきょう')));
      expect(readingVariants('がっこう'), contains('がこう'));
      expect(readingVariants('かいぎ'), contains('かいき')); // ぎ → き? thử đục/trong
    });

    test('không có từ đủ điều kiện thì chiến lược IT rơi về Kanji đơn', () {
      final qs = ItPracticeStrategy(QuizGenerator(random: Random(1)))
          .kanji(kanjiItems: const [], vocabulary: [_v('テスト', 'てすと')], count: 5);
      expect(qs, isEmpty);
    });

    test('N5–N1: không hỏi theo từ, giữ hướng Kanji đơn', () {
      final qs = JlptPracticeStrategy(QuizGenerator(random: Random(1)))
          .kanji(kanjiItems: const [], vocabulary: _itVocab, count: 5);
      expect(qs, isEmpty);
    });

    test('containsKanji', () {
      expect(containsKanji('開発環境'), isTrue);
      expect(containsKanji('テスト'), isFalse);
      expect(containsKanji('お願い'), isTrue);
    });
  });

  group('Từ vựng IT: điền từ vào câu ví dụ', () {
    test('có lời giải gồm câu đầy đủ + bản dịch, nhiễu ưu tiên cùng loại từ', () {
      final pool = [
        _v('障害', 'しょうがい',
            meaning: 'sự cố',
            exampleJp: '本番環境で障害が発生しました。',
            exampleVi: 'Đã xảy ra sự cố ở môi trường production.',
            pos: 'noun'),
        _v('会議', 'かいぎ', pos: 'noun'),
        _v('進捗', 'しんちょく', pos: 'noun'),
        _v('確認する', 'かくにんする', pos: 'verb'),
        _v('報告する', 'ほうこくする', pos: 'verb'),
      ];
      final qs = QuizGenerator(random: Random(2))
          .generateVocabCloze(pool: pool, questionCount: 5);
      expect(qs, hasLength(1));
      final q = qs.single;
      expect(q.displayJp, contains('＿＿＿'));
      expect(q.options[q.correctIndex], '障害');
      expect(q.explanationVi, contains('本番環境で障害が発生しました。'));
      expect(q.explanationVi, contains('Đã xảy ra sự cố'));
      // 3 nhiễu: 2 danh từ cùng loại trước, rồi mới tới từ khác loại.
      final nounOptions = q.options.where((o) => ['障害', '会議', '進捗'].contains(o));
      expect(nounOptions, hasLength(3));
    });
  });
}
