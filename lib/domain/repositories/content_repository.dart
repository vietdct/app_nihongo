import '../entities/grammar_point.dart';
import '../entities/kanji.dart';
import '../entities/lesson.dart';
import '../entities/vocabulary.dart';

abstract interface class ContentRepository {
  Stream<List<Lesson>> watchLessons(String levelId);
  Stream<List<LessonContentItem>> watchLessonItems(String lessonId);
  Stream<List<Vocabulary>> watchVocabulary(String levelId);
  Stream<List<Kanji>> watchKanji(String levelId);
  Stream<List<GrammarPoint>> watchGrammar(String levelId);

  /// Bài học của mỗi từ vựng/kanji/ngữ pháp trong cấp độ — dùng để lọc theo
  /// bài thay vì hiện 1 danh sách phẳng gộp hết.
  Stream<Map<String, LessonAssignment>> watchVocabularyLessonAssignments(String levelId);
  Stream<Map<String, LessonAssignment>> watchKanjiLessonAssignments(String levelId);
  Stream<Map<String, LessonAssignment>> watchGrammarLessonAssignments(String levelId);

  /// Kéo dữ liệu mới nhất từ Supabase về Drift. Gọi khi có mạng;
  /// UI không cần đợi việc này — nó chỉ làm mới cache nền.
  Future<void> refreshFromRemote(String levelId);
}
