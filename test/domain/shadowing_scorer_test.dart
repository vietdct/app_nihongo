import 'package:flutter_test/flutter_test.dart';
import 'package:nihongo/domain/services/shadowing_scorer.dart';

void main() {
  group('computeShadowingScore', () {
    test('khớp hoàn toàn cho điểm 100', () {
      expect(computeShadowingScore('わたしは学生です。', 'わたしは学生です。'), 100);
    });

    test('khác dấu câu/khoảng trắng không ảnh hưởng điểm', () {
      expect(computeShadowingScore('わたしは、学生です！', 'わたしは学生です'), 100);
    });

    test('sai 1 ký tự trong câu dài vẫn cho điểm cao', () {
      final score = computeShadowingScore('わたしは学生です。', 'わたしは学生でわ。');
      expect(score, greaterThanOrEqualTo(70));
      expect(score, lessThan(100));
    });

    test('câu hoàn toàn khác cho điểm thấp', () {
      final score = computeShadowingScore('おはようございます。', 'こんばんは。');
      expect(score, lessThan(40));
    });

    test('chưa nhận diện được gì (rỗng) cho điểm 0', () {
      expect(computeShadowingScore('わたしは学生です。', ''), 0);
    });

    test('câu mẫu rỗng cho điểm 0 (không chia cho 0)', () {
      expect(computeShadowingScore('', 'わたしは学生です。'), 0);
    });

    test('điểm luôn trong khoảng 0-100', () {
      final score = computeShadowingScore('これはテストです', 'まったく違う内容の文章です');
      expect(score, inInclusiveRange(0, 100));
    });
  });
}
