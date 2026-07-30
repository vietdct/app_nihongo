import '../entities/lesson.dart';

/// Độ khó hiển thị ở Lesson Intro — suy ra từ số lượng nội dung mới trong
/// bài, không phải đánh giá chủ quan soạn tay cho từng bài.
enum LessonPaceDifficulty { easy, medium, hard }

/// Mục tiêu bài học luôn suy ra từ chính [items] đã gán cho bài — không soạn
/// văn bản riêng cho từng bài nên không thể lệch với thứ người học thực sự
/// sẽ học (honest, cùng triết lý với QuizGenerator/GrammarPracticeGenerator).
List<String> deriveLessonObjectives(List<LessonContentItem> items) {
  final vocabCount = items.where((i) => i.type == LessonItemType.vocabulary).length;
  final kanjiCount = items.where((i) => i.type == LessonItemType.kanji).length;
  final grammarTitles = items
      .where((i) => i.type == LessonItemType.grammar)
      .map((i) => i.grammar!.title)
      .toList();

  return [
    if (grammarTitles.isNotEmpty) 'Sử dụng đúng: ${grammarTitles.join(", ")}',
    if (vocabCount > 0) 'Học $vocabCount từ vựng mới',
    if (kanjiCount > 0) 'Nhận biết $kanjiCount chữ Kanji',
  ];
}

/// Ước lượng thời gian học dựa trên số lượng item thật của bài (không phải
/// hằng số cố định cho mọi bài) — vocab/kanji/grammar tốn thời gian tiếp thu
/// khác nhau nên có trọng số riêng.
int estimateLessonMinutes(List<LessonContentItem> items) {
  const perVocabMinutes = 1.0;
  const perKanjiMinutes = 1.5;
  const perGrammarMinutes = 2.0;
  const overheadMinutes = 3.0; // Intro + Objectives + chuyển màn giữa các bước

  var minutes = overheadMinutes;
  for (final item in items) {
    minutes += switch (item.type) {
      LessonItemType.vocabulary => perVocabMinutes,
      LessonItemType.kanji => perKanjiMinutes,
      LessonItemType.grammar => perGrammarMinutes,
    };
  }
  return minutes.ceil();
}

/// Số lượng nội dung mới càng nhiều thì càng cần nhiều thời gian/nỗ lực —
/// dùng ngưỡng đơn giản thay vì gán độ khó tay cho từng bài.
LessonPaceDifficulty deriveLessonDifficulty(List<LessonContentItem> items) {
  if (items.length <= 6) return LessonPaceDifficulty.easy;
  if (items.length <= 14) return LessonPaceDifficulty.medium;
  return LessonPaceDifficulty.hard;
}
