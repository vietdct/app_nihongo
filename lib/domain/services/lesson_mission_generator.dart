import '../entities/grammar_point.dart';
import '../entities/lesson.dart';
import '../entities/vocabulary.dart';

const _maxTargetVocab = 3;
const _maxTargetGrammar = 2;

/// Mục tiêu của pha Apply (Mission Challenge) — từ vựng/ngữ pháp THẬT của
/// chính bài học mà người học phải chủ động dùng trong hội thoại AI, thay vì
/// chỉ được chấm điểm chung chung như Kaiwa tự do. Xem `LessonMissionView`.
class LessonMission {
  const LessonMission({
    required this.lessonTitle,
    required this.targetVocab,
    required this.targetGrammar,
  });

  final String lessonTitle;
  final List<Vocabulary> targetVocab;
  final List<GrammarPoint> targetGrammar;

  int get totalTargets => targetVocab.length + targetGrammar.length;
}

/// honest-empty: bài không có đủ ít nhất 1 từ vựng VÀ 1 ngữ pháp thì không
/// tạo mission — không có gì để đặt mục tiêu, không bịa target giả.
LessonMission? generateLessonMission({
  required Lesson lesson,
  required List<LessonContentItem> items,
}) {
  final vocab = [
    for (final item in items)
      if (item.type == LessonItemType.vocabulary) item.vocabulary!,
  ];
  final grammar = [
    for (final item in items)
      if (item.type == LessonItemType.grammar) item.grammar!,
  ];
  if (vocab.isEmpty || grammar.isEmpty) return null;

  return LessonMission(
    lessonTitle: lesson.title,
    targetVocab: vocab.take(_maxTargetVocab).toList(),
    targetGrammar: grammar.take(_maxTargetGrammar).toList(),
  );
}
