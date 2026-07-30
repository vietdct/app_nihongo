import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/supabase_providers.dart';
import '../../../domain/entities/listening_dialogue.dart';

/// Hội thoại nghe hiểu là nội dung nhỏ, soạn tay, ít đổi — fetch thẳng từ
/// Supabase, không cần cache Drift (giống `jlptLevelsProvider`/nội dung
/// AI Kaiwa): số bài ít, và bài nghe vốn đã random chọn tập con mỗi lần vào
/// (xem `DialogueListeningGenerator`) nên không cần offline-first.
final listeningDialoguesForLevelProvider =
    FutureProvider.family<List<ListeningDialogue>, String>((ref, levelId) async {
  final sb = ref.watch(supabaseProvider);
  final rows =
      await sb.from('listening_dialogues').select().eq('level_id', levelId);
  return [
    for (final r in rows)
      ListeningDialogue(
        id: r['id'] as String,
        levelId: r['level_id'] as String,
        turns: [
          for (final t in r['turns'] as List)
            ListeningTurn(
                speaker: t['speaker'] as String, jp: t['jp'] as String,),
        ],
        questionJa: r['question_ja'] as String,
        options: List<String>.from(r['options'] as List),
        correctIndex: r['correct_index'] as int,
      ),
  ];
});
