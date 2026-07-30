import 'dart:math';

import '../entities/grammar_point.dart';

/// 3 kiểu bài trong 1 phiên Practice — chọn theo dữ liệu thật đã soạn cho
/// từng mẫu (xem `GrammarPoint.practiceTokens`/`practiceBlankIndex`), không
/// bịa bài cho mẫu chưa có dữ liệu phù hợp.
enum GrammarExerciseType { wordOrder, fillBlank, matchSentence }

/// 1 câu hỏi Practice sinh từ 1 [GrammarPoint] thật.
class GrammarExercise {
  const GrammarExercise({
    required this.type,
    required this.source,
    this.tiles = const [],
    this.blankPrompt,
    this.options = const [],
    this.correctIndex = 0,
  });

  final GrammarExerciseType type;
  final GrammarPoint source;

  /// [GrammarExerciseType.wordOrder]: tile đã xáo trộn — đáp án đúng là
  /// đúng thứ tự trong `source.practiceTokens`.
  final List<String> tiles;

  /// [GrammarExerciseType.fillBlank]: câu có sẵn chỗ trống "___" thay cho từ
  /// tại `source.practiceBlankIndex`.
  final String? blankPrompt;

  /// [GrammarExerciseType.fillBlank]/[GrammarExerciseType.matchSentence]:
  /// lựa chọn đã xáo trộn.
  final List<String> options;

  /// Index đáp án đúng trong [options] (đã tính theo thứ tự sau xáo trộn).
  final int correctIndex;
}

const int _minWordOrderTiles = 3;

/// Sinh 1 phiên Practice từ [pool] (thường là toàn bộ ngữ pháp của 1 cấp
/// độ). Mỗi [GrammarPoint] được gán đúng 1 kiểu bài theo dữ liệu nó có:
/// - có `practiceBlankIndex` → [GrammarExerciseType.fillBlank], nhiễu lấy từ
///   token cùng vị trí của các mẫu khác trong pool (đều là dữ liệu thật).
/// - có `practiceTokens` (≥3 từ) nhưng không có blank index →
///   [GrammarExerciseType.wordOrder].
/// - còn lại (không có `practiceTokens` phù hợp) →
///   [GrammarExerciseType.matchSentence], nhiễu lấy `exampleJp` của mẫu khác
///   trong pool — không cần dữ liệu soạn thêm, đúng kiểu tái dùng đã có ở
///   `QuizGenerator`.
List<GrammarExercise> generatePracticeSession({
  required List<GrammarPoint> pool,
  int exerciseCount = 10,
  Random? random,
}) {
  final rng = random ?? Random();

  final withExample = pool.where((g) => (g.exampleJp ?? '').trim().isNotEmpty).toList();
  if (withExample.length < 2) return const [];

  final chosen = withExample.toList()..shuffle(rng);
  final selected = chosen.take(min(exerciseCount, chosen.length));

  return [
    for (final g in selected) _buildExercise(g, withExample, rng),
  ];
}

GrammarExercise _buildExercise(
  GrammarPoint g,
  List<GrammarPoint> allCandidates,
  Random rng,
) {
  if (g.practiceBlankIndex != null &&
      g.practiceBlankIndex! >= 0 &&
      g.practiceBlankIndex! < g.practiceTokens.length) {
    return _buildFillBlank(g, allCandidates, rng);
  }
  if (g.practiceTokens.length >= _minWordOrderTiles) {
    return _buildWordOrder(g, rng);
  }
  return _buildMatchSentence(g, allCandidates, rng);
}

GrammarExercise _buildWordOrder(GrammarPoint g, Random rng) {
  final tiles = List<String>.of(g.practiceTokens)..shuffle(rng);
  return GrammarExercise(
    type: GrammarExerciseType.wordOrder,
    source: g,
    tiles: tiles,
  );
}

GrammarExercise _buildFillBlank(
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
      if (other.id != g.id &&
          other.practiceBlankIndex != null &&
          other.practiceBlankIndex! < other.practiceTokens.length)
        other.practiceTokens[other.practiceBlankIndex!],
  }..remove(correctAnswer);

  final distractors = distractorPool.toList()..shuffle(rng);
  final options = <String>[correctAnswer, ...distractors.take(3)]..shuffle(rng);

  return GrammarExercise(
    type: GrammarExerciseType.fillBlank,
    source: g,
    blankPrompt: blankPrompt,
    options: options,
    correctIndex: options.indexOf(correctAnswer),
  );
}

GrammarExercise _buildMatchSentence(
  GrammarPoint g,
  List<GrammarPoint> allCandidates,
  Random rng,
) {
  final correctSentence = g.exampleJp!;
  final distractorPool = <String>{
    for (final other in allCandidates)
      if (other.id != g.id) other.exampleJp!,
  }..remove(correctSentence);

  final distractors = distractorPool.toList()..shuffle(rng);
  final options = <String>[correctSentence, ...distractors.take(3)]..shuffle(rng);

  return GrammarExercise(
    type: GrammarExerciseType.matchSentence,
    source: g,
    options: options,
    correctIndex: options.indexOf(correctSentence),
  );
}
