import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/network/ai_exception.dart';
import '../../../core/network/supabase_providers.dart';
import '../../../domain/entities/kanji.dart';
import '../../../domain/entities/vocabulary.dart';

final kanjiTutorServiceProvider = Provider.autoDispose<KanjiTutorService?>((ref) {
  final sb = ref.watch(supabaseProvider);
  final userId = ref.watch(currentUserProvider)?.id;
  if (userId == null) return null;
  return KanjiTutorService(sb);
});

/// Câu trả lời AI + câu hỏi gợi ý tiếp theo.
class KanjiTutorReply {
  const KanjiTutorReply({required this.reply, required this.suggestedQuestions});

  final String reply;
  final List<String> suggestedQuestions;
}

// Chỉ gửi ~10 lượt gần nhất — phiên hỏi-đáp càng dài, gửi nguyên toàn bộ
// lịch sử càng tốn token vô ích trong khi vài lượt trước đã đủ ngữ cảnh.
const _maxHistoryTurns = 10;

/// Gọi Edge Function `ai-kanji-tutor` — hỏi-đáp nhanh về 1 chữ Hán, không
/// lưu lịch sử (khác `KaiwaChatService`, phiên hỏi-đáp mất khi thoát màn).
/// Luôn gửi kèm dữ liệu thật của chữ (on/kun/nghĩa/mẹo nhớ/từ vựng/gia đình
/// kanji) để AI bị ràng buộc không bịa cách đọc khác — xem system prompt
/// trong Edge Function.
class KanjiTutorService {
  KanjiTutorService(this._sb);

  final SupabaseClient _sb;

  Future<KanjiTutorReply> ask({
    required Kanji kanji,
    required List<Vocabulary> relatedVocab,
    required List<Kanji> familyParents,
    required List<Kanji> familyChildren,
    required List<Map<String, String>> history,
    required String message,
  }) async {
    final recentHistory =
        history.length > _maxHistoryTurns ? history.sublist(history.length - _maxHistoryTurns) : history;

    final FunctionResponse res;
    try {
      res = await _sb.functions.invoke(
        'ai-kanji-tutor',
        body: {
          'kanji': {
            'character': kanji.character,
            'hanViet': kanji.hanViet,
            'meaningVi': kanji.meaningVi,
            'onyomi': kanji.onyomi,
            'kunyomi': kanji.kunyomi,
            'mnemonic': kanji.mnemonic,
            'exampleJp': kanji.exampleJp,
            'exampleVi': kanji.exampleVi,
            'relatedVocab': [
              for (final v in relatedVocab) '${v.word}（${v.reading}）',
            ],
            'familyParents': [for (final k in familyParents) k.character],
            'familyChildren': [for (final k in familyChildren) k.character],
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
    return KanjiTutorReply(
      reply: data['reply'] as String? ?? '',
      suggestedQuestions:
          (data['suggestedQuestions'] as List?)?.cast<String>() ?? const [],
    );
  }
}
