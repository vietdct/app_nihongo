import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:nihongo/domain/entities/grammar_point.dart';
import 'package:nihongo/domain/entities/vocab_meaning.dart';
import 'package:nihongo/domain/entities/vocabulary.dart';
import 'package:nihongo/domain/services/quiz_generator.dart';

GrammarPoint _g(String id, String title, String? example) => GrammarPoint(
      id: id,
      title: title,
      explanation: 'x',
      levelId: 'it',
      exampleJp: example,
    );

void main() {
  final gen = QuizGenerator(random: Random(1));

  test('đáp án đúng là câu ví dụ của mẫu, nhiễu không chứa lõi mẫu', () {
    final pool = [
      _g('1', '〜について', 'プロジェクトについて説明します。'),
      _g('2', '〜場合は', 'エラーが出た場合は連絡します。'),
      _g('3', '〜ために', '品質のためにレビューします。'),
      _g('4', '〜前に', '会議の前に準備します。'),
    ];
    final qs = gen.generateGrammarSentencePick(pool: pool, questionCount: 4);
    expect(qs, isNotEmpty);
    for (final q in qs) {
      final g = pool.firstWhere((p) => p.title == q.displayJp);
      expect(q.options[q.correctIndex], g.exampleJp);
      final core = g.title.replaceAll('〜', '');
      for (var i = 0; i < q.options.length; i++) {
        if (i != q.correctIndex) expect(q.options[i].contains(core), isFalse);
      }
    }
  });

  test('thiếu dữ liệu thì không sinh câu hỏi', () {
    expect(
      gen.generateGrammarSentencePick(
        pool: [_g('1', '〜について', 'a'), _g('2', '〜場合は', null)],
      ),
      isEmpty,
    );
  });

  test('cloze từ vựng: chỉ dùng ví dụ chứa nguyên văn từ, thay bằng chỗ trống',
      () {
    Vocabulary v(String id, String w, String? ex) => Vocabulary(
          id: id,
          word: w,
          reading: w,
          levelId: 'it',
          meanings: [VocabMeaning(meaningVi: 'x', exampleJp: ex)],
        );
    final pool = [
      v('1', '課題', '課題を整理します。'),
      v('2', '進捗', '進捗を報告します。'),
      v('3', '対応する', '問題に対応して直す。'), // chia đuôi khác → bỏ qua
      v('4', '確認', '内容を確認します。'),
    ];
    final qs = gen.generateVocabCloze(pool: pool, questionCount: 10);
    expect(qs.length, 3);
    for (final q in qs) {
      expect(q.displayJp.contains('＿＿＿'), isTrue);
      expect(q.options[q.correctIndex], isNot('対応する'));
      expect(q.options.toSet().length, q.options.length);
    }
  });

  group('tình huống → thuật ngữ', () {
    Vocabulary v(String id, String w, String meaning, String? ex, String? vi,
            {String? pos = 'noun'}) =>
        Vocabulary(
          id: id,
          word: w,
          reading: w,
          levelId: 'it',
          partOfSpeech: pos,
          meanings: [
            VocabMeaning(meaningVi: meaning, exampleJp: ex, exampleVi: vi),
          ],
        );

    final pool = [
      v('1', '課題', 'vấn đề cần giải quyết', '課題を整理します。',
          'Tôi sẽ sắp xếp lại các việc còn tồn đọng của dự án.'),
      v('2', '進捗', 'tiến độ', '進捗を報告します。',
          'Tôi sẽ báo cáo mức độ hoàn thành công việc cho trưởng nhóm.'),
      v('3', '確認', 'xác nhận', '内容を確認します。',
          'Tôi sẽ xem lại nội dung trước khi gửi cho khách hàng.'),
      v('4', '納期', 'thời hạn giao hàng', '納期を守ります。', null),
      v('5', '仕様', 'đặc tả', '仕様を決めます。', 'Ngắn'), // câu Việt quá ngắn
      v('6', '要件', 'yêu cầu', '要件を聞きます。',
          'Tôi sẽ nghe yêu cầu của khách hàng ở buổi họp.'),
    ];

    test('hiện câu Việt, đáp án là từ Nhật, 4 lựa chọn không trùng', () {
      final qs = gen.generateVocabSituation(pool: pool, questionCount: 10);
      expect(qs, isNotEmpty);
      for (final q in qs) {
        expect(q.displayIsJapanese, isFalse);
        expect(q.options.length, 4);
        expect(q.options.toSet().length, 4);
        final word = q.options[q.correctIndex];
        final src = pool.firstWhere((p) => p.word == word);
        expect(q.displayJp, src.meanings.first.exampleVi);
        expect(q.explanationVi, contains(src.meanings.first.exampleJp));
      }
    });

    test('bỏ từ thiếu bản dịch hoặc câu Việt quá ngắn', () {
      final qs = gen.generateVocabSituation(pool: pool, questionCount: 10);
      final answers = qs.map((q) => q.options[q.correctIndex]).toSet();
      expect(answers, isNot(contains('納期')));
      expect(answers, isNot(contains('仕様')));
    });

    test('không dùng nhiễu có nghĩa xuất hiện ngay trong câu tình huống', () {
      final leaky = [
        ...pool,
        v('7', '期限', 'khách hàng', '期限を決めます。', 'Tôi sẽ đặt lịch ngày mai cho cuộc họp.'),
      ];
      final qs = gen.generateVocabSituation(pool: leaky, questionCount: 20);
      for (final q in qs) {
        if (q.displayJp.toLowerCase().contains('khách hàng')) {
          expect(q.options, isNot(contains('期限')));
        }
      }
    });

    test('không đủ nhiễu thì không sinh câu', () {
      expect(
        gen.generateVocabSituation(pool: pool.take(3).toList()),
        isEmpty,
      );
    });
  });
}
