import 'dart:math';

import '../entities/grammar_point.dart';
import '../entities/kaiwa_message.dart';
import '../entities/lesson.dart';
import '../entities/listening_dialogue.dart';
import '../entities/review_mistake.dart';

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
    this.readingPassageTitle,
    this.readingPassageBodyJa,
    this.displayIsJapanese = true,
    this.typedAnswerMode,
    this.typedAcceptedAnswers = const [],
    this.orderTiles,
    this.orderCorrectSequence = const [],
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

  /// Chỉ có ở câu hỏi Đọc hiểu (xem `ReadingQuestionGenerator`) — khi khác
  /// null, UI hiện khung đoạn văn [readingPassageBodyJa] cố định phía trên
  /// câu hỏi thay vì khung [displayJp] thường. Nhiều câu hỏi liên tiếp có
  /// thể cùng 1 đoạn văn (1 passage — nhiều câu).
  final String? readingPassageTitle;
  final String? readingPassageBodyJa;

  /// null: câu hỏi trắc nghiệm bình thường (chọn giữa [options]). Khác null:
  /// câu hỏi gõ đáp án (Typing/Translation, xem [QuizGenerator.generateTyping]/
  /// [QuizGenerator.generateTranslation]) — `QuizScreen` hiện ô nhập chữ thay
  /// vì danh sách lựa chọn, chấm bằng [isTypedAnswerCorrect] với
  /// [typedAcceptedAnswers] thay vì so `correctIndex`. [options] vẫn giữ đúng
  /// 1 phần tử (đáp án đại diện, `correctIndex == 0`) để tái dùng nguyên
  /// `_FeedbackPanel` hiện "Đáp án đúng" khi trả lời sai — không thêm field
  /// hiển thị trùng lặp.
  final TypedAnswerMode? typedAnswerMode;

  /// Mọi đáp án được coi là đúng khi gõ (VD 1 Kanji có nhiều âm on/kun đều
  /// đúng) — luôn chứa ít nhất [options.first] khi [typedAnswerMode] khác
  /// null. Rỗng ở câu hỏi trắc nghiệm thường.
  final List<String> typedAcceptedAnswers;

  /// null: không phải câu hỏi Ghép câu (Sentence Ordering, xem
  /// [QuizGenerator.generateSentenceOrdering]). Khác null: các từ trong
  /// [orderCorrectSequence] đã bị xáo trộn — `QuizScreen` hiện dạng ô để gõ
  /// từng từ (tap-to-order) thay vì danh sách lựa chọn hay ô nhập chữ, chấm
  /// bằng [isOrderCorrect] so với [orderCorrectSequence] (so đúng thứ tự,
  /// không so nội dung gõ tay). [options] vẫn giữ câu hoàn chỉnh đã ghép
  /// đúng (`correctIndex == 0`) để tái dùng `_FeedbackPanel`.
  final List<String>? orderTiles;

  /// Thứ tự đúng của các từ trong [orderTiles] (chính là `practiceTokens`
  /// gốc, chưa xáo trộn). Rỗng ở câu hỏi không phải Sentence Ordering.
  final List<String> orderCorrectSequence;
}

/// 1 cặp (câu người học thật đã nói, câu AI thật đã trả lời tiếp theo) trong
/// cùng 1 hội thoại Kaiwa đã lưu — input thuần dữ liệu cho
/// [QuizGenerator.generateConversationCompletion]. Việc gom nhóm theo hội
/// thoại + sắp theo thời gian để tạo ra danh sách này thuộc tầng provider
/// (xem `kaiwaConversationTurnsProvider`), tách khỏi domain layer để hàm
/// generate test được độc lập không cần Supabase.
class ConversationTurn {
  const ConversationTurn({
    required this.promptContextJp,
    required this.nextAiReplyJp,
  });

  final String promptContextJp;
  final String nextAiReplyJp;
}

/// Cách chấm câu hỏi gõ đáp án — xem [isTypedAnswerCorrect].
enum TypedAnswerMode {
  /// Typing: gõ đúng cách đọc (kana) của Từ vựng/Kanji — cách đọc là dữ liệu
  /// cố định, không có nhiều cách diễn đạt hợp lệ nên so khớp tuyệt đối sau
  /// khi chuẩn hoá là hợp lý, không cần nới lỏng.
  exact,

  /// Translation: gõ nghĩa tiếng Việt/bản dịch câu ví dụ — 1 nghĩa có thể
  /// diễn đạt nhiều cách, so khớp tuyệt đối sẽ chấm sai oan nhiều câu trả
  /// lời đúng. Chấp nhận khi 1 trong 2 chuỗi (đã chuẩn hoá) chứa chuỗi còn
  /// lại — quyết định người dùng xác nhận (không dùng AI để chấm).
  lenient,
}

/// Chuẩn hoá trước khi so khớp: cắt khoảng trắng đầu/cuối, bỏ phân biệt
/// hoa/thường, và bỏ dấu chấm ngăn okurigana trong ký hiệu cách đọc Kanji từ
/// điển (VD kunyomi "い.きる" → so khớp được với input gõ tay "いきる", vì
/// dấu chấm chỉ là quy ước trình bày, người dùng thật không gõ nó).
String _normalizeTypedAnswer(String value) =>
    value.trim().toLowerCase().replaceAll('.', '');

/// So khớp 1 câu trả lời gõ tay ([typed]) với danh sách đáp án được chấp
/// nhận ([accepted]) theo [mode] — xem [TypedAnswerMode]. Trả về false nếu
/// [typed] rỗng sau khi chuẩn hoá (không tính bỏ trắng là "đúng" theo kiểu
/// accepted rỗng trùng khớp gì đó).
bool isTypedAnswerCorrect(
  String typed,
  List<String> accepted,
  TypedAnswerMode mode,
) {
  final t = _normalizeTypedAnswer(typed);
  if (t.isEmpty) return false;
  for (final raw in accepted) {
    final a = _normalizeTypedAnswer(raw);
    if (a.isEmpty) continue;
    final match = mode == TypedAnswerMode.exact ? t == a : (t.contains(a) || a.contains(t));
    if (match) return true;
  }
  return false;
}

/// So khớp câu trả lời Sentence Ordering — đúng khi [submitted] (thứ tự
/// người dùng ghép tile) giống hệt [correctSequence] cả về nội dung lẫn thứ
/// tự từng phần tử. Không chuẩn hoá (trim/lowercase) vì tile là tap-to-order
/// (chọn nguyên văn từ có sẵn), không phải gõ tay nên không có sai lệch
/// khoảng trắng/hoa-thường để nới lỏng.
bool isOrderCorrect(List<String> submitted, List<String> correctSequence) {
  if (submitted.length != correctSequence.length) return false;
  for (var i = 0; i < submitted.length; i++) {
    if (submitted[i] != correctSequence[i]) return false;
  }
  return true;
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

  /// Sinh câu hỏi Điền từ (fill blank) cho Ngữ pháp — tái dùng đúng cơ chế
  /// `practiceTokens`/`practiceBlankIndex` mà `grammar_practice_generator.dart`
  /// đã dùng cho màn Luyện tập ngữ pháp (chỗ trống + nhiễu lấy từ token cùng
  /// vị trí của mẫu khác), chỉ đổi kiểu trả về thành [QuizQuestion] để trộn
  /// chung được với câu trắc nghiệm khác trong Quiz tổng hợp. [pool] chỉ nên
  /// chứa các [GrammarPoint] đã có `practiceBlankIndex` hợp lệ — caller lọc
  /// trước (xem `mixed_quiz_providers.dart`) để tách khỏi các mẫu chỉ đủ dữ
  /// liệu cho câu hỏi nghĩa thông thường.
  List<QuizQuestion> generateGrammarFillBlank({
    required List<GrammarPoint> pool,
    int questionCount = 10,
  }) {
    final rng = _random ?? Random();

    final eligible = pool
        .where((g) =>
            g.practiceBlankIndex != null &&
            g.practiceBlankIndex! >= 0 &&
            g.practiceBlankIndex! < g.practiceTokens.length,)
        .toList();
    if (eligible.length < 2) return const [];

    final chosen = eligible.toList()..shuffle(rng);
    final selected = chosen.take(min(questionCount, chosen.length));

    return [
      for (final g in selected) _buildFillBlankQuestion(g, eligible, rng),
    ];
  }

  QuizQuestion _buildFillBlankQuestion(
    GrammarPoint g,
    List<GrammarPoint> allCandidates,
    Random rng,
  ) {
    final blankIndex = g.practiceBlankIndex!;
    final correctAnswer = g.practiceTokens[blankIndex];
    final blankPrompt = [
      for (var i = 0; i < g.practiceTokens.length; i++)
        i == blankIndex ? '___' : g.practiceTokens[i],
    ].join('');

    final distractorPool = <String>{
      for (final other in allCandidates)
        if (other.id != g.id) other.practiceTokens[other.practiceBlankIndex!],
    }..remove(correctAnswer);

    final distractors = distractorPool.toList()..shuffle(rng);
    final options = <String>[correctAnswer, ...distractors.take(3)]
      ..shuffle(rng);

    return QuizQuestion(
      promptVi: 'Điền từ còn thiếu vào chỗ trống:',
      displayJp: blankPrompt,
      options: options,
      correctIndex: options.indexOf(correctAnswer),
      sourceType: LessonItemType.grammar,
    );
  }

  /// Sinh câu hỏi Gõ đáp án (Typing) cho Từ vựng/Kanji — hiện chữ, gõ lại
  /// cách đọc (kana). Chỉ nhận [LessonItemType.vocabulary]/[LessonItemType.kanji]
  /// có cách đọc thật (item không có cách đọc bị bỏ qua, không bịa). Kanji có
  /// nhiều âm on/kun đều được chấp nhận riêng lẻ (không gộp nối bằng "・" như
  /// [_readingOf] dùng cho câu trắc nghiệm, vì người gõ chỉ gõ 1 âm/lần).
  List<QuizQuestion> generateTyping({
    required List<LessonContentItem> pool,
    int questionCount = 10,
  }) {
    final rng = _random ?? Random();
    final candidates = <QuizQuestion>[
      for (final item in pool)
        if (_typingQuestion(item) case final q?) q,
    ];
    candidates.shuffle(rng);
    return candidates.take(min(questionCount, candidates.length)).toList();
  }

  QuizQuestion? _typingQuestion(LessonContentItem item) {
    final term = _termOf(item).trim();
    if (term.isEmpty) return null;
    final accepted = switch (item.type) {
      LessonItemType.vocabulary => item.vocabulary!.reading.trim().isEmpty
          ? const <String>[]
          : [item.vocabulary!.reading.trim()],
      LessonItemType.kanji => [...item.kanji!.onyomi, ...item.kanji!.kunyomi]
          .map((r) => r.trim())
          .where((r) => r.isNotEmpty)
          .toList(),
      LessonItemType.grammar => const <String>[],
    };
    if (accepted.isEmpty) return null;
    return QuizQuestion(
      promptVi: item.type == LessonItemType.vocabulary
          ? 'Gõ cách đọc (hiragana/katakana) của từ này:'
          : 'Gõ 1 cách đọc (On hoặc Kun) của chữ Hán này:',
      displayJp: term,
      options: [accepted.first],
      correctIndex: 0,
      sourceType: item.type,
      typedAnswerMode: TypedAnswerMode.exact,
      typedAcceptedAnswers: accepted,
    );
  }

  /// Sinh câu hỏi Dịch (Translation) — Từ vựng: hiện từ, gõ nghĩa tiếng Việt
  /// (`primaryMeaning` thật). Ngữ pháp: hiện `exampleJp`, gõ bản dịch
  /// `exampleVi` thật của câu ví dụ — chỉ nhận mẫu có đủ cả 2, không tự dịch.
  /// Không áp dụng cho Kanji (thiết kế chỉ định Vocab/Grammar — 1 Kanji đơn lẻ
  /// không có "bản dịch" để gõ, khác với nghĩa đã hỏi ở câu trắc nghiệm).
  List<QuizQuestion> generateTranslation({
    required List<LessonContentItem> pool,
    int questionCount = 10,
  }) {
    final rng = _random ?? Random();
    final candidates = <QuizQuestion>[
      for (final item in pool)
        if (_translationQuestion(item) case final q?) q,
    ];
    candidates.shuffle(rng);
    return candidates.take(min(questionCount, candidates.length)).toList();
  }

  QuizQuestion? _translationQuestion(LessonContentItem item) {
    if (item.type == LessonItemType.vocabulary) {
      final term = item.vocabulary!.word.trim();
      final meaning = item.vocabulary!.primaryMeaning.trim();
      if (term.isEmpty || meaning.isEmpty) return null;
      return QuizQuestion(
        promptVi: 'Từ này có nghĩa là gì? Gõ nghĩa tiếng Việt:',
        displayJp: term,
        options: [meaning],
        correctIndex: 0,
        sourceType: LessonItemType.vocabulary,
        typedAnswerMode: TypedAnswerMode.lenient,
        typedAcceptedAnswers: [meaning],
      );
    }
    if (item.type == LessonItemType.grammar) {
      final jp = (item.grammar!.exampleJp ?? '').trim();
      final vi = (item.grammar!.exampleVi ?? '').trim();
      if (jp.isEmpty || vi.isEmpty) return null;
      return QuizQuestion(
        promptVi: 'Dịch câu ví dụ này sang tiếng Việt:',
        displayJp: jp,
        options: [vi],
        correctIndex: 0,
        sourceType: LessonItemType.grammar,
        typedAnswerMode: TypedAnswerMode.lenient,
        typedAcceptedAnswers: [vi],
      );
    }
    return null;
  }

  /// Sinh câu hỏi Ghép câu (Sentence Ordering) — xáo `practiceTokens` thành
  /// tile, người dùng ghép lại đúng thứ tự gốc. Không cần `practiceBlankIndex`
  /// (khác Fill Blank). Chỉ nhận mẫu có `exampleVi` thật để hiện làm gợi ý
  /// nghĩa (hiện tiếng Việt, không hiện trước câu tiếng Nhật — sẽ lộ đáp án)
  /// — không có gợi ý nghĩa thì bài ghép câu vô nghĩa vì có thể ghép đúng
  /// ngữ pháp nhưng sai ý định luyện (VD ghép được câu khác cũng hợp lệ ngữ
  /// pháp nhưng không phải câu app muốn hỏi).
  List<QuizQuestion> generateSentenceOrdering({
    required List<GrammarPoint> pool,
    int questionCount = 10,
  }) {
    final rng = _random ?? Random();
    final eligible = pool
        .where((g) =>
            g.practiceTokens.length >= 3 && (g.exampleVi ?? '').trim().isNotEmpty,)
        .toList();
    if (eligible.isEmpty) return const [];

    final chosen = eligible.toList()..shuffle(rng);
    final selected = chosen.take(min(questionCount, chosen.length));

    return [
      for (final g in selected) _buildSentenceOrderingQuestion(g, rng),
    ];
  }

  QuizQuestion _buildSentenceOrderingQuestion(GrammarPoint g, Random rng) {
    final correctSequence = List<String>.of(g.practiceTokens);
    final tiles = List<String>.of(g.practiceTokens)..shuffle(rng);
    // shuffle() ngẫu nhiên hiếm khi ra đúng thứ tự gốc (đề bài trùng đáp án
    // luôn) — đảo 2 phần tử đầu để đảm bảo luôn khác, không ảnh hưởng tính
    // ngẫu nhiên chung vì trường hợp này cực hiếm.
    if (isOrderCorrect(tiles, correctSequence) && tiles.length > 1) {
      final tmp = tiles[0];
      tiles[0] = tiles[1];
      tiles[1] = tmp;
    }

    return QuizQuestion(
      promptVi: 'Sắp xếp các từ dưới đây thành câu đúng nghĩa:',
      displayJp: g.exampleVi!.trim(),
      displayIsJapanese: false,
      options: [correctSequence.join('')],
      correctIndex: 0,
      sourceType: LessonItemType.grammar,
      orderTiles: tiles,
      orderCorrectSequence: correctSequence,
    );
  }

  /// Sinh câu hỏi Chọn mẫu ngữ pháp (Grammar Selection) — hiện `exampleJp`
  /// thật, chọn đúng tên/mẫu ngữ pháp (`title`) minh hoạ cho câu đó trong số
  /// `title` của các mẫu khác trong [pool] — ngược chiều với bài
  /// `matchSentence` ở `grammar_practice_generator.dart` (bài đó hiện mẫu,
  /// chọn câu; bài này hiện câu, chọn mẫu), tái dùng đúng cặp dữ liệu
  /// title/exampleJp thật, không viết thêm nội dung.
  List<QuizQuestion> generateGrammarSelection({
    required List<GrammarPoint> pool,
    int questionCount = 10,
  }) {
    final rng = _random ?? Random();
    final eligible = pool
        .where((g) => (g.exampleJp ?? '').trim().isNotEmpty && g.title.trim().isNotEmpty)
        .toList();
    final distinctTitles = <String>{for (final g in eligible) g.title.trim().toLowerCase()};
    if (eligible.length < 2 || distinctTitles.length < 2) return const [];

    final chosen = eligible.toList()..shuffle(rng);
    final selected = chosen.take(min(questionCount, chosen.length));

    return [
      for (final g in selected) _buildGrammarSelectionQuestion(g, eligible, rng),
    ];
  }

  QuizQuestion _buildGrammarSelectionQuestion(
    GrammarPoint g,
    List<GrammarPoint> allCandidates,
    Random rng,
  ) {
    final correctTitle = g.title.trim();
    final distractorPool = <String>{
      for (final other in allCandidates) other.title.trim(),
    }..removeWhere((t) => t.toLowerCase() == correctTitle.toLowerCase());

    final distractors = distractorPool.toList()..shuffle(rng);
    final options = <String>[correctTitle, ...distractors.take(3)]..shuffle(rng);

    return QuizQuestion(
      promptVi: 'Câu này minh hoạ cho mẫu ngữ pháp nào?',
      displayJp: g.exampleJp!.trim(),
      options: options,
      correctIndex: options.indexOf(correctTitle),
      sourceType: LessonItemType.grammar,
    );
  }

  /// Các trợ từ tiếng Nhật cơ bản dùng để (a) nhận diện token nào trong
  /// `practiceTokens` là trợ từ (không đoán mò dựa vào độ dài chữ), và (b)
  /// làm nhiễu dự phòng khi pool không đủ trợ từ thật khác cho 1 vị trí —
  /// đây là kiến thức ngữ pháp cố định (giống cách `_promptFor` cố định
  /// chuỗi hỏi), không phải nội dung học bịa ra.
  static const _particleSet = {'は', 'が', 'を', 'に', 'で', 'へ', 'と', 'も', 'の', 'や'};

  /// Sinh câu hỏi Chọn trợ từ (Particle Selection) — ẩn đúng 1 token là trợ
  /// từ thật trong `practiceTokens` (nhận diện qua [_particleSet], không
  /// phải token bất kỳ như Fill Blank), nhiễu ưu tiên lấy trợ từ thật xuất
  /// hiện ở mẫu khác trong [pool], chỉ dùng [_particleSet] làm nhiễu dự
  /// phòng khi thiếu.
  List<QuizQuestion> generateParticleSelection({
    required List<GrammarPoint> pool,
    int questionCount = 10,
  }) {
    final rng = _random ?? Random();
    final withParticle = <(GrammarPoint, int)>[];
    for (final g in pool) {
      final indices = _particleIndices(g).toList();
      if (indices.isEmpty) continue;
      indices.shuffle(rng);
      withParticle.add((g, indices.first));
    }
    if (withParticle.length < 2) return const [];

    final allParticlesInPool = <String>{
      for (final g in pool)
        for (final i in _particleIndices(g)) g.practiceTokens[i],
    };

    final chosen = withParticle.toList()..shuffle(rng);
    final selected = chosen.take(min(questionCount, chosen.length));

    return [
      for (final (g, idx) in selected)
        _buildParticleQuestion(g, idx, allParticlesInPool, rng),
    ];
  }

  Iterable<int> _particleIndices(GrammarPoint g) sync* {
    for (var i = 0; i < g.practiceTokens.length; i++) {
      if (_particleSet.contains(g.practiceTokens[i].trim())) yield i;
    }
  }

  QuizQuestion _buildParticleQuestion(
    GrammarPoint g,
    int blankIndex,
    Set<String> particlesInPool,
    Random rng,
  ) {
    final correctAnswer = g.practiceTokens[blankIndex];
    final blankPrompt = [
      for (var i = 0; i < g.practiceTokens.length; i++)
        i == blankIndex ? '___' : g.practiceTokens[i],
    ].join('');

    final distractorPool = <String>{...particlesInPool, ..._particleSet}
      ..remove(correctAnswer);
    final distractors = distractorPool.toList()..shuffle(rng);
    final options = <String>[correctAnswer, ...distractors.take(3)]..shuffle(rng);

    return QuizQuestion(
      promptVi: 'Chọn trợ từ đúng vào chỗ trống:',
      displayJp: blankPrompt,
      options: options,
      correctIndex: options.indexOf(correctAnswer),
      sourceType: LessonItemType.grammar,
    );
  }

  /// Sinh câu hỏi Sửa lỗi (Error Correction) từ Sổ tay lỗi thật — hiện đúng
  /// câu trả lời sai đã ghi nhận ([ReviewMistake.originalAnswer]), chọn đáp
  /// án đúng thật ([ReviewMistake.correctAnswer]) trong số đáp án đúng của
  /// các lỗi khác làm nhiễu. Chỉ nhận mục có `originalAnswer` (field này có
  /// thể null theo entity, không phải mọi lỗi đều ghi lại được câu trả lời
  /// sai) — không suy đoán khi thiếu dữ liệu thật. Ngôn ngữ của
  /// `originalAnswer` không xác định trước (có thể là chữ Nhật hoặc nghĩa
  /// tiếng Việt tuỳ chiều câu hỏi gốc đã sai) nên hiện với
  /// `displayIsJapanese: false` để tránh áp nhầm font/giọng đọc tiếng Nhật
  /// lên văn bản tiếng Việt.
  List<QuizQuestion> generateErrorCorrectionFromMistakes({
    required List<ReviewMistake> pool,
    int questionCount = 10,
  }) {
    final rng = _random ?? Random();
    final eligible = pool
        .where((m) =>
            (m.originalAnswer ?? '').trim().isNotEmpty && m.correctAnswer.trim().isNotEmpty,)
        .toList();
    final distinctAnswers = <String>{
      for (final m in eligible) m.correctAnswer.trim().toLowerCase(),
    };
    if (eligible.length < 2 || distinctAnswers.length < 2) return const [];

    final chosen = eligible.toList()..shuffle(rng);
    final selected = chosen.take(min(questionCount, chosen.length));

    return [
      for (final m in selected) _buildMistakeCorrectionQuestion(m, eligible, rng),
    ];
  }

  QuizQuestion _buildMistakeCorrectionQuestion(
    ReviewMistake m,
    List<ReviewMistake> allCandidates,
    Random rng,
  ) {
    final correctAnswer = m.correctAnswer.trim();
    final distractorPool = <String>{
      for (final other in allCandidates) other.correctAnswer.trim(),
    }..removeWhere((a) => a.toLowerCase() == correctAnswer.toLowerCase());
    final distractors = distractorPool.toList()..shuffle(rng);
    final options = <String>[correctAnswer, ...distractors.take(3)]..shuffle(rng);

    return QuizQuestion(
      promptVi: 'Bạn từng trả lời sai câu này — đáp án đúng là gì?',
      displayJp: m.originalAnswer!.trim(),
      displayIsJapanese: false,
      options: options,
      correctIndex: options.indexOf(correctAnswer),
      sourceType: _lessonItemTypeOfMistakeSource(m.sourceType),
    );
  }

  LessonItemType? _lessonItemTypeOfMistakeSource(String sourceType) =>
      switch (sourceType) {
        'vocab' => LessonItemType.vocabulary,
        'kanji' => LessonItemType.kanji,
        'grammar' => LessonItemType.grammar,
        _ => null,
      };

  /// Sinh câu hỏi Sửa lỗi (Error Correction) từ AI Kaiwa History — hiện câu
  /// người học từng nói thật ([KaiwaMessage.contentJp]), chọn đúng cách nói
  /// tự nhiên hơn mà AI đã chấm thật ([KaiwaFeedback.betterPhrasing]) trong
  /// số cách nói tự nhiên hơn của các tin nhắn khác làm nhiễu. [pool] nên đã
  /// lọc [KaiwaMessage.isReviewable] (xem entity — tự đảm bảo có feedback
  /// thật và `betterPhrasing` khác câu gốc). `sourceType` để `null` vì Kaiwa
  /// không thuộc riêng Vocab/Kanji/Ngữ pháp (giống quy ước ở câu nghe hiểu
  /// hội thoại).
  List<QuizQuestion> generateErrorCorrectionFromKaiwa({
    required List<KaiwaMessage> pool,
    int questionCount = 10,
  }) {
    final rng = _random ?? Random();
    final eligible = pool.where((m) => m.isReviewable).toList();
    final distinctPhrasings = <String>{
      for (final m in eligible) m.feedback!.betterPhrasing.trim().toLowerCase(),
    };
    if (eligible.length < 2 || distinctPhrasings.length < 2) return const [];

    final chosen = eligible.toList()..shuffle(rng);
    final selected = chosen.take(min(questionCount, chosen.length));

    return [
      for (final m in selected) _buildKaiwaCorrectionQuestion(m, eligible, rng),
    ];
  }

  QuizQuestion _buildKaiwaCorrectionQuestion(
    KaiwaMessage m,
    List<KaiwaMessage> allCandidates,
    Random rng,
  ) {
    final correctAnswer = m.feedback!.betterPhrasing.trim();
    final distractorPool = <String>{
      for (final other in allCandidates) other.feedback!.betterPhrasing.trim(),
    }..removeWhere((a) => a.toLowerCase() == correctAnswer.toLowerCase());
    final distractors = distractorPool.toList()..shuffle(rng);
    final options = <String>[correctAnswer, ...distractors.take(3)]..shuffle(rng);

    return QuizQuestion(
      promptVi: 'Câu này có thể nói tự nhiên hơn — chọn cách nói đúng:',
      displayJp: m.contentJp.trim(),
      options: options,
      correctIndex: options.indexOf(correctAnswer),
    );
  }

  /// Sinh câu hỏi Hoàn thành hội thoại (Conversation Completion) từ AI Kaiwa
  /// History — hiện câu người học thật đã nói ([ConversationTurn.promptContextJp]),
  /// chọn đúng câu AI THẬT đã trả lời tiếp theo trong đúng hội thoại đó
  /// ([ConversationTurn.nextAiReplyJp]) trong số câu trả lời AI thật ở các
  /// hội thoại khác làm nhiễu. [pool] do tầng provider dựng sẵn (cần gom
  /// nhóm theo hội thoại + sắp theo thời gian, việc thuộc tầng dữ liệu, xem
  /// `kaiwaConversationTurnsProvider`) — hàm này chỉ nhận dữ liệu thuần để
  /// test độc lập không cần Supabase.
  List<QuizQuestion> generateConversationCompletion({
    required List<ConversationTurn> pool,
    int questionCount = 10,
  }) {
    final rng = _random ?? Random();
    final eligible = pool
        .where((t) =>
            t.promptContextJp.trim().isNotEmpty && t.nextAiReplyJp.trim().isNotEmpty,)
        .toList();
    final distinctReplies = <String>{
      for (final t in eligible) t.nextAiReplyJp.trim().toLowerCase(),
    };
    if (eligible.length < 2 || distinctReplies.length < 2) return const [];

    final chosen = eligible.toList()..shuffle(rng);
    final selected = chosen.take(min(questionCount, chosen.length));

    return [
      for (final t in selected)
        _buildConversationCompletionQuestion(t, eligible, rng),
    ];
  }

  QuizQuestion _buildConversationCompletionQuestion(
    ConversationTurn t,
    List<ConversationTurn> allCandidates,
    Random rng,
  ) {
    final correctReply = t.nextAiReplyJp.trim();
    final distractorPool = <String>{
      for (final other in allCandidates) other.nextAiReplyJp.trim(),
    }..removeWhere((r) => r.toLowerCase() == correctReply.toLowerCase());
    final distractors = distractorPool.toList()..shuffle(rng);
    final options = <String>[correctReply, ...distractors.take(3)]..shuffle(rng);

    return QuizQuestion(
      promptVi: 'Bạn vừa nói câu này trong hội thoại — AI đã trả lời gì tiếp theo?',
      displayJp: t.promptContextJp.trim(),
      options: options,
      correctIndex: options.indexOf(correctReply),
    );
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
