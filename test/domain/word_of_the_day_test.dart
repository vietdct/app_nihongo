import 'package:flutter_test/flutter_test.dart';
import 'package:nihongo/domain/entities/vocab_meaning.dart';
import 'package:nihongo/domain/entities/vocabulary.dart';
import 'package:nihongo/domain/services/word_of_the_day.dart';

Vocabulary _vocab(String id) => Vocabulary(
      id: id,
      word: id,
      reading: id,
      levelId: 'n5',
      meanings: const [VocabMeaning(meaningVi: 'nghĩa')],
    );

void main() {
  group('pickWordOfTheDay', () {
    test('danh sách rỗng trả về null', () {
      expect(
        pickWordOfTheDay(pool: const [], levelId: 'n5', now: DateTime(2026, 7, 29)),
        isNull,
      );
    });

    test('cùng ngày, cùng cấp độ, cùng danh sách luôn ra cùng 1 từ', () {
      final pool = List.generate(20, (i) => _vocab('w$i'));
      final now = DateTime(2026, 7, 29, 14, 30);
      final a = pickWordOfTheDay(pool: pool, levelId: 'n5', now: now);
      final b = pickWordOfTheDay(pool: pool, levelId: 'n5', now: now);
      expect(a, isNotNull);
      expect(a!.id, b!.id);
    });

    test('sang ngày mới thì đổi từ', () {
      final pool = List.generate(20, (i) => _vocab('w$i'));
      final today = pickWordOfTheDay(pool: pool, levelId: 'n5', now: DateTime(2026, 7, 29));
      final tomorrow = pickWordOfTheDay(pool: pool, levelId: 'n5', now: DateTime(2026, 7, 30));
      expect(today!.id, isNot(tomorrow!.id));
    });

    test('đổi cấp độ thì đổi từ dù cùng ngày và cùng danh sách', () {
      final pool = List.generate(20, (i) => _vocab('w$i'));
      final now = DateTime(2026, 7, 29);
      final n5 = pickWordOfTheDay(pool: pool, levelId: 'n5', now: now);
      final n4 = pickWordOfTheDay(pool: pool, levelId: 'n4', now: now);
      expect(n5!.id, isNot(n4!.id));
    });

    test('chỉ số luôn nằm trong phạm vi danh sách', () {
      final pool = [_vocab('only')];
      final result = pickWordOfTheDay(pool: pool, levelId: 'n5', now: DateTime(2026, 7, 29));
      expect(result!.id, 'only');
    });
  });
}
