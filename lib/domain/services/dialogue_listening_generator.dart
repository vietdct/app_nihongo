import 'dart:math';

import '../entities/listening_dialogue.dart';
import 'quiz_generator.dart';

/// Sinh câu hỏi nghe hiểu từ [ListeningDialogue] thật (hội thoại + câu hỏi
/// đã soạn sẵn) — không sinh nội dung, chỉ chọn ngẫu nhiên 1 tập con mỗi lần
/// vào bài (để độ dài hội thoại ngắn/dài xen kẽ khác nhau mỗi lượt học) và
/// xáo trộn thứ tự 4 lựa chọn có sẵn.
///
/// Tái dùng [QuizQuestion] (qua [QuizQuestion.dialogueTurns]) để không phải
/// xây lại UI/state machine của `QuizScreen`.
///
/// Một quiz theo cấp độ cần ít nhất hai hội thoại để có pool đủ phong phú.
/// Lesson Runner có thể đặt [allowSingle] khi bài đã được gắn đúng một hội
/// thoại chuyên biệt.
class DialogueListeningGenerator {
  const DialogueListeningGenerator({Random? random}) : _random = random;

  final Random? _random;

  List<QuizQuestion> generate({
    required List<ListeningDialogue> dialogues,
    int questionCount = 8,
    bool allowSingle = false,
  }) {
    final valid = dialogues
        .where(
          (d) =>
              d.turns.isNotEmpty &&
              d.options.length >= 2 &&
              d.questionJa.trim().isNotEmpty,
        )
        .toList();
    if (valid.length < (allowSingle ? 1 : 2)) return const [];

    final rng = _random ?? Random();
    final selected = _spreadAcrossDialogues(valid, rng).take(questionCount);

    return [for (final d in selected) _buildQuestion(d, rng)];
  }

  /// Xáo trộn nhưng ưu tiên mỗi hội thoại xuất hiện 1 lần trước khi lặp lại
  /// (nhiều câu hỏi có thể dùng chung 1 hội thoại — ví dụ Tiếng Nhật IT có
  /// 5 câu/bài), để 1 lượt luyện tập không nghe đi nghe lại cùng 1 đoạn.
  List<ListeningDialogue> _spreadAcrossDialogues(
    List<ListeningDialogue> items,
    Random rng,
  ) {
    final groups = <String, List<ListeningDialogue>>{};
    for (final d in items.toList()..shuffle(rng)) {
      final key = [for (final t in d.turns) '${t.speaker}|${t.jp}'].join('\n');
      groups.putIfAbsent(key, () => []).add(d);
    }
    final queues = groups.values.toList()..shuffle(rng);
    final out = <ListeningDialogue>[];
    for (var round = 0; out.length < items.length; round++) {
      for (final q in queues) {
        if (round < q.length) out.add(q[round]);
      }
    }
    return out;
  }

  QuizQuestion _buildQuestion(ListeningDialogue d, Random rng) {
    final correctText = d.options[d.correctIndex];
    final shuffled = d.options.toList()..shuffle(rng);

    return QuizQuestion(
      promptVi: d.questionJa,
      displayJp: [for (final t in d.turns) '${t.speaker}: ${t.jp}'].join('\n'),
      options: shuffled,
      correctIndex: shuffled.indexOf(correctText),
      dialogueTurns: d.turns,
    );
  }
}
