import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/supabase_providers.dart';

/// Tóm tắt 1 lượt làm bài Thi thử JLPT đã nộp — dùng cho "Lịch sử" ở Hồ sơ.
class ExamSessionSummary {
  const ExamSessionSummary({
    required this.id,
    required this.mode,
    required this.levelCode,
    required this.submittedAt,
    required this.score,
  });

  final String id;
  final String mode;
  final String levelCode;
  final DateTime submittedAt;

  /// {"vocabulary_grammar":{"correct":28,"total":35}, "reading":{...}, ...}
  final Map<String, dynamic>? score;

  /// Tổng đúng/tổng câu cộng dồn mọi phần thi — null nếu chưa có điểm.
  (int correct, int total)? get totalScore {
    if (score == null) return null;
    var correct = 0;
    var total = 0;
    for (final section in score!.values) {
      if (section is Map) {
        correct += (section['correct'] as num?)?.toInt() ?? 0;
        total += (section['total'] as num?)?.toInt() ?? 0;
      }
    }
    return total == 0 ? null : (correct, total);
  }
}

const examModeLabels = {
  'full_exam': 'Thi thử đầy đủ',
  'mini_test': 'Mini Test',
  'section_practice': 'Luyện theo phần',
  'custom_test': 'Đề tuỳ chỉnh',
  'weak_point_test': 'Ôn điểm yếu',
  'ai_mock_exam': 'AI Mock Exam',
  // 4 biến thể Mini Test — mode do MiniTestBlueprint.sessionMode sinh ra
  // (docs/JLPT_MINI_TEST_DESIGN.md), khác 6 giá trị mode gốc ở trên.
  'mini_quick5': 'Mini Test · Quick 5',
  'mini_daily': 'Mini Test · Hằng ngày',
  'mini_weakPoint': 'Mini Test · Điểm yếu',
  'mini_ai': 'Mini Test · AI',
};

/// 20 lượt thi thử JLPT đã nộp gần nhất của user hiện tại, mới nhất trước.
final examSessionHistoryProvider =
    FutureProvider.autoDispose<List<ExamSessionSummary>>((ref) async {
  final sb = ref.watch(supabaseProvider);
  final userId = ref.watch(currentUserProvider)?.id;
  if (userId == null) return [];

  final rows = await sb
      .from('jlpt_exam_sessions')
      .select('id, mode, submitted_at, score, jlpt_levels(code)')
      .eq('user_id', userId)
      .eq('status', 'submitted')
      .order('submitted_at', ascending: false)
      .limit(20);

  return [
    for (final r in rows)
      ExamSessionSummary(
        id: r['id'] as String,
        mode: r['mode'] as String,
        levelCode: (r['jlpt_levels'] as Map?)?['code'] as String? ?? '',
        submittedAt: DateTime.parse(r['submitted_at'] as String),
        score: (r['score'] as Map?)?.cast<String, dynamic>(),
      ),
  ];
});
