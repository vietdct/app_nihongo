import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/entities/kanji.dart';
import '../../lesson/providers/content_providers.dart';

/// Quan hệ ghép-bộ của 1 kanji, tính từ `Kanji.components` (dữ liệu IDS
/// thật) đối chiếu với bộ kanji hiện có trong app — xem
/// `20260727020000_kanji_components.sql` cho nguồn dữ liệu.
class KanjiFamily {
  const KanjiFamily({required this.parents, required this.children});

  /// Kanji khác trong app xuất hiện trong `target.components` — chữ này
  /// được ghép từ những chữ nào.
  final List<Kanji> parents;

  /// Kanji khác trong app có `target.character` nằm trong `components` của
  /// chúng — những chữ khác dùng chữ này làm bộ.
  final List<Kanji> children;

  bool get isEmpty => parents.isEmpty && children.isEmpty;
}

/// Hàm thuần — dùng lại ở cả `kanjiFamilyProvider` (route `/kanji/:id/family`)
/// lẫn trực tiếp trong `kanji_detail_screen.dart` (quyết định có hiện nút
/// "Gia đình Kanji" hay không), tránh lặp logic đối chiếu.
KanjiFamily computeKanjiFamily(Kanji target, List<Kanji> all) {
  final parents = [
    for (final component in target.components)
      for (final k in all)
        if (k.character == component && k.id != target.id) k,
  ];
  final children = [
    for (final k in all)
      if (k.id != target.id && k.components.contains(target.character)) k,
  ];
  return KanjiFamily(parents: parents, children: children);
}

final kanjiFamilyProvider = Provider.autoDispose
    .family<AsyncValue<KanjiFamily>, String>((ref, kanjiId) {
  final kanjiAsync = ref.watch(kanjiListProvider);
  return kanjiAsync.whenData((allKanji) {
    Kanji? target;
    for (final k in allKanji) {
      if (k.id == kanjiId) {
        target = k;
        break;
      }
    }
    if (target == null) {
      return const KanjiFamily(parents: [], children: []);
    }
    return computeKanjiFamily(target, allKanji);
  });
});
