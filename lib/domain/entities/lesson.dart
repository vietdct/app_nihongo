import 'grammar_point.dart';
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

/// Bài học mà 1 từ vựng/kanji/ngữ pháp thuộc về, cùng thứ tự dạy trong bài
/// đó — dùng để lọc/sắp theo bài thay vì hiện 1 danh sách phẳng.
class LessonAssignment {
  const LessonAssignment({required this.lessonId, required this.orderIndex});

  final String lessonId;
  final int orderIndex;
}

/// Một mục trong bài học đã được "resolve" — Vocabulary, Kanji, hoặc
/// GrammarPoint. UI chỉ cần switch trên [type] để hiển thị đúng widget.
class LessonContentItem {
  const LessonContentItem.vocabulary(Vocabulary vocab)
      : type = LessonItemType.vocabulary,
        vocabulary = vocab,
        kanji = null,
        grammar = null;

  const LessonContentItem.kanji(Kanji k)
      : type = LessonItemType.kanji,
        kanji = k,
        vocabulary = null,
        grammar = null;

  const LessonContentItem.grammar(GrammarPoint g)
      : type = LessonItemType.grammar,
        grammar = g,
        vocabulary = null,
        kanji = null;

  final LessonItemType type;
  final Vocabulary? vocabulary;
  final Kanji? kanji;
  final GrammarPoint? grammar;
}
