import 'dart:math';

import '../entities/grammar_point.dart';
import '../entities/grammar_practice_question.dart';
import '../entities/lesson.dart';
import '../entities/vocabulary.dart';
import 'quiz_generator.dart';

/// Hai họ chiến lược ra đề cho phần Luyện tập. Khung giao diện, chấm điểm và
/// điều hướng dùng chung; chỉ cách TẠO câu hỏi khác nhau.
///  * [jlpt]: N5–N1 — kiểm tra kiến thức ngôn ngữ theo cấp độ, dạng bài gần JLPT.
///  * [it]: Tiếng Nhật IT — tình huống công việc, thuật ngữ IT, giao tiếp công sở.
enum PracticeProfile { jlpt, it }

PracticeProfile practiceProfileFor(String? levelCode) =>
    levelCode == 'IT' ? PracticeProfile.it : PracticeProfile.jlpt;

PracticeStrategy practiceStrategyFor(
  PracticeProfile profile, {
  QuizGenerator generator = const QuizGenerator(),
}) =>
    switch (profile) {
      PracticeProfile.jlpt => JlptPracticeStrategy(generator),
      PracticeProfile.it => ItPracticeStrategy(generator),
    };

/// Mỗi phần luyện tập (Từ vựng, Ngữ pháp, Kanji) có một hàm sinh câu hỏi.
/// Nghe hiểu lấy hội thoại thật từ DB nên không nằm ở đây
/// (xem `DialogueListeningGenerator`).
abstract interface class PracticeStrategy {
  List<QuizQuestion> vocabulary(List<Vocabulary> items, int count);

  List<QuizQuestion> grammar(
    List<GrammarPoint> items,
    int count, {
    List<GrammarPracticeQuestion> curated = const [],
  });

  /// [kanjiItems]: Kanji riêng của cấp độ; [vocabulary]: từ vựng trong phạm vi
  /// đang luyện (khóa IT không có bộ Kanji riêng nên hỏi Kanji qua từ vựng).
  List<QuizQuestion> kanji({
    required List<LessonContentItem> kanjiItems,
    required List<Vocabulary> vocabulary,
    required int count,
  });
}

/// N5–N1: giữ đúng hành vi cũ (nghĩa ⇄ chữ ⇄ cách đọc từ nội dung từng cấp).
class JlptPracticeStrategy implements PracticeStrategy {
  const JlptPracticeStrategy(this._gen);

  final QuizGenerator _gen;

  @override
  List<QuizQuestion> vocabulary(List<Vocabulary> items, int count) =>
      _gen.generate(
        pool: [for (final v in items) LessonContentItem.vocabulary(v)],
        questionCount: count,
      );

  @override
  List<QuizQuestion> grammar(
    List<GrammarPoint> items,
    int count, {
    List<GrammarPracticeQuestion> curated = const [],
  }) =>
      _gen.generate(
        pool: [for (final g in items) LessonContentItem.grammar(g)],
        questionCount: count,
      );

  @override
  List<QuizQuestion> kanji({
    required List<LessonContentItem> kanjiItems,
    required List<Vocabulary> vocabulary,
    required int count,
  }) =>
      _gen.generate(pool: kanjiItems, questionCount: count);
}

/// Tiếng Nhật IT: ưu tiên câu hỏi gắn với tình huống thật trong giáo trình.
///  * Từ vựng: thêm câu điền từ vào câu ví dụ thật (tối đa 1/3), kèm lời giải.
///  * Ngữ pháp: câu điền chỗ trống đã soạn (có nhiễu + lời giải + nguồn) trước,
///    rồi "câu nào dùng đúng mẫu", cuối cùng nghĩa/mẫu như cũ.
///  * Kanji: hỏi cách đọc của CẢ TỪ (không tách chữ khỏi từ làm sai cách đọc).
class ItPracticeStrategy implements PracticeStrategy {
  const ItPracticeStrategy(this._gen, {Random? random}) : _random = random;

  final QuizGenerator _gen;
  final Random? _random;

  @override
  List<QuizQuestion> vocabulary(List<Vocabulary> items, int count) {
    final cloze = _gen.generateVocabCloze(pool: items, questionCount: count ~/ 4);
    final situation =
        _gen.generateVocabSituation(pool: items, questionCount: count ~/ 4);
    final base = _gen.generate(
      pool: [for (final v in items) LessonContentItem.vocabulary(v)],
      questionCount: count - cloze.length - situation.length,
    );
    if (cloze.isEmpty && situation.isEmpty) return base;
    return _mix([...base, ...cloze, ...situation], count);
  }

  @override
  List<QuizQuestion> grammar(
    List<GrammarPoint> items,
    int count, {
    List<GrammarPracticeQuestion> curated = const [],
  }) {
    // Câu đã soạn (đã xáo): lấy tối đa một nửa làm chính, phần dư để bù nếu
    // các dạng còn lại không đủ câu.
    final allCurated = _gen.generateCuratedGrammarCloze(
      pool: curated,
      questionCount: curated.length,
    );
    final cloze = allCurated.take((count + 1) ~/ 2).toList();
    final spare = allCurated.skip(cloze.length).toList();
    final picks = _gen.generateGrammarSentencePick(
      pool: items,
      questionCount: (count - cloze.length) ~/ 2,
    );
    final base = _gen.generate(
      pool: [for (final g in items) LessonContentItem.grammar(g)],
      questionCount: count - cloze.length - picks.length,
    );
    final all = [...cloze, ...picks, ...base];
    if (all.length < count) all.addAll(spare.take(count - all.length));
    return _mix(all, count);
  }

  @override
  List<QuizQuestion> kanji({
    required List<LessonContentItem> kanjiItems,
    required List<Vocabulary> vocabulary,
    required int count,
  }) {
    final words = generateWordReadingQuestions(
      pool: vocabulary,
      questionCount: count,
      random: _random,
    );
    if (words.isNotEmpty) return words;
    // Không có từ chứa Kanji đủ điều kiện → dùng Kanji đơn như trước.
    return _gen.generate(pool: kanjiItems, questionCount: count);
  }

  List<QuizQuestion> _mix(List<QuizQuestion> all, int count) =>
      (all..shuffle(_random)).take(count).toList();
}

final _kanjiChar = RegExp(r'[一-鿿々]');

/// Từ có chứa ít nhất một chữ Kanji (điều kiện để hỏi cách đọc cả từ).
bool containsKanji(String word) => _kanjiChar.hasMatch(word);
final _hiraganaReading = RegExp(r'^[ぁ-ゖー]+$');

/// Câu hỏi "Chọn cách đọc đúng" cho cả từ chứa Kanji (thuật ngữ thực tế).
///
/// Đáp án nhiễu là biến thể một chỗ của cách đọc đúng — nhầm nguyên âm
/// (か↔け, は↔ほ), nhầm trường âm (ょう↔ょ, おう↔お), nhầm đục/trong
/// (か↔が), bỏ っ — đúng kiểu đề đọc chữ Kanji của JLPT. Từ nào có nhiều
/// cách đọc trong dữ liệu (cùng chữ, khác cách đọc) bị bỏ qua để không có 2
/// đáp án cùng đúng; từ không đủ 3 nhiễu hợp lệ cũng bị bỏ thay vì độn.
List<QuizQuestion> generateWordReadingQuestions({
  required List<Vocabulary> pool,
  int questionCount = 10,
  Random? random,
}) {
  final rng = random ?? Random();

  final readingsByWord = <String, Set<String>>{};
  for (final v in pool) {
    readingsByWord.putIfAbsent(v.word.trim(), () => {}).add(v.reading.trim());
  }

  final eligible = <Vocabulary>[];
  final seen = <String>{};
  for (final v in pool) {
    final word = v.word.trim();
    final reading = v.reading.trim();
    if (!_kanjiChar.hasMatch(word) || !_hiraganaReading.hasMatch(reading)) {
      continue;
    }
    if ((readingsByWord[word]?.length ?? 0) != 1) continue;
    if (seen.add(word)) eligible.add(v);
  }
  eligible.shuffle(rng);

  final allReadings = {for (final v in eligible) v.reading.trim()}.toList();
  final out = <QuizQuestion>[];
  for (final v in eligible) {
    if (out.length >= questionCount) break;
    final word = v.word.trim();
    final reading = v.reading.trim();
    final forbidden = {reading, ...?readingsByWord[word]};

    final variants = (readingVariants(reading)..removeAll(forbidden)).toList()
      ..shuffle(rng);
    final distractors = variants.take(3).toList();
    if (distractors.length < 3) {
      // Từ quá ngắn để biến đổi đủ 3 kiểu: bù bằng cách đọc thật của từ khác
      // cùng độ dài (chắc chắn sai với từ này).
      final real = [
        for (final r in allReadings)
          if (!forbidden.contains(r) &&
              !distractors.contains(r) &&
              r.length == reading.length)
            r,
      ]..shuffle(rng);
      distractors.addAll(real.take(3 - distractors.length));
    }
    if (distractors.length < 3) continue;

    final options = [reading, ...distractors]..shuffle(rng);
    final meaning = v.primaryMeaning;
    out.add(QuizQuestion(
      promptVi: 'Chọn cách đọc đúng của từ này',
      displayJp: word,
      options: options,
      correctIndex: options.indexOf(reading),
      sourceType: LessonItemType.vocabulary,
      explanationVi: '「$word」 đọc là 「$reading」'
          '${meaning.isEmpty ? '' : ' — $meaning'}.',
    ),);
  }
  return out;
}

const _rows = [
  'あいうえお',
  'かきくけこ',
  'さしすせそ',
  'たちつてと',
  'なにぬねの',
  'はひふへほ',
  'まみむめも',
  'らりるれろ',
];
// Cặp nguyên âm dễ nhầm trong cùng một hàng: a↔o/e, i↔e, u↔o.
const _confusableVowel = {
  0: [4, 3],
  1: [3],
  2: [4],
  3: [1, 0],
  4: [0, 2],
};

const _voicing = {
  'か': 'が', 'き': 'ぎ', 'く': 'ぐ', 'け': 'げ', 'こ': 'ご',
  'さ': 'ざ', 'し': 'じ', 'す': 'ず', 'せ': 'ぜ', 'そ': 'ぞ',
  'た': 'だ', 'て': 'で', 'と': 'ど',
  'は': 'ば', 'ひ': 'び', 'ふ': 'ぶ', 'へ': 'べ', 'ほ': 'ぼ',
};

final _unvoicing = {for (final e in _voicing.entries) e.value: e.key};

/// Các biến thể "gần giống nhưng sai" của một cách đọc hiragana (không gồm
/// chính nó). Mỗi biến thể chỉ khác cách đọc gốc đúng một chỗ.
Set<String> readingVariants(String reading) {
  final out = <String>{};
  final chars = reading.split('');

  String replaceAt(int i, String c) =>
      [...chars.sublist(0, i), c, ...chars.sublist(i + 1)].join();

  for (var i = 0; i < chars.length; i++) {
    final c = chars[i];
    final next = i + 1 < chars.length ? chars[i + 1] : '';
    // Nhầm nguyên âm trong cùng hàng. Không đổi 「う」(thường là dấu kéo dài
    // của ょう/ゅう/おう) và không đổi kana đứng trước ゃゅょ (き+ょ → け+ょ là
    // chính tả không tồn tại).
    final canSwapVowel = c != 'う' && !'ゃゅょ'.contains(next.isEmpty ? '_' : next);
    for (final row in canSwapVowel ? _rows : const <String>[]) {
      final col = row.indexOf(c);
      if (col < 0) continue;
      for (final to in _confusableVowel[col] ?? const <int>[]) {
        out.add(replaceAt(i, row[to]));
      }
    }
    // Nhầm đục/trong.
    final voiced = _voicing[c] ?? _unvoicing[c];
    if (voiced != null) out.add(replaceAt(i, voiced));
    // Bỏ っ.
    if (c == 'っ' && chars.length > 2) {
      out.add([...chars.sublist(0, i), ...chars.sublist(i + 1)].join());
    }
    // Nhầm trường âm: ょう/ゅう/おう ⇄ ょ/ゅ/お.
    if ((c == 'ょ' || c == 'ゅ') && next == 'う') {
      out.add([...chars.sublist(0, i + 1), ...chars.sublist(i + 2)].join());
    } else if ((c == 'ょ' || c == 'ゅ') && !'うーんっ'.contains(next.isEmpty ? '_' : next)) {
      out.add([...chars.sublist(0, i + 1), 'う', ...chars.sublist(i + 1)].join());
    }
    if (c == 'お' && next == 'う' && i > 0) {
      out.add([...chars.sublist(0, i + 1), ...chars.sublist(i + 2)].join());
    }
  }
  out.remove(reading);
  return out;
}
