import 'dart:math';

import '../entities/lesson.dart';
import '../entities/listening_dialogue.dart';

/// 1 câu hỏi trắc nghiệm được sinh ra từ 1 [LessonContentItem] thật (từ
/// vựng/Kanji/ngữ pháp) — không có nội dung nào bịa, chỉ trình bày lại
/// dữ liệu đã có dưới dạng câu hỏi.
class QuizQuestion {
  const QuizQuestion({
    required this.promptVi,
    required this.displayJp,
    required this.options,
    required this.correctIndex,
    this.sourceType,
    this.readingFurigana,
    this.dialogueTurns,
    this.displayIsJapanese = true,
  });

  /// Dòng hướng dẫn/câu hỏi phía trên — tiếng Việt cho câu hỏi Vocab/Kanji/
  /// Ngữ pháp (VD "Từ này có nghĩa là gì?"); với câu hỏi nghe hiểu hội thoại
  /// (xem [DialogueListeningGenerator]) đây là chính đề bài bằng tiếng Nhật
  /// (`ListeningDialogue.questionJa`) — luyện đọc hiểu tiếng Nhật thật thay
  /// vì chỉ dịch sẵn ra tiếng Việt.
  final String promptVi;

  /// Chữ lớn hiển thị giữa màn — Nhật (kanji/kana) khi [displayIsJapanese],
  /// hoặc nghĩa tiếng Việt khi câu hỏi đảo chiều (chọn từ tiếng Nhật đúng
  /// nghĩa cho sẵn) — xem [QuizGenerator].
  final String displayJp;
  final String? readingFurigana;

  /// false khi [displayJp] là tiếng Việt (câu hỏi đảo chiều) — UI khi đó
  /// không hiện furigana, không phát TTS (đọc tiếng Việt bằng giọng đọc
  /// tiếng Nhật sẽ sai hoàn toàn), và không dùng font chữ Nhật.
  final bool displayIsJapanese;

  /// 2-4 lựa chọn, đã xáo trộn. Độ dài co lại khi không đủ dữ liệu để
  /// tạo nhiễu (xem [QuizGenerator.generate]) thay vì độn đáp án giả.
  final List<String> options;
  final int correctIndex;

  /// null ở câu hỏi nghe hiểu hội thoại (không thuộc riêng 1 loại nội dung).
  final LessonItemType? sourceType;

  /// Chỉ có ở câu hỏi nghe hiểu hội thoại (xem `DialogueListeningGenerator`)
  /// — khi có giá trị, `QuizScreen` đọc TTS lần lượt từng lượt thoại (đổi
  /// giọng theo speaker) thay vì đọc nguyên [displayJp] 1 lần.
  final List<ListeningTurn>? dialogueTurns;
}

/// 4 kiểu hỏi xoay quanh 1 item — thay vì luôn hỏi 1 chiều "chữ Nhật → nghĩa"
/// như trước, trộn thêm chiều ngược ("nghĩa → chữ Nhật") và trục cách đọc
/// (kanji/từ ⇄ hiragana/katakana) để đỡ nhàm và luyện được nhiều kỹ năng
/// hơn (nhận mặt chữ, nhớ nghĩa, nhớ cách đọc).
enum _Direction { termToMeaning, meaningToTerm, termToReading, readingToTerm }

/// Sinh câu hỏi trắc nghiệm trực tiếp từ nội dung bài học/trình độ đã có
/// sẵn (Vocabulary/Kanji/GrammarPoint) — app chưa có ngân hàng câu hỏi
/// riêng nên không bịa nội dung mới, chỉ hỏi lại đúng dữ liệu thật đã có,
/// dưới nhiều góc hỏi khác nhau (xem [_Direction]).
class QuizGenerator {
  const QuizGenerator({Random? random}) : _random = random;

  final Random? _random;

  /// [pool]: nội dung dùng làm câu hỏi (VD: đúng 1 bài học, hoặc toàn bộ
  /// trình độ). [distractorPool]: nguồn nhiễu mở rộng khi [pool] không đủ
  /// đáp án nhiễu khác nghĩa — câu hỏi luôn lấy từ [pool], không bao giờ
  /// lấy từ [distractorPool].
  /// [readingOnly]: chỉ hỏi trục cách đọc (termToReading/readingToTerm) —
  /// dùng cho màn Luyện đọc riêng 1 Kanji (`kanji_reading_practice_providers.dart`),
  /// nơi mục đích là luyện đọc chứ không phải ôn nghĩa. Item nào không có
  /// cách đọc riêng biệt (VD ngữ pháp, hoặc từ kana thuần) vẫn rơi về
  /// termToMeaning thay vì bị loại hẳn — tránh câu hỏi trống, chấp nhận lẫn
  /// 1 câu hỏi nghĩa thay vì bịa cách đọc không có thật.
  List<QuizQuestion> generate({
    required List<LessonContentItem> pool,
    List<LessonContentItem>? distractorPool,
    int questionCount = 10,
    bool readingOnly = false,
  }) {
    final rng = _random ?? Random();

    final poolItems = _validItems(pool);
    final distractorItems = _validItems(distractorPool ?? const []);
    final allCandidates = [...poolItems, ...distractorItems];

    final questionCandidates = _dedupeBy(poolItems, (c) => c.meaning);
    if (questionCandidates.length < 2) return const [];

    final chosen = questionCandidates.toList()..shuffle(rng);
    final selected = chosen.take(min(questionCount, chosen.length));

    return [
      for (final item in selected)
        _buildQuestion(
          item,
          allCandidates,
          _pickDirection(item, allCandidates, rng, readingOnly: readingOnly),
          rng,
        ),
    ];
  }

  /// Chọn ngẫu nhiên 1 chiều hỏi trong số các chiều "an toàn" cho item này
  /// — an toàn nghĩa là (a) trục đáp án tương ứng (nghĩa/chữ/cách đọc) có ít
  /// nhất 2 giá trị khác nhau trong [allCandidates], tránh sinh câu hỏi chỉ
  /// có đúng 1 lựa chọn (không có gì để chọn nhiễu), và (b) chữ hỏi khác chữ
  /// đáp án — từ thuần kana (VD いくら) có `term == reading`, hỏi
  /// termToReading/readingToTerm cho từ này sẽ ra đề trùng hệt đáp án đúng.
  /// [termToMeaning] luôn an toàn (đã được đảm bảo bởi điều kiện
  /// `questionCandidates.length >= 2` ở [generate]) nên luôn có ít nhất 1 lựa
  /// chọn hợp lệ để rơi về.
  _Direction _pickDirection(
    _ContentItem item,
    List<_ContentItem> allCandidates,
    Random rng, {
    bool readingOnly = false,
  }) {
    final hasDistinctReading = item.reading != null &&
        item.reading!.trim().toLowerCase() != item.term.trim().toLowerCase();
    final candidates = <_Direction>[
      if (!readingOnly || !hasDistinctReading) ...[
        _Direction.termToMeaning,
        _Direction.meaningToTerm,
      ],
      if (hasDistinctReading) ...[
        _Direction.termToReading,
        _Direction.readingToTerm,
      ],
    ];
    final eligible = candidates
        .where((d) => _dedupeBy(allCandidates, (c) => _axisOf(c, d)).length >= 2)
        .toList();
    if (eligible.isEmpty) return _Direction.termToMeaning;
    return eligible[rng.nextInt(eligible.length)];
  }

  QuizQuestion _buildQuestion(
    _ContentItem item,
    List<_ContentItem> allCandidates,
    _Direction direction,
    Random rng,
  ) {
    final correctValue = _axisOf(item, direction);

    final optionPool = _dedupeBy(allCandidates, (c) => _axisOf(c, direction));
    final optionSlots = min(4, optionPool.length);

    final distractors = optionPool
        .where((c) =>
            _axisOf(c, direction).trim().toLowerCase() !=
            correctValue.trim().toLowerCase(),)
        .toList()
      ..shuffle(rng);

    final options = <String>[
      correctValue,
      ...distractors.take(optionSlots - 1).map((c) => _axisOf(c, direction)),
    ]..shuffle(rng);

    final displayIsJapanese = direction != _Direction.meaningToTerm;
    final stem = switch (direction) {
      _Direction.termToMeaning || _Direction.termToReading => item.term,
      _Direction.meaningToTerm => item.meaning,
      _Direction.readingToTerm => item.reading!,
    };

    return QuizQuestion(
      promptVi: _promptFor(item.type, direction),
      displayJp: stem,
      displayIsJapanese: displayIsJapanese,
      readingFurigana: direction == _Direction.termToMeaning &&
              item.type == LessonItemType.vocabulary
          ? item.reading
          : null,
      options: options,
      correctIndex: options.indexOf(correctValue),
      sourceType: item.type,
    );
  }

  /// Giá trị dùng làm đáp án/lựa chọn theo từng trục hỏi.
  String _axisOf(_ContentItem item, _Direction direction) => switch (direction) {
        _Direction.termToMeaning => item.meaning,
        _Direction.meaningToTerm => item.term,
        _Direction.termToReading => item.reading ?? '',
        _Direction.readingToTerm => item.term,
      };

  String _promptFor(LessonItemType type, _Direction direction) =>
      switch ((type, direction)) {
        (LessonItemType.vocabulary, _Direction.termToMeaning) =>
          'Từ này có nghĩa là gì?',
        (LessonItemType.vocabulary, _Direction.meaningToTerm) =>
          'Từ nào có nghĩa như trên?',
        (LessonItemType.vocabulary, _Direction.termToReading) =>
          'Từ này đọc là gì?',
        (LessonItemType.vocabulary, _Direction.readingToTerm) =>
          'Cách đọc này là của từ nào?',
        (LessonItemType.kanji, _Direction.termToMeaning) =>
          'Chữ Hán này có nghĩa là gì?',
        (LessonItemType.kanji, _Direction.meaningToTerm) =>
          'Chữ Hán nào có nghĩa như trên?',
        (LessonItemType.kanji, _Direction.termToReading) =>
          'Chữ Hán này đọc là gì?',
        (LessonItemType.kanji, _Direction.readingToTerm) =>
          'Cách đọc này là của chữ Hán nào?',
        (LessonItemType.grammar, _Direction.termToMeaning) =>
          'Điểm ngữ pháp này dùng để làm gì?',
        (LessonItemType.grammar, _Direction.meaningToTerm) =>
          'Điểm ngữ pháp nào dùng như trên?',
        (LessonItemType.grammar, _Direction.termToReading) ||
        (LessonItemType.grammar, _Direction.readingToTerm) =>
          throw UnsupportedError('Ngữ pháp không có trục cách đọc'),
      };

  List<_ContentItem> _validItems(List<LessonContentItem> items) {
    final result = <_ContentItem>[];
    for (final item in items) {
      final term = _termOf(item).trim();
      final meaning = _meaningOf(item).trim();
      if (term.isEmpty || meaning.isEmpty) continue;
      result.add(
        _ContentItem(
          term: term,
          meaning: meaning,
          type: item.type,
          reading: _readingOf(item),
        ),
      );
    }
    return result;
  }

  List<_ContentItem> _dedupeBy(
      Iterable<_ContentItem> items, String Function(_ContentItem) key,) {
    final seen = <String>{};
    final result = <_ContentItem>[];
    for (final item in items) {
      final k = key(item).trim().toLowerCase();
      if (k.isEmpty) continue;
      if (seen.add(k)) result.add(item);
    }
    return result;
  }

  String _termOf(LessonContentItem item) => switch (item.type) {
        LessonItemType.vocabulary => item.vocabulary!.word,
        LessonItemType.kanji => item.kanji!.character,
        LessonItemType.grammar => item.grammar!.title,
      };

  String _meaningOf(LessonContentItem item) => switch (item.type) {
        LessonItemType.vocabulary => item.vocabulary!.primaryMeaning,
        LessonItemType.kanji => item.kanji!.primaryMeaning,
        LessonItemType.grammar => item.grammar!.explanation,
      };

  /// Cách đọc (hiragana/katakana) dùng làm trục hỏi riêng — null nếu item
  /// không có cách đọc nào (VD ngữ pháp, hoặc kanji chưa có dữ liệu on/kun).
  /// Kanji có thể có nhiều âm on/kun — gộp hết thành 1 chuỗi đáp án thay vì
  /// tự chọn đại diện 1 âm (tránh bịa ra "đáp án đúng duy nhất" không có
  /// thật trong dữ liệu).
  String? _readingOf(LessonContentItem item) => switch (item.type) {
        LessonItemType.vocabulary =>
          item.vocabulary!.reading.trim().isEmpty
              ? null
              : item.vocabulary!.reading.trim(),
        LessonItemType.kanji => () {
            final readings = [...item.kanji!.onyomi, ...item.kanji!.kunyomi]
                .map((r) => r.trim())
                .where((r) => r.isNotEmpty)
                .toList();
            return readings.isEmpty ? null : readings.join('・');
          }(),
        LessonItemType.grammar => null,
      };
}

class _ContentItem {
  const _ContentItem({
    required this.term,
    required this.meaning,
    required this.type,
    this.reading,
  });

  final String term;
  final String meaning;
  final LessonItemType type;
  final String? reading;
}
