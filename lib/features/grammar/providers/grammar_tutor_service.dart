import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/network/ai_exception.dart';
import '../../../core/network/supabase_providers.dart';
import '../../../domain/entities/grammar_point.dart';

final grammarTutorServiceProvider = Provider.autoDispose<GrammarTutorService?>((ref) {
  final sb = ref.watch(supabaseProvider);
  final userId = ref.watch(currentUserProvider)?.id;
  if (userId == null) return null;
  return GrammarTutorService(sb);
});

/// Câu trả lời AI + câu hỏi gợi ý tiếp theo.
class GrammarTutorReply {
  const GrammarTutorReply({required this.reply, required this.suggestedQuestions});

  final String reply;
  final List<String> suggestedQuestions;
}

// Chỉ gửi ~10 lượt gần nhất — phiên hỏi-đáp càng dài, gửi nguyên toàn bộ
// lịch sử càng tốn token vô ích trong khi vài lượt trước đã đủ ngữ cảnh.
const _maxHistoryTurns = 10;

/// Gọi Edge Function `ai-grammar-tutor` — hỏi-đáp nhanh về 1 mẫu ngữ pháp,
/// không lưu lịch sử (khác `KaiwaChatService`, phiên hỏi-đáp mất khi thoát
/// màn — đúng pattern `KanjiTutorService`). Luôn gửi kèm dữ liệu thật của
/// mẫu ngữ pháp (giải thích/ví dụ/lỗi thường gặp/mẹo nhớ/so sánh) để AI bị
/// ràng buộc không bịa công thức khác — xem system prompt trong Edge Function.
class GrammarTutorService {
  GrammarTutorService(this._sb);

  final SupabaseClient _sb;

  Future<GrammarTutorReply> ask({
    required GrammarPoint grammar,
    required List<GrammarPoint> comparedWith,
    required List<Map<String, String>> history,
    required String message,
  }) async {
    final recentHistory =
        history.length > _maxHistoryTurns ? history.sublist(history.length - _maxHistoryTurns) : history;

    final FunctionResponse res;
    try {
      res = await _sb.functions.invoke(
        'ai-grammar-tutor',
        body: {
          'grammar': {
            'title': grammar.title,
            'explanation': grammar.explanation,
            'exampleJp': grammar.exampleJp,
            'exampleVi': grammar.exampleVi,
            'commonMistake': grammar.commonMistake,
            'memoryTip': grammar.memoryTip,
            'comparisonNote': grammar.comparisonNote,
            'comparedWith': [for (final g in comparedWith) g.title],
          },
          'history': recentHistory,
          'message': message,
        },
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () => throw Exception('AI phản hồi quá lâu, vui lòng thử lại.'),
      );
    } on FunctionException catch (e) {
      throw mapAiFunctionException(e);
    }

    final data = res.data;
    if (data is! Map) {
      throw const AiException('Lỗi gọi AI, vui lòng thử lại.', code: 'UNKNOWN');
    }
    return GrammarTutorReply(
      reply: data['reply'] as String? ?? '',
      suggestedQuestions:
          (data['suggestedQuestions'] as List?)?.cast<String>() ?? const [],
    );
  }
}
