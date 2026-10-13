import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/supabase_providers.dart';
import '../../../domain/entities/listening_dialogue.dart';

/// Hội thoại nghe hiểu là nội dung nhỏ, soạn tay, ít đổi — fetch thẳng từ
/// Supabase, không cần cache Drift (giống `jlptLevelsProvider`/nội dung
/// AI Kaiwa): số bài ít, và bài nghe vốn đã random chọn tập con mỗi lần vào
/// (xem `DialogueListeningGenerator`) nên không cần offline-first.
final listeningDialoguesForLevelProvider =
    FutureProvider.family<List<ListeningDialogue>, String>(
        (ref, levelId) async {
  final sb = ref.watch(supabaseProvider);
  final rows =
      await sb.from('listening_dialogues').select().eq('level_id', levelId);
  return _toListeningDialogues(rows);
});

/// Hội thoại gắn trực tiếp với một bài. Các khóa học chuyên đề (như IT) dùng
/// provider này để mỗi bài luôn hiện đúng tình huống đã học, còn N5 hiện có
/// vẫn dùng pool theo cấp độ ở provider phía trên.
final listeningDialoguesForLessonProvider =
    FutureProvider.family<List<ListeningDialogue>, String>(
        (ref, lessonId) async {
  final sb = ref.watch(supabaseProvider);
  final rows =
      await sb.from('listening_dialogues').select().eq('lesson_id', lessonId);
  return _toListeningDialogues(rows);
});

List<ListeningDialogue> _toListeningDialogues(List<dynamic> rows) => [
      for (final raw in rows)
        ListeningDialogue(
          id: raw['id'] as String,
          levelId: raw['level_id'] as String,
          turns: _parseTurns(raw),
          questionJa: raw['question_ja'] as String,
          options: List<String>.from(raw['options'] as List),
          correctIndex: raw['correct_index'] as int,
        ),
    ];

/// Bỏ lượt thoại hỏng thay vì làm crash; dữ liệu cũ chỉ có 1 chuỗi `script`
/// (không có `turns`) → 1 lượt do nhân vật mặc định đọc.
List<ListeningTurn> _parseTurns(Map<String, dynamic> raw) {
  final turns = raw['turns'];
  final items = turns is List
      ? turns
      : (raw['script'] is String ? [raw['script']] : const []);
  return [
    for (final t in items)
      if (ListeningTurn.tryParse(t) case final turn?) turn,
  ];
}
