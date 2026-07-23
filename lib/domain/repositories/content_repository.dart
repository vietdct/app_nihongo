import '../entities/kanji.dart';
import '../entities/lesson.dart';
import '../entities/vocabulary.dart';

abstract interface class ContentRepository {
  Stream<List<Lesson>> watchLessons(String levelId);
  Stream<List<LessonContentItem>> watchLessonItems(String lessonId);
  Stream<List<Vocabulary>> watchAllVocabulary();
  Stream<List<Kanji>> watchAllKanji();

  /// Kéo dữ liệu mới nhất từ Supabase về Drift. Gọi khi có mạng;
  /// UI không cần đợi việc này — nó chỉ làm mới cache nền.
  Future<void> refreshFromRemote(String levelId);
}
