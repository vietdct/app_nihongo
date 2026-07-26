import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:nihongo/domain/entities/grammar_point.dart';
import 'package:nihongo/domain/entities/kanji.dart';
import 'package:nihongo/domain/entities/lesson.dart';
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
  });
}
