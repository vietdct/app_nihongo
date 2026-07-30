import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/network/supabase_providers.dart';
import '../../../domain/entities/kaiwa_feedback_context.dart';

final kaiwaTutorServiceProvider = Provider.autoDispose<KaiwaTutorService?>((ref) {
  final sb = ref.watch(supabaseProvider);
  final userId = ref.watch(currentUserProvider)?.id;
  if (userId == null) return null;
  return KaiwaTutorService(sb);
});

/// Câu trả lời AI + câu hỏi gợi ý tiếp theo.
class KaiwaTutorReply {
  const KaiwaTutorReply({required this.reply, required this.suggestedQuestions});

  final String reply;
  final List<String> suggestedQuestions;
}

/// Gọi Edge Function `ai-kaiwa-tutor` — hỏi-đáp sâu thêm về 1 câu người học
/// đã nói + feedback đã chấm, không lưu lịch sử (giống `KanjiTutorService`/
/// `GrammarTutorService`, khác `KaiwaChatService` — đây không phải hội thoại
/// nhập vai, chỉ là hỏi-đáp nhanh về đúng 1 lượt nói).
class KaiwaTutorService {
  KaiwaTutorService(this._sb);

  final SupabaseClient _sb;

  Future<KaiwaTutorReply> ask({
    required KaiwaFeedbackContext turn,
    required List<Map<String, String>> history,
    required String message,
  }) async {
    final res = await _sb.functions.invoke(
      'ai-kaiwa-tutor',
      body: {
        'turn': {
          'originalSentence': turn.originalSentence,
          'betterPhrasing': turn.betterPhrasing,
          'explanation': turn.explanation,
          'commonMistake': turn.commonMistake,
          'grammarNote': turn.grammarNote,
          'vocabularyNote': turn.vocabularyNote,
          'politenessNote': turn.politenessNote,
          'personaName': turn.personaName,
          'scenarioTitle': turn.scenarioTitle,
        },
        'history': history,
        'message': message,
      },
    ).timeout(
      const Duration(seconds: 30),
      onTimeout: () => throw Exception('AI phản hồi quá lâu, vui lòng thử lại.'),
    );

    final data = res.data;
    if (res.status != 200 || data is! Map) {
      final err = data is Map ? data['error'] as String? : null;
      throw Exception(err ?? 'Lỗi gọi AI, vui lòng thử lại.');
    }
    return KaiwaTutorReply(
      reply: data['reply'] as String? ?? '',
      suggestedQuestions: (data['suggestedQuestions'] as List?)?.cast<String>() ?? const [],
    );
  }
}
