import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/supabase_providers.dart';
import '../../../domain/entities/grammar_practice_question.dart';

/// Câu hỏi Ngữ pháp đã soạn sẵn theo bài (id cách nhau bằng dấu phẩy). Giống
/// `listening_dialogues`: nội dung nhỏ, soạn tay → fetch thẳng từ Supabase,
/// không mirror Drift. Lỗi mạng/bảng chưa tồn tại → danh sách rỗng để bài
/// luyện tập vẫn chạy bằng các dạng câu hỏi khác.
final grammarPracticeForLessonsProvider = FutureProvider.autoDispose
    .family<List<GrammarPracticeQuestion>, String>((ref, lessonIds) async {
  final sb = ref.watch(supabaseProvider);
  try {
    final rows = await sb
        .from('grammar_practice_questions')
        .select()
        .inFilter('lesson_id', lessonIds.split(','));
    return _parse(rows);
  } catch (_) {
    return const [];
  }
});

/// Toàn bộ câu hỏi của 1 cấp độ.
final grammarPracticeForLevelProvider = FutureProvider.autoDispose
    .family<List<GrammarPracticeQuestion>, String>((ref, levelId) async {
  final sb = ref.watch(supabaseProvider);
  try {
    final rows = await sb
        .from('grammar_practice_questions')
        .select()
        .eq('level_id', levelId);
    return _parse(rows);
  } catch (_) {
    return const [];
  }
});

List<GrammarPracticeQuestion> _parse(List<dynamic> rows) => [
      for (final r in rows)
        if (GrammarPracticeQuestion.tryParse(Map<String, dynamic>.from(r as Map))
            case final q?)
          q,
    ];
