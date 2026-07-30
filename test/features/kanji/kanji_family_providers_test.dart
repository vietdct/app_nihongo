import 'package:flutter_test/flutter_test.dart';
import 'package:nihongo/domain/entities/kanji.dart';
import 'package:nihongo/features/kanji/providers/kanji_family_providers.dart';

Kanji _kanji(String id, String character, {List<String> components = const []}) =>
    Kanji(
      id: id,
      character: character,
      levelId: 'n5',
      meaningVi: const ['nghĩa'],
      components: components,
    );

void main() {
  group('computeKanjiFamily', () {
    test('tìm đúng parents từ components của chính kanji đó', () {
      final all = [
        _kanji('k1', '人'),
        _kanji('k2', '木'),
        _kanji('k3', '校', components: ['木', '交']),
      ];

      final family = computeKanjiFamily(all[2], all);

      expect(family.parents.map((k) => k.character), ['木']);
      expect(family.children, isEmpty);
    });

    test('tìm đúng children — kanji khác có chữ này trong components', () {
      final all = [
        _kanji('k1', '人'),
        _kanji('k2', '火', components: ['八', '人']),
        _kanji('k3', '大', components: ['一', '人']),
      ];

      final family = computeKanjiFamily(all[0], all);

      expect(
        family.children.map((k) => k.character).toSet(),
        {'火', '大'},
      );
      expect(family.parents, isEmpty);
    });

    test('honest-empty khi kanji không có quan hệ ghép-bộ thật nào', () {
      final all = [
        _kanji('k1', '日'),
        _kanji('k2', '月'),
      ];

      final family = computeKanjiFamily(all[0], all);

      expect(family.isEmpty, isTrue);
    });

    test('không tự trỏ về chính nó dù component trùng ký tự chính nó', () {
      final all = [
        _kanji('k1', '木', components: ['木']),
      ];

      final family = computeKanjiFamily(all[0], all);

      expect(family.isEmpty, isTrue);
    });
  });
}
