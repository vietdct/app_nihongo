import 'kanji.dart';
import 'vocabulary.dart';

class Lesson {
  const Lesson({
    required this.id,
    required this.title,
    required this.levelId,
    required this.orderIndex,
    this.description,
  });

  final String id;
  final String title;
  final String levelId;
  final int orderIndex;
  final String? description;
}

/// item_type cho lesson_items — polymorphic (xem lý do ở migration Pha 1/2:
/// đánh đổi ràng buộc FK cứng lấy ít bảng lặp lại cho một người maintain).
enum LessonItemType { vocabulary, kanji, grammar }

/// Một mục trong bài học đã được "resolve" — hoặc là Vocabulary hoặc Kanji.
/// UI chỉ cần switch trên [type] để hiển thị đúng widget.
class LessonContentItem {
  const LessonContentItem.vocabulary(Vocabulary vocab)
      : type = LessonItemType.vocabulary,
        vocabulary = vocab,
        kanji = null;

  const LessonContentItem.kanji(Kanji k)
      : type = LessonItemType.kanji,
        kanji = k,
        vocabulary = null;

  final LessonItemType type;
  final Vocabulary? vocabulary;
  final Kanji? kanji;
}
