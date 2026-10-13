/// 1 câu Ngữ pháp trắc nghiệm điền chỗ trống đã soạn sẵn (bảng
/// `grammar_practice_questions`): có đáp án nhiễu, lời giải và nguồn.
class GrammarPracticeQuestion {
  const GrammarPracticeQuestion({
    required this.id,
    required this.levelId,
    required this.promptJp,
    required this.options,
    required this.correctIndex,
    this.lessonId,
    this.explanationVi,
    this.source,
    this.sourceRef,
  });

  final String id;
  final String levelId;
  final String? lessonId;

  /// Câu tiếng Nhật có chỗ trống （　　）.
  final String promptJp;
  final List<String> options;
  final int correctIndex;
  final String? explanationVi;

  /// 'book' (câu nguyên văn từ sách) hoặc 'ai' (câu do AI soạn).
  final String? source;
  final String? sourceRef;

  /// Dữ liệu hợp lệ để hỏi: 2–4 lựa chọn khác nhau, đáp án đúng nằm trong danh sách.
  bool get isValid =>
      promptJp.trim().isNotEmpty &&
      options.length >= 2 &&
      options.length <= 4 &&
      options.toSet().length == options.length &&
      correctIndex >= 0 &&
      correctIndex < options.length;

  static GrammarPracticeQuestion? tryParse(Map<String, dynamic> row) {
    try {
      final options = [for (final o in row['options'] as List) o.toString()];
      final q = GrammarPracticeQuestion(
        id: row['id'] as String,
        levelId: row['level_id'] as String,
        lessonId: row['lesson_id'] as String?,
        promptJp: row['prompt_jp'] as String,
        options: options,
        correctIndex: (row['correct_index'] as num).toInt(),
        explanationVi: row['explanation_vi'] as String?,
        source: row['source'] as String?,
        sourceRef: row['source_ref'] as String?,
      );
      return q.isValid ? q : null;
    } catch (_) {
      // Dòng hỏng thì bỏ qua thay vì làm hỏng cả bài luyện tập.
      return null;
    }
  }
}
