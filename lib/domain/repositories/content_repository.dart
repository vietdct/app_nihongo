import '../entities/grammar_point.dart';
import '../entities/kanji.dart';
import '../entities/lesson.dart';
import '../entities/vocabulary.dart';

abstract interface class ContentRepository {
  Stream<List<Lesson>> watchLessons(String levelId);
  Stream<List<LessonContentItem>> watchLessonItems(String lessonId);

  /// Khi [coreN5Only] là true, chỉ trả 254 từ N5 cốt lõi đã được biên soạn
  /// trong `seed_content_n5.sql`; không lấy các mục gắn nhãn N5 ngoài bộ này.
  Stream<List<Vocabulary>> watchVocabulary(
    String levelId, {
    bool coreN5Only = false,
  });
  Stream<List<Kanji>> watchKanji(String levelId);
  Stream<List<GrammarPoint>> watchGrammar(String levelId);

  /// Tra 1 chữ Kanji theo mọi cấp độ đã cache — dùng cho breakdown Kanji và
  /// ghép âm Hán Việt của Vocabulary Detail Sheet. Null nếu chưa cache được.
  Future<Kanji?> findKanjiByCharacter(String character);

  /// Từ vựng khác chứa cùng Kanji với [word] (mọi cấp độ đã cache) — nguồn
  /// dữ liệu thật cho section "Từ liên quan" (không có synonym/antonym vì
  /// app chưa có dữ liệu đó).
  Future<List<Vocabulary>> findRelatedVocabulary(
    String word, {
    required String excludeId,
    int limit = 8,
  });

  /// Bài học của mỗi từ vựng/kanji/ngữ pháp trong cấp độ — dùng để lọc theo
  /// bài thay vì hiện 1 danh sách phẳng gộp hết.
  Stream<Map<String, LessonAssignment>> watchVocabularyLessonAssignments(
    String levelId,
  );
  Stream<Map<String, LessonAssignment>> watchKanjiLessonAssignments(
    String levelId,
  );
  Stream<Map<String, LessonAssignment>> watchGrammarLessonAssignments(
    String levelId,
  );

  /// Kéo dữ liệu mới nhất từ Supabase về Drift. Gọi khi có mạng;
  /// UI không cần đợi việc này — nó chỉ làm mới cache nền.
  Future<void> refreshFromRemote(
    String levelId, {
    bool coreN5Only = false,
  });
}
