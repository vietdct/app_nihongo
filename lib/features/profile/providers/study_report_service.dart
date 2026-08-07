import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/network/ai_exception.dart';
import '../../../core/network/supabase_providers.dart';
import '../../../domain/entities/review_mistake.dart';
import 'ai_insights_providers.dart';

final studyReportServiceProvider =
    Provider.autoDispose<StudyReportService?>((ref) {
  final sb = ref.watch(supabaseProvider);
  final userId = ref.watch(currentUserProvider)?.id;
  if (userId == null) return null;
  return StudyReportService(sb);
});

/// Gọi Edge Function `ai-study-report` — sinh 1 bản tóm tắt hiện trạng học
/// tập bằng văn xuôi, dựa 100% trên số liệu thật ([StudyReportStats] + tối
/// đa 5 lỗi lặp lại nhiều nhất). Không lưu lịch sử, mỗi lần gọi là 1 report
/// mới (bị giới hạn quota 'study_report': 2/phút, 5/ngày).
class StudyReportService {
  StudyReportService(this._sb);

  final SupabaseClient _sb;

  Future<String> generate({
    required StudyReportStats stats,
    required List<ReviewMistake> topMistakes,
  }) async {
    final FunctionResponse res;
    try {
      res = await _sb.functions.invoke(
        'ai-study-report',
        body: {
          'streakCount': stats.streakCount,
          'longestStreakCount': stats.longestStreakCount,
          'xp': stats.xp,
          'knownVocab': stats.knownVocab,
          'knownKanji': stats.knownKanji,
          'knownGrammar': stats.knownGrammar,
          'weakVocab': stats.weak.vocab,
          'weakKanji': stats.weak.kanji,
          'weakGrammar': stats.weak.grammar,
          'mistakes': [
            for (final m in topMistakes)
              {
                'sourceType': m.sourceType,
                'correctAnswer': m.correctAnswer,
                'explanation': m.explanation,
                'occurrenceCount': m.occurrenceCount,
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
    if (data is! Map || data['report'] is! String) {
      throw const AiException('Lỗi gọi AI, vui lòng thử lại.', code: 'UNKNOWN');
    }
    return data['report'] as String;
  }
}
