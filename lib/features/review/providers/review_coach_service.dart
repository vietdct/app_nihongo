import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/network/ai_exception.dart';
import '../../../core/network/supabase_providers.dart';
import '../../../domain/entities/review_mistake.dart';

final reviewCoachServiceProvider = Provider.autoDispose<ReviewCoachService?>((ref) {
  final sb = ref.watch(supabaseProvider);
  final userId = ref.watch(currentUserProvider)?.id;
  if (userId == null) return null;
  return ReviewCoachService(sb);
});

/// 5 câu hỏi mẫu cố định của AI Review Coach — MVP theo
/// `docs/REVIEW_DESIGN.md` §12/§16, chưa hỗ trợ chat tự do để tránh AI trả
/// lời lan man ngoài phạm vi lỗi thật của người học.
enum ReviewCoachQuestion {
  whyWrong,
  explainAgain,
  exampleVariants,
  quizFromMistakes,
  reviewYesterday,
}

extension ReviewCoachQuestionX on ReviewCoachQuestion {
  String get label => switch (this) {
        ReviewCoachQuestion.whyWrong => 'Vì sao tôi hay sai?',
        ReviewCoachQuestion.explainAgain => 'Giải thích lại',
        ReviewCoachQuestion.exampleVariants => 'Cho ví dụ dễ hơn/khó hơn',
        ReviewCoachQuestion.quizFromMistakes => 'Tạo quiz từ lỗi của tôi',
        ReviewCoachQuestion.reviewYesterday => 'Ôn lại bài hôm qua',
      };

  String get _key => switch (this) {
        ReviewCoachQuestion.whyWrong => 'why_wrong',
        ReviewCoachQuestion.explainAgain => 'explain_again',
        ReviewCoachQuestion.exampleVariants => 'example_variants',
        ReviewCoachQuestion.quizFromMistakes => 'quiz_from_mistakes',
        ReviewCoachQuestion.reviewYesterday => 'review_yesterday',
      };
}

// Chỉ gửi tối đa 15 lỗi gần nhất — không gửi toàn bộ Mistake Notebook, giữ
// đúng nguyên tắc giới hạn context đã áp dụng ở AI Kaiwa.
const _maxMistakesSent = 15;

/// Gọi Edge Function `ai-review-coach` — tái dùng hạ tầng AI Kaiwa (Gemini +
/// Anthropic fallback, quota/token tracking qua `ai_guard.ts`), khác ở chỗ
/// input là 1 trong 5 câu hỏi mẫu cố định + danh sách lỗi thật, không phải
/// hội thoại nhập vai.
class ReviewCoachService {
  ReviewCoachService(this._sb);

  final SupabaseClient _sb;

  Future<String> ask(
    ReviewCoachQuestion question,
    List<ReviewMistake> mistakes,
  ) async {
    final recent = mistakes.length > _maxMistakesSent
        ? mistakes.sublist(0, _maxMistakesSent)
        : mistakes;

    final FunctionResponse res;
    try {
      res = await _sb.functions.invoke(
        'ai-review-coach',
        body: {
          'questionKey': question._key,
          'mistakes': [
            for (final m in recent)
              {
                'sourceType': m.sourceType,
                'correctAnswer': m.correctAnswer,
                'explanation': m.explanation,
                'occurrenceCount': m.occurrenceCount,
                'updatedAt': m.updatedAt.toIso8601String(),
              },
          ],
        },
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () => throw Exception('AI phản hồi quá lâu, vui lòng thử lại.'),
      );
    } on FunctionException catch (e) {
      throw mapAiFunctionException(e);
    }

    final data = res.data;
    if (data is! Map || data['reply'] is! String) {
      throw const AiException('Lỗi gọi AI, vui lòng thử lại.', code: 'UNKNOWN');
    }
    return data['reply'] as String;
  }
}
