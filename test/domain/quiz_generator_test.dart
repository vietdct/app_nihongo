import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:nihongo/domain/entities/grammar_point.dart';
import 'package:nihongo/domain/entities/kaiwa_message.dart';
import 'package:nihongo/domain/entities/kanji.dart';
import 'package:nihongo/domain/entities/lesson.dart';
import 'package:nihongo/domain/entities/review_mistake.dart';
import 'package:nihongo/domain/entities/vocab_meaning.dart';
import 'package:nihongo/domain/entities/vocabulary.dart';
import 'package:nihongo/domain/services/quiz_generator.dart';

Vocabulary _vocab(String id, String word, String meaning,
        {String reading = 'よみ',}) =>
    Vocabulary(
      id: id,
      word: word,
      reading: reading,
      levelId: 'n5',
      meanings: meaning.isEmpty ? const [] : [VocabMeaning(meaningVi: meaning)],
    );

Kanji _kanji(String id, String character, String meaning,
        {List<String> onyomi = const [], List<String> kunyomi = const [],}) =>
    Kanji(
      id: id,
      character: character,
      levelId: 'n5',
      meaningVi: meaning.isEmpty ? const [] : [meaning],
      onyomi: onyomi,
      kunyomi: kunyomi,
    );

GrammarPoint _grammar(String id, String title, String explanation) =>
    GrammarPoint(
      id: id,
      title: title,
      explanation: explanation,
      levelId: 'n5',
    );

GrammarPoint _grammarFillBlank(
  String id,
  List<String> practiceTokens,
  int practiceBlankIndex,
) =>
    GrammarPoint(
      id: id,
      title: id,
      explanation: 'giải thích',
      levelId: 'n5',
      practiceTokens: practiceTokens,
      practiceBlankIndex: practiceBlankIndex,
    );

GrammarPoint _grammarWithExample(String id, String exampleJp, String exampleVi) =>
    GrammarPoint(
      id: id,
      title: id,
      explanation: 'giải thích',
      levelId: 'n5',
      exampleJp: exampleJp,
      exampleVi: exampleVi,
    );

ReviewMistake _mistake(
  String id,
  String sourceType,
  String correctAnswer, {
  String? originalAnswer,
}) =>
    ReviewMistake(
      id: id,
      sourceType: sourceType,
      sourceId: 'src-$id',
      correctAnswer: correctAnswer,
      occurrenceCount: 1,
      bookmarked: false,
      updatedAt: DateTime(2026, 8, 4),
      originalAnswer: originalAnswer,
    );

KaiwaMessage _kaiwaReviewable(String id, String contentJp, String betterPhrasing) =>
    KaiwaMessage(
      id: id,
      role: KaiwaMessageRole.user,
      contentJp: contentJp,
      feedback: KaiwaFeedback(
        rating: 3,
        naturalness: 'ổn',
        grammar: 'ổn',
        vocabulary: 'ổn',
        politeness: 'ổn',
        nativeLikeness: 'ổn',
        explanation: 'giải thích',
        commonMistake: 'lỗi thường gặp',
        betterPhrasing: betterPhrasing,
      ),
    );

GrammarPoint _grammarFull(
  String id,
  String title, {
  String? exampleJp,
  String? exampleVi,
  List<String> practiceTokens = const [],
}) =>
    GrammarPoint(
      id: id,
      title: title,
      explanation: 'giải thích',
      levelId: 'n5',
      exampleJp: exampleJp,
      exampleVi: exampleVi,
      practiceTokens: practiceTokens,
    );

/// Tập hợp mọi giá trị trục (term/nghĩa/cách đọc) có thể xuất hiện trong 1
/// câu hỏi sinh từ [item] — dùng để xác nhận cặp (displayJp, đáp án đúng)
/// luôn thuộc về CÙNG 1 item nguồn, bất kể generator chọn chiều hỏi nào
/// (chiều hỏi giờ ngẫu nhiên — xem quiz_generator.dart).
class _KnownItem {
  const _KnownItem(this.term, this.meaning, this.reading);
  final String term;
  final String meaning;
  final String? reading;

  bool hasField(String value) =>
      value == term || value == meaning || value == reading;
}

void main() {
  group('QuizGenerator', () {
    test('sinh đúng số câu hỏi khi pool đủ lớn, mỗi câu 4 lựa chọn', () {
      final pool = [
        LessonContentItem.vocabulary(_vocab('v1', '買い物', 'Mua sắm')),
        LessonContentItem.vocabulary(_vocab('v2', '食べる', 'Ăn')),
        LessonContentItem.kanji(_kanji('k1', '買', 'Mua')),
        LessonContentItem.kanji(_kanji('k2', '食', 'Ăn uống')),
        LessonContentItem.grammar(_grammar('g1', '〜てください', 'Nhờ ai đó làm gì')),
        LessonContentItem.grammar(
            _grammar('g2', '〜ないでください', 'Nhờ ai đó đừng làm gì'),),
      ];

      final questions = const QuizGenerator(random: null)
          .generate(pool: pool, questionCount: 10);

      expect(questions.length, 6);
      for (final q in questions) {
        expect(q.options.length, greaterThanOrEqualTo(2));
        expect(q.options.length, lessThanOrEqualTo(4));
      }
    });

    test(
        'correctIndex trỏ đúng đáp án thật của item nguồn, dù chiều hỏi nào được chọn',
        () {
      final items = {
        '買い物': const _KnownItem('買い物', 'Mua sắm', 'かいもの'),
        '食べる': const _KnownItem('食べる', 'Ăn', 'たべる'),
        '買': const _KnownItem('買', 'Mua', null),
        '食': const _KnownItem('食', 'Ăn uống', null),
      };
      final pool = [
        LessonContentItem.vocabulary(
            _vocab('v1', '買い物', 'Mua sắm', reading: 'かいもの'),),
        LessonContentItem.vocabulary(
            _vocab('v2', '食べる', 'Ăn', reading: 'たべる'),),
        LessonContentItem.kanji(_kanji('k1', '買', 'Mua')),
        LessonContentItem.kanji(_kanji('k2', '食', 'Ăn uống')),
      ];

      final questions = QuizGenerator(random: Random(42)).generate(pool: pool);

      for (final q in questions) {
        final sourceItem =
            items.values.firstWhere((it) => it.hasField(q.displayJp));
        final correctAnswer = q.options[q.correctIndex];
        expect(sourceItem.hasField(correctAnswer), isTrue,
            reason: 'stem "${q.displayJp}" và đáp án đúng "$correctAnswer" '
                'phải cùng thuộc 1 item nguồn',);
      }
    });

    test(
        'khử trùng lặp nghĩa — không có 2 option giống hệt nhau (case-insensitive)',
        () {
      final pool = [
        LessonContentItem.vocabulary(_vocab('v1', '高い', 'Đắt')),
        LessonContentItem.vocabulary(_vocab(
            'v2', '安い', 'đắt ',),), // trùng nghĩa, khác hoa/thường + khoảng trắng
        LessonContentItem.vocabulary(_vocab('v3', '大きい', 'To')),
        LessonContentItem.vocabulary(_vocab('v4', '小さい', 'Nhỏ')),
      ];

      final questions = const QuizGenerator().generate(pool: pool);

      for (final q in questions) {
        final normalized =
            q.options.map((o) => o.trim().toLowerCase()).toList();
        expect(normalized.toSet().length, normalized.length,
            reason: 'options bị trùng: ${q.options}',);
      }
    });

    test('honest-empty-state khi pool có ít hơn 2 item hợp lệ', () {
      final pool = [
        LessonContentItem.vocabulary(_vocab('v1', '買い物', 'Mua sắm')),
      ];

      final questions = const QuizGenerator().generate(pool: pool);

      expect(questions, isEmpty);
    });

    test('honest-empty-state khi item có nghĩa rỗng bị loại, còn lại không đủ',
        () {
      final pool = [
        LessonContentItem.vocabulary(_vocab('v1', '買い物', 'Mua sắm')),
        LessonContentItem.vocabulary(
            _vocab('v2', '謎', ''),), // meanings rỗng -> primaryMeaning == ''
      ];

      final questions = const QuizGenerator().generate(pool: pool);

      expect(questions, isEmpty);
    });

    test('số lựa chọn co lại còn tối đa đúng số item khi pool chỉ có 2-3 item hợp lệ',
        () {
      final pool = [
        LessonContentItem.vocabulary(_vocab('v1', '買い物', 'Mua sắm')),
        LessonContentItem.vocabulary(_vocab('v2', '食べる', 'Ăn')),
        LessonContentItem.vocabulary(_vocab('v3', '飲む', 'Uống')),
      ];

      final questions = const QuizGenerator().generate(pool: pool);

      expect(questions.length, 3);
      for (final q in questions) {
        expect(q.options.length, lessThanOrEqualTo(3));
        expect(q.options.length, greaterThanOrEqualTo(2));
      }
    });

    test(
        'không bao giờ sinh câu hỏi chỉ có 1 lựa chọn (luôn có ít nhất 1 đáp án nhiễu)',
        () {
      // Mọi item dùng chung 1 cách đọc 'よみ' — nếu generator không loại trừ
      // trục cách đọc khi không đủ giá trị khác nhau, câu hỏi kiểu
      // termToReading/readingToTerm sẽ chỉ còn đúng 1 lựa chọn (vô nghĩa).
      final pool = [
        LessonContentItem.vocabulary(_vocab('v1', '買い物', 'Mua sắm')),
        LessonContentItem.vocabulary(_vocab('v2', '食べる', 'Ăn')),
      ];

      for (var seed = 0; seed < 20; seed++) {
        final questions =
            QuizGenerator(random: Random(seed)).generate(pool: pool);
        for (final q in questions) {
          expect(q.options.length, greaterThanOrEqualTo(2),
              reason: 'câu hỏi chỉ có 1 lựa chọn (seed=$seed): ${q.promptVi}',);
        }
      }
    });

    test('trộn cả 3 loại item — sourceType và promptVi khớp đúng loại nguồn',
        () {
      const validPrompts = {
        LessonItemType.vocabulary: {
          'Từ này có nghĩa là gì?',
          'Từ nào có nghĩa như trên?',
          'Từ này đọc là gì?',
          'Cách đọc này là của từ nào?',
        },
        LessonItemType.kanji: {
          'Chữ Hán này có nghĩa là gì?',
          'Chữ Hán nào có nghĩa như trên?',
          'Chữ Hán này đọc là gì?',
          'Cách đọc này là của chữ Hán nào?',
        },
        LessonItemType.grammar: {
          'Điểm ngữ pháp này dùng để làm gì?',
          'Điểm ngữ pháp nào dùng như trên?',
        },
      };
      final pool = [
        LessonContentItem.vocabulary(_vocab('v1', '買い物', 'Mua sắm')),
        LessonContentItem.vocabulary(_vocab('v2', '食べる', 'Ăn')),
        LessonContentItem.kanji(_kanji('k1', '買', 'Mua')),
        LessonContentItem.kanji(_kanji('k2', '食', 'Ăn uống')),
        LessonContentItem.grammar(_grammar('g1', '〜てください', 'Nhờ ai đó làm gì')),
        LessonContentItem.grammar(
            _grammar('g2', '〜ないでください', 'Nhờ ai đó đừng làm gì'),),
      ];

      for (var seed = 0; seed < 10; seed++) {
        final questions =
            QuizGenerator(random: Random(seed)).generate(pool: pool);
        for (final q in questions) {
          expect(validPrompts[q.sourceType], contains(q.promptVi));
        }
      }
    });

    test(
        'từ thuần kana (word == reading, VD いくら) không hỏi trục cách đọc — đề trùng đáp án',
        () {
      final pool = [
        LessonContentItem.vocabulary(
            _vocab('v1', 'いくら', 'Bao nhiêu tiền', reading: 'いくら'),),
        LessonContentItem.vocabulary(
            _vocab('v2', 'えんじにあ', 'Kỹ sư', reading: 'えんじにあ'),),
        LessonContentItem.vocabulary(
            _vocab('v3', 'はしります', 'Chạy', reading: 'はしります'),),
        LessonContentItem.vocabulary(
            _vocab('v4', 'はたらきます', 'Làm việc', reading: 'はたらきます'),),
      ];

      for (var seed = 0; seed < 30; seed++) {
        final questions =
            QuizGenerator(random: Random(seed)).generate(pool: pool);
        for (final q in questions) {
          expect(
            q.promptVi,
            isNot(anyOf('Từ này đọc là gì?', 'Cách đọc này là của từ nào?')),
            reason:
                'item kana-thuần có term==reading, hỏi trục cách đọc sẽ ra '
                'đề trùng hệt đáp án đúng (stem="${q.displayJp}")',
          );
        }
      }
    });

    test('câu hỏi đảo chiều (nghĩa → chữ Nhật) tắt hiển thị kiểu Nhật', () {
      final pool = [
        LessonContentItem.vocabulary(_vocab('v1', '買い物', 'Mua sắm')),
        LessonContentItem.vocabulary(_vocab('v2', '食べる', 'Ăn')),
        LessonContentItem.vocabulary(_vocab('v3', '飲む', 'Uống')),
        LessonContentItem.vocabulary(_vocab('v4', '見る', 'Xem')),
      ];

      var sawReverseDirection = false;
      for (var seed = 0; seed < 30; seed++) {
        final questions =
            QuizGenerator(random: Random(seed)).generate(pool: pool);
        for (final q in questions) {
          if (q.promptVi == 'Từ nào có nghĩa như trên?') {
            sawReverseDirection = true;
            expect(q.displayIsJapanese, isFalse);
            expect(['Mua sắm', 'Ăn', 'Uống', 'Xem'], contains(q.displayJp));
            expect(q.readingFurigana, isNull);
          } else {
            expect(q.displayIsJapanese, isTrue);
          }
        }
      }
      expect(sawReverseDirection, isTrue,
          reason:
              'không thấy chiều hỏi đảo (nghĩa → chữ Nhật) sau 30 lần thử',);
    });

    test('distractorPool bổ sung nhiễu khi pool chính quá nhỏ để tự đủ 4 lựa chọn',
        () {
      final items = {
        '買い物': const _KnownItem('買い物', 'Mua sắm', 'かいもの'),
        '食べる': const _KnownItem('食べる', 'Ăn', 'たべる'),
      };
      final pool = [
        LessonContentItem.vocabulary(
            _vocab('v1', '買い物', 'Mua sắm', reading: 'かいもの'),),
        LessonContentItem.vocabulary(
            _vocab('v2', '食べる', 'Ăn', reading: 'たべる'),),
      ];
      final distractorPool = [
        LessonContentItem.vocabulary(
            _vocab('v3', '飲む', 'Uống', reading: 'のむ'),),
        LessonContentItem.vocabulary(
            _vocab('v4', '見る', 'Xem', reading: 'みる'),),
        LessonContentItem.vocabulary(
            _vocab('v5', '寝る', 'Ngủ', reading: 'ねる'),),
      ];

      final withoutDistractor = const QuizGenerator().generate(pool: pool);
      final withDistractor = const QuizGenerator()
          .generate(pool: pool, distractorPool: distractorPool);

      // Câu hỏi vẫn chỉ lấy từ `pool`, không lấy dư từ distractorPool.
      expect(withDistractor.length, 2);
      for (final q in withDistractor) {
        final sourceItem =
            items.values.firstWhere((it) => it.hasField(q.displayJp));
        expect(sourceItem.hasField(q.options[q.correctIndex]), isTrue);
      }
      expect(withoutDistractor.first.options.length,
          lessThanOrEqualTo(withDistractor.first.options.length),);
    });

    test(
        'options thực sự được xáo trộn — correctIndex không phải lúc nào cũng bằng 0',
        () {
      final pool = [
        LessonContentItem.vocabulary(_vocab('v1', '買い物', 'Mua sắm')),
        LessonContentItem.vocabulary(_vocab('v2', '食べる', 'Ăn')),
        LessonContentItem.vocabulary(_vocab('v3', '飲む', 'Uống')),
        LessonContentItem.vocabulary(_vocab('v4', '見る', 'Xem')),
      ];

      var sawNonZero = false;
      for (var i = 0; i < 30; i++) {
        final questions = QuizGenerator(random: Random(i)).generate(pool: pool);
        if (questions.any((q) => q.correctIndex != 0)) {
          sawNonZero = true;
          break;
        }
      }

      expect(sawNonZero, isTrue,
          reason:
              'correctIndex luôn là 0 sau 30 lần thử — có thể quên shuffle',);
    });

    test('kanji gộp cả on lẫn kun thành 1 chuỗi cách đọc, không bịa 1 âm đại diện',
        () {
      final pool = [
        LessonContentItem.kanji(_kanji('k1', '生', 'Sinh',
            onyomi: ['セイ', 'ショウ'], kunyomi: ['い.きる', 'う.まれる'],),),
        LessonContentItem.kanji(_kanji('k2', '食', 'Ăn uống',
            onyomi: ['ショク'], kunyomi: ['た.べる'],),),
      ];

      const expectedReading = {
        '生': 'セイ・ショウ・い.きる・う.まれる',
        '食': 'ショク・た.べる',
      };

      var sawReadingQuestion = false;
      for (var seed = 0; seed < 30; seed++) {
        final questions =
            QuizGenerator(random: Random(seed)).generate(pool: pool);
        for (final q in questions) {
          if (q.promptVi == 'Chữ Hán này đọc là gì?') {
            sawReadingQuestion = true;
            expect(expectedReading.containsKey(q.displayJp), isTrue);
            expect(
                q.options[q.correctIndex], expectedReading[q.displayJp],);
          }
        }
      }
      expect(sawReadingQuestion, isTrue,
          reason: 'không thấy câu hỏi cách đọc kanji sau 30 lần thử',);
    });

    test(
        'readingOnly: chỉ hỏi trục cách đọc khi item có cách đọc riêng biệt',
        () {
      final pool = [
        LessonContentItem.kanji(_kanji('k1', '生', 'Sinh',
            onyomi: ['セイ'], kunyomi: ['い.きる'],),),
        LessonContentItem.vocabulary(
            _vocab('v1', '生まれる', 'Được sinh ra', reading: 'うまれる'),),
        LessonContentItem.vocabulary(
            _vocab('v2', '先生', 'Giáo viên', reading: 'せんせい'),),
      ];

      const readingPrompts = {
        'Chữ Hán này đọc là gì?',
        'Cách đọc này là của chữ Hán nào?',
        'Từ này đọc là gì?',
        'Cách đọc này là của từ nào?',
      };

      for (var seed = 0; seed < 30; seed++) {
        final questions = QuizGenerator(random: Random(seed))
            .generate(pool: pool, readingOnly: true);
        for (final q in questions) {
          expect(readingPrompts, contains(q.promptVi));
        }
      }
    });

    test('readingOnly: item không có cách đọc riêng biệt vẫn có câu hỏi (rơi về nghĩa)',
        () {
      final pool = [
        LessonContentItem.grammar(_grammar('g1', '〜てください', 'Nhờ ai đó làm gì')),
        LessonContentItem.grammar(
            _grammar('g2', '〜ないでください', 'Nhờ ai đó đừng làm gì'),),
      ];

      final questions =
          const QuizGenerator().generate(pool: pool, readingOnly: true);

      expect(questions.length, 2);
    });
  });

  group('QuizGenerator.generateGrammarFillBlank', () {
    test('honest-empty-state khi pool có ít hơn 2 mẫu hợp lệ', () {
      final pool = [
        _grammarFillBlank('g1', ['わたし', 'は', '学生', 'です'], 1),
      ];

      final questions =
          const QuizGenerator().generateGrammarFillBlank(pool: pool);

      expect(questions, isEmpty);
    });

    test('blankPrompt chứa "___" và đáp án đúng đúng bằng token bị ẩn', () {
      final pool = [
        _grammarFillBlank('g1', ['わたし', 'は', '学生', 'です'], 1),
        _grammarFillBlank('g2', ['かれ', 'も', '先生', 'です'], 1),
      ];
      const expectedByPrompt = {
        'わたし___学生です': 'は',
        'かれ___先生です': 'も',
      };

      for (var seed = 0; seed < 10; seed++) {
        final questions = QuizGenerator(random: Random(seed))
            .generateGrammarFillBlank(pool: pool);
        for (final q in questions) {
          expect(q.displayJp, contains('___'));
          expect(q.sourceType, LessonItemType.grammar);
          expect(q.options[q.correctIndex], expectedByPrompt[q.displayJp]);
        }
      }
    });

    test('nhiễu lấy từ token cùng vị trí của mẫu khác, không bịa từ mới', () {
      final pool = [
        _grammarFillBlank('g1', ['わたし', 'は', '学生', 'です'], 1),
        _grammarFillBlank('g2', ['わたし', 'も', '学生', 'です'], 1),
        _grammarFillBlank('g3', ['かれ', 'が', '先生', 'です'], 1),
      ];
      const knownTokens = {'は', 'も', 'が'};

      for (var seed = 0; seed < 10; seed++) {
        final questions = QuizGenerator(random: Random(seed))
            .generateGrammarFillBlank(pool: pool);
        for (final q in questions) {
          for (final option in q.options) {
            expect(knownTokens, contains(option));
          }
          final normalized =
              q.options.map((o) => o.trim().toLowerCase()).toList();
          expect(normalized.toSet().length, normalized.length,
              reason: 'options bị trùng: ${q.options}',);
        }
      }
    });

    test('sinh đúng số câu hỏi tối đa questionCount', () {
      final pool = [
        _grammarFillBlank('g1', ['わたし', 'は', '学生', 'です'], 1),
        _grammarFillBlank('g2', ['わたし', 'も', '学生', 'です'], 1),
        _grammarFillBlank('g3', ['かれ', 'が', '先生', 'です'], 1),
      ];

      final questions = const QuizGenerator()
          .generateGrammarFillBlank(pool: pool, questionCount: 2);

      expect(questions.length, 2);
    });
  });

  group('isTypedAnswerCorrect', () {
    test('exact: khớp sau khi trim/lowercase, khác chuỗi thì sai', () {
      expect(isTypedAnswerCorrect('  たべる  ', ['たべる'], TypedAnswerMode.exact),
          isTrue,);
      expect(isTypedAnswerCorrect('タベル', ['たべる'], TypedAnswerMode.exact),
          isFalse,);
      expect(isTypedAnswerCorrect('', ['たべる'], TypedAnswerMode.exact), isFalse);
    });

    test('exact: bỏ dấu chấm ngăn okurigana khi so khớp kunyomi từ điển', () {
      expect(
          isTypedAnswerCorrect('いきる', ['い.きる'], TypedAnswerMode.exact), isTrue,);
    });

    test('exact: đúng nếu khớp bất kỳ 1 trong nhiều đáp án chấp nhận', () {
      expect(
          isTypedAnswerCorrect('しょう', ['せい', 'しょう'], TypedAnswerMode.exact),
          isTrue,);
    });

    test('lenient: đúng khi 1 trong 2 chuỗi (đã chuẩn hoá) chứa chuỗi còn lại',
        () {
      expect(isTypedAnswerCorrect('Mua sắm', ['mua sắm'], TypedAnswerMode.lenient),
          isTrue,);
      expect(
          isTypedAnswerCorrect('đi mua sắm', ['mua sắm'], TypedAnswerMode.lenient),
          isTrue,);
      expect(
          isTypedAnswerCorrect('mua', ['mua sắm'], TypedAnswerMode.lenient),
          isTrue,);
      expect(
          isTypedAnswerCorrect('bán', ['mua sắm'], TypedAnswerMode.lenient),
          isFalse,);
    });
  });

  group('QuizGenerator.generateTyping', () {
    test('vocab: chỉ nhận item có reading thật, gõ đúng reading là đúng', () {
      final pool = [
        LessonContentItem.vocabulary(
            _vocab('v1', '食べる', 'Ăn', reading: 'たべる'),),
        LessonContentItem.vocabulary(
            _vocab('v2', '飲む', 'Uống', reading: 'のむ'),),
      ];

      final questions = const QuizGenerator().generateTyping(pool: pool);

      expect(questions.length, 2);
      for (final q in questions) {
        expect(q.typedAnswerMode, TypedAnswerMode.exact);
        expect(q.sourceType, LessonItemType.vocabulary);
        expect(
            isTypedAnswerCorrect(
                q.typedAcceptedAnswers.first, q.typedAcceptedAnswers, TypedAnswerMode.exact,),
            isTrue,);
      }
    });

    test('kanji: mọi âm on/kun đều là đáp án chấp nhận riêng lẻ, không gộp "・"',
        () {
      final pool = [
        LessonContentItem.kanji(_kanji('k1', '生', 'Sinh',
            onyomi: ['セイ', 'ショウ'], kunyomi: ['い.きる', 'う.まれる'],),),
      ];

      final questions = const QuizGenerator().generateTyping(pool: pool);

      expect(questions.length, 1);
      expect(
        questions.first.typedAcceptedAnswers,
        containsAll(['セイ', 'ショウ', 'い.きる', 'う.まれる']),
      );
      expect(isTypedAnswerCorrect('いきる', questions.first.typedAcceptedAnswers,
          TypedAnswerMode.exact,), isTrue,);
    });

    test('bỏ qua item không có cách đọc (VD ngữ pháp, hoặc kanji chưa có on/kun)',
        () {
      final pool = [
        LessonContentItem.grammar(_grammar('g1', '〜てください', 'Nhờ ai đó làm gì')),
        LessonContentItem.kanji(_kanji('k1', '謎', 'Bí ẩn')),
      ];

      final questions = const QuizGenerator().generateTyping(pool: pool);

      expect(questions, isEmpty);
    });
  });

  group('QuizGenerator.generateTranslation', () {
    test('vocab: hiện từ, đáp án chấp nhận là primaryMeaning thật', () {
      final pool = [
        LessonContentItem.vocabulary(_vocab('v1', '買い物', 'Mua sắm')),
      ];

      final questions = const QuizGenerator().generateTranslation(pool: pool);

      expect(questions.length, 1);
      expect(questions.first.displayJp, '買い物');
      expect(questions.first.typedAnswerMode, TypedAnswerMode.lenient);
      expect(questions.first.typedAcceptedAnswers, ['Mua sắm']);
    });

    test('grammar: chỉ nhận mẫu có đủ cả exampleJp lẫn exampleVi thật', () {
      final pool = [
        LessonContentItem.grammar(
            _grammarWithExample('g1', 'わたしは学生です。', 'Tôi là học sinh.'),),
        LessonContentItem.grammar(_grammar('g2', '〜てください', 'Nhờ ai đó làm gì')),
      ];

      final questions = const QuizGenerator().generateTranslation(pool: pool);

      expect(questions.length, 1);
      expect(questions.first.displayJp, 'わたしは学生です。');
      expect(questions.first.typedAcceptedAnswers, ['Tôi là học sinh.']);
    });

    test('kanji không có câu hỏi Translation (ngoài phạm vi thiết kế)', () {
      final pool = [
        LessonContentItem.kanji(_kanji('k1', '買', 'Mua')),
      ];

      final questions = const QuizGenerator().generateTranslation(pool: pool);

      expect(questions, isEmpty);
    });
  });

  group('isOrderCorrect', () {
    test('đúng khi thứ tự và nội dung khớp hệt', () {
      expect(isOrderCorrect(['わたし', 'は', '学生'], ['わたし', 'は', '学生']), isTrue);
    });

    test('sai khi thứ tự khác dù nội dung giống', () {
      expect(isOrderCorrect(['は', 'わたし', '学生'], ['わたし', 'は', '学生']), isFalse);
    });

    test('sai khi số lượng khác', () {
      expect(isOrderCorrect(['わたし', 'は'], ['わたし', 'は', '学生']), isFalse);
    });
  });

  group('QuizGenerator.generateSentenceOrdering', () {
    test('chỉ nhận mẫu có ≥3 practiceTokens và exampleVi thật', () {
      final pool = [
        _grammarFull('g1', 'A',
            exampleVi: 'Tôi là học sinh.',
            practiceTokens: ['わたし', 'は', '学生', 'です'],),
        _grammarFull('g2', 'B', practiceTokens: ['a', 'b', 'c']), // thiếu exampleVi
        _grammarFull('g3', 'C', exampleVi: 'thiếu token'), // thiếu practiceTokens
      ];

      final questions = const QuizGenerator().generateSentenceOrdering(pool: pool);

      expect(questions.length, 1);
      expect(questions.first.displayJp, 'Tôi là học sinh.');
      expect(questions.first.displayIsJapanese, isFalse);
    });

    test('orderTiles là hoán vị của orderCorrectSequence, luôn khác thứ tự gốc',
        () {
      final pool = [
        _grammarFull('g1', 'A',
            exampleVi: 'Tôi là học sinh.',
            practiceTokens: ['わたし', 'は', '学生', 'です'],),
      ];

      for (var seed = 0; seed < 20; seed++) {
        final questions = QuizGenerator(random: Random(seed))
            .generateSentenceOrdering(pool: pool);
        final q = questions.first;
        expect(q.orderCorrectSequence, ['わたし', 'は', '学生', 'です']);
        expect(
          [...q.orderTiles!]..sort(),
          [...q.orderCorrectSequence]..sort(),
          reason: 'orderTiles phải là hoán vị đúng của orderCorrectSequence',
        );
        expect(isOrderCorrect(q.orderTiles!, q.orderCorrectSequence), isFalse,
            reason: 'đề bài không được trùng sẵn đáp án đúng',);
      }
    });
  });

  group('QuizGenerator.generateGrammarSelection', () {
    test('hiện exampleJp, đáp án đúng là title thật của chính mẫu đó', () {
      final pool = [
        _grammarFull('g1', '〜てください', exampleJp: '食べてください。'),
        _grammarFull('g2', '〜ないでください', exampleJp: '食べないでください。'),
      ];

      final questions = const QuizGenerator().generateGrammarSelection(pool: pool);

      expect(questions.length, 2);
      for (final q in questions) {
        final expectedTitle =
            q.displayJp == '食べてください。' ? '〜てください' : '〜ないでください';
        expect(q.options[q.correctIndex], expectedTitle);
      }
    });

    test('honest-empty-state khi không đủ 2 title khác nhau để làm nhiễu', () {
      final pool = [
        _grammarFull('g1', 'A', exampleJp: '例文1'),
      ];

      final questions = const QuizGenerator().generateGrammarSelection(pool: pool);

      expect(questions, isEmpty);
    });
  });

  group('QuizGenerator.generateParticleSelection', () {
    test('chỉ ẩn đúng token là trợ từ thật, không phải token bất kỳ', () {
      final pool = [
        _grammarFull('g1', 'A', practiceTokens: ['わたし', 'は', '学生', 'です']),
        _grammarFull('g2', 'B', practiceTokens: ['かれ', 'も', '先生', 'です']),
      ];

      for (var seed = 0; seed < 10; seed++) {
        final questions = QuizGenerator(random: Random(seed))
            .generateParticleSelection(pool: pool);
        for (final q in questions) {
          expect(q.displayJp, contains('___'));
          expect(const {'は', 'も'}, contains(q.options[q.correctIndex]));
        }
      }
    });

    test('honest-empty-state khi không có mẫu nào chứa trợ từ nhận diện được',
        () {
      final pool = [
        _grammarFull('g1', 'A', practiceTokens: ['わたし', '学生', 'です']),
      ];

      final questions = const QuizGenerator().generateParticleSelection(pool: pool);

      expect(questions, isEmpty);
    });
  });

  group('QuizGenerator.generateErrorCorrectionFromMistakes', () {
    test('hiện originalAnswer, đáp án đúng là correctAnswer thật', () {
      final pool = [
        _mistake('m1', 'vocab', 'Mua sắm', originalAnswer: 'Mua đồ'),
        _mistake('m2', 'kanji', 'Ăn uống', originalAnswer: 'Ẩm thực'),
      ];

      final questions =
          const QuizGenerator().generateErrorCorrectionFromMistakes(pool: pool);

      expect(questions.length, 2);
      for (final q in questions) {
        expect(q.displayIsJapanese, isFalse);
        final expected = q.displayJp == 'Mua đồ' ? 'Mua sắm' : 'Ăn uống';
        expect(q.options[q.correctIndex], expected);
      }
    });

    test('bỏ qua mục không có originalAnswer (field có thể null)', () {
      final pool = [
        _mistake('m1', 'vocab', 'Mua sắm'), // originalAnswer null
        _mistake('m2', 'kanji', 'Ăn uống', originalAnswer: 'Ẩm thực'),
      ];

      final questions =
          const QuizGenerator().generateErrorCorrectionFromMistakes(pool: pool);

      expect(questions, isEmpty); // còn lại 1 mục hợp lệ, không đủ 2 để chấm
    });

    test('sourceType suy đúng từ chuỗi thật trong entity (vocab/kanji/grammar)',
        () {
      final pool = [
        _mistake('m1', 'vocab', 'A', originalAnswer: 'a'),
        _mistake('m2', 'kanji', 'B', originalAnswer: 'b'),
        _mistake('m3', 'grammar', 'C', originalAnswer: 'c'),
      ];

      final questions =
          const QuizGenerator().generateErrorCorrectionFromMistakes(pool: pool);

      final bySource = {for (final q in questions) q.displayJp: q.sourceType};
      expect(bySource['a'], LessonItemType.vocabulary);
      expect(bySource['b'], LessonItemType.kanji);
      expect(bySource['c'], LessonItemType.grammar);
    });
  });

  group('QuizGenerator.generateErrorCorrectionFromKaiwa', () {
    test('hiện contentJp, đáp án đúng là betterPhrasing thật', () {
      final pool = [
        _kaiwaReviewable('k1', '私は学生。', '私は学生です。'),
        _kaiwaReviewable('k2', '食べます、明日。', '明日食べます。'),
      ];

      final questions =
          const QuizGenerator().generateErrorCorrectionFromKaiwa(pool: pool);

      expect(questions.length, 2);
      for (final q in questions) {
        final expected =
            q.displayJp == '私は学生。' ? '私は学生です。' : '明日食べます。';
        expect(q.options[q.correctIndex], expected);
        expect(q.sourceType, isNull);
      }
    });

    test('honest-empty-state khi không đủ 2 mục isReviewable', () {
      final pool = [
        _kaiwaReviewable('k1', '私は学生。', '私は学生です。'),
        const KaiwaMessage(
            id: 'k2', role: KaiwaMessageRole.user, contentJp: 'ok',), // không reviewable
      ];

      final questions =
          const QuizGenerator().generateErrorCorrectionFromKaiwa(pool: pool);

      expect(questions, isEmpty);
    });
  });

  group('QuizGenerator.generateConversationCompletion', () {
    test('hiện promptContextJp, đáp án đúng là nextAiReplyJp thật', () {
      const pool = [
        ConversationTurn(
            promptContextJp: '初めまして。', nextAiReplyJp: 'よろしくお願いします。',),
        ConversationTurn(
            promptContextJp: 'お元気ですか。', nextAiReplyJp: '元気です、ありがとう。',),
      ];

      final questions =
          const QuizGenerator().generateConversationCompletion(pool: pool);

      expect(questions.length, 2);
      for (final q in questions) {
        final expected = q.displayJp == '初めまして。'
            ? 'よろしくお願いします。'
            : '元気です、ありがとう。';
        expect(q.options[q.correctIndex], expected);
      }
    });

    test('honest-empty-state khi không đủ 2 câu trả lời AI khác nhau', () {
      const pool = [
        ConversationTurn(promptContextJp: 'A', nextAiReplyJp: 'B'),
      ];

      final questions =
          const QuizGenerator().generateConversationCompletion(pool: pool);

      expect(questions, isEmpty);
    });
  });
}
