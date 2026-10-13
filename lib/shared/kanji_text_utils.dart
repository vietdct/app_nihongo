/// Kanji Unicode nằm trong khối CJK Unified Ideographs (4E00–9FFF) — đủ cho
/// toàn bộ nội dung N5–N1 của app, không cần bảng tra riêng.
bool isKanjiChar(int rune) => rune >= 0x4E00 && rune <= 0x9FFF;

bool containsKanji(String text) => text.runes.any(isKanjiChar);

/// Các ký tự Kanji duy nhất trong [text], theo đúng thứ tự xuất hiện lần đầu
/// — dùng để tra âm Hán Việt từng chữ (VD: 旅行 → [旅, 行]) và liệt kê phần
/// "Kanji trong từ".
List<String> uniqueKanjiChars(String text) {
  final seen = <String>{};
  final result = <String>[];
  for (final rune in text.runes) {
    if (!isKanjiChar(rune)) continue;
    final ch = String.fromCharCode(rune);
    if (seen.add(ch)) result.add(ch);
  }
  return result;
}
