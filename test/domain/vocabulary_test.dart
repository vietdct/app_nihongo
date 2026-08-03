import 'package:flutter_test/flutter_test.dart';
import 'package:nihongo/domain/entities/vocab_meaning.dart';
import 'package:nihongo/domain/entities/vocabulary.dart';

void main() {
  group('Vocabulary.primaryMeaning', () {
    test('trả về chuỗi rỗng khi danh sách nghĩa chưa được nạp', () {
      const vocabulary = Vocabulary(
        id: 'vocab-1',
        word: '旅行',
        reading: 'りょこう',
        levelId: 'n5',
        meanings: [],
      );

      expect(vocabulary.primaryMeaning, isEmpty);
    });

    test('trả về nghĩa đầu tiên khi dữ liệu đã có', () {
      const vocabulary = Vocabulary(
        id: 'vocab-1',
        word: '旅行',
        reading: 'りょこう',
        levelId: 'n5',
        meanings: [
          VocabMeaning(meaningVi: 'du lịch'),
          VocabMeaning(meaningVi: 'chuyến đi'),
        ],
      );

      expect(vocabulary.primaryMeaning, 'du lịch');
    });
  });
}
