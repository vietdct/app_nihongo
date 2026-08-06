import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/network/supabase_providers.dart';

/// Ghi dữ liệu 1 lượt thi thật vào `jlpt_exam_sessions`/`jlpt_exam_answers`
/// — theo đúng pattern `ReviewMistakesController`
/// (`lib/features/review/providers/review_mistakes_providers.dart`): 1 class
/// thuần cầm `SupabaseClient` + `userId`, không dùng StateNotifier cho phần
/// ghi dữ liệu (trạng thái tương tác lúc làm bài — câu hiện tại, flag/bookmark
/// — nằm ở `ExamRunnerScreen` local state, theo đúng kiến trúc `QuizScreen`
/// đã có, không phải kiểu StateNotifierProvider phác thảo ban đầu ở
/// docs/JLPT_MOCK_EXAM_DESIGN.md §7 — đổi cho khớp code thật đang chạy).
class ExamSessionRepository {
  ExamSessionRepository(this._sb, this._userId);

  final SupabaseClient _sb;
  final String _userId;

  Future<String> createSession({
    required String levelId,
    required String mode,
    String? blueprintId,
  }) async {
    final row = await _sb
        .from('jlpt_exam_sessions')
        .insert({
          'user_id': _userId,
          'level_id': levelId,
          'mode': mode,
          if (blueprintId != null) 'blueprint_id': blueprintId,
        })
        .select('id')
        .single();
    return row['id'] as String;
  }

  /// Upsert 1 câu trả lời — gọi mỗi khi người học chọn đáp án, đổi flag/bookmark,
  /// hoặc rời câu (ghi `time_spent_ms`). `is_correct` tính sẵn ở phía gọi
  /// (đã biết `correctIndex` từ [QuizQuestion]) nhưng KHÔNG hiện cho người
  /// dùng lúc đang thi — đúng nguyên tắc JLPT thật, xem
  /// docs/JLPT_MOCK_EXAM_DESIGN.md §6.
  Future<void> saveAnswer({
    required String sessionId,
    required String sectionType,
    required int questionIndex,
    required Map<String, dynamic> questionSnapshot,
    int? selectedIndex,
    bool? isCorrect,
    bool? bookmarked,
    bool? flagged,
    int? timeSpentMs,
  }) async {
    await _sb.from('jlpt_exam_answers').upsert(
      {
        'session_id': sessionId,
        'user_id': _userId,
        'section_type': sectionType,
        'question_index': questionIndex,
        'question_snapshot': questionSnapshot,
        if (selectedIndex != null) 'selected_index': selectedIndex,
        if (isCorrect != null) 'is_correct': isCorrect,
        if (bookmarked != null) 'bookmarked': bookmarked,
        if (flagged != null) 'flagged': flagged,
        if (timeSpentMs != null) 'time_spent_ms': timeSpentMs,
        if (selectedIndex != null)
          'answered_at': DateTime.now().toUtc().toIso8601String(),
      },
      onConflict: 'session_id,section_type,question_index',
    );
  }

  Future<void> submitSession({
    required String sessionId,
    required Map<String, dynamic> score,
  }) async {
    await _sb
        .from('jlpt_exam_sessions')
        .update({
          'status': 'submitted',
          'score': score,
          'submitted_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', sessionId)
        .eq('user_id', _userId);
  }

  Future<void> abandonSession(String sessionId) async {
    await _sb
        .from('jlpt_exam_sessions')
        .update({'status': 'abandoned'})
        .eq('id', sessionId)
        .eq('user_id', _userId);
  }
}

/// null khi chưa đăng nhập — màn gọi provider này cần chặn truy cập Mock
/// Exam trước đó (không nên xảy ra vì toàn app đã yêu cầu đăng nhập từ đầu,
/// nhưng vẫn xử lý null thay vì giả định luôn có user).
final examSessionRepositoryProvider =
    Provider.autoDispose<ExamSessionRepository?>((ref) {
  final sb = ref.watch(supabaseProvider);
  final userId = ref.watch(currentUserProvider)?.id;
  if (userId == null) return null;
  return ExamSessionRepository(sb, userId);
});

/// Kết quả Mini Test gần nhất theo level (docs/JLPT_MINI_TEST_DESIGN.md
/// Task 9) — lấy lượt `mode LIKE 'mini_%'` đã nộp gần nhất, dùng cho ô
/// "Accuracy" ở Hero Card của `MiniTestHomeScreen`. Trả null nếu chưa đăng
/// nhập hoặc chưa làm Mini Test nào ở level này (không phải lỗi).
final lastMiniTestScoreProvider = FutureProvider.autoDispose
    .family<({int correct, int total})?, String>((ref, levelId) async {
  final sb = ref.watch(supabaseProvider);
  final userId = ref.watch(currentUserProvider)?.id;
  if (userId == null) return null;

  final rows = await sb
      .from('jlpt_exam_sessions')
      .select('score')
      .eq('user_id', userId)
      .eq('level_id', levelId)
      .eq('status', 'submitted')
      .like('mode', 'mini_%')
      .order('submitted_at', ascending: false)
      .limit(1);

  if (rows.isEmpty) return null;
  final score = (rows.first['score'] as Map?)?.cast<String, dynamic>();
  if (score == null) return null;

  var correct = 0;
  var total = 0;
  for (final section in score.values) {
    final s = (section as Map).cast<String, dynamic>();
    correct += s['correct'] as int? ?? 0;
    total += s['total'] as int? ?? 0;
  }
  return (correct: correct, total: total);
});

/// Thống kê Mini Test cho 1 biến thể — số lượt, độ chính xác trung bình/tốt
/// nhất (docs/JLPT_MINI_TEST_DESIGN.md §10, Task 10). `avgAccuracy`/
/// `bestAccuracy` trong khoảng 0..1.
class MiniTestVariantStats {
  const MiniTestVariantStats({
    required this.count,
    required this.avgAccuracy,
    required this.bestAccuracy,
  });

  final int count;
  final double avgAccuracy;
  final double bestAccuracy;
}

/// Thống kê Mini Test tổng hợp mọi cấp độ + mọi biến thể (docs §10) — dùng
/// cho lát cắt "Mini Test" trong Review Statistics (Task 10). Streak dùng
/// chung `profiles.streak_count` (đã hiện sẵn ở đầu màn Thống kê ôn tập,
/// KHÔNG lặp lại ở đây).
class MiniTestStats {
  const MiniTestStats({
    required this.totalCount,
    required this.weeklyCount,
    required this.avgAccuracy,
    required this.bestAccuracy,
    required this.byVariant,
  });

  final int totalCount;
  final int weeklyCount;
  final double avgAccuracy;
  final double bestAccuracy;
  final Map<String, MiniTestVariantStats> byVariant;
}

/// Trả null nếu chưa đăng nhập; `totalCount == 0` nếu chưa làm Mini Test
/// nào — cả hai đều KHÔNG phải lỗi, UI cần tự xử lý hiển thị rỗng.
final miniTestStatsProvider = FutureProvider.autoDispose<MiniTestStats?>((ref) async {
  final sb = ref.watch(supabaseProvider);
  final userId = ref.watch(currentUserProvider)?.id;
  if (userId == null) return null;

  final rows = await sb
      .from('jlpt_exam_sessions')
      .select('mode, score, submitted_at')
      .eq('user_id', userId)
      .eq('status', 'submitted')
      .like('mode', 'mini_%')
      .order('submitted_at', ascending: false);

  if (rows.isEmpty) {
    return const MiniTestStats(
      totalCount: 0,
      weeklyCount: 0,
      avgAccuracy: 0,
      bestAccuracy: 0,
      byVariant: {},
    );
  }

  final now = DateTime.now();
  var weeklyCount = 0;
  var sumAccuracy = 0.0;
  var bestAccuracy = 0.0;
  final accuraciesByVariant = <String, List<double>>{};

  for (final row in rows) {
    final mode = row['mode'] as String;
    final variant = mode.startsWith('mini_') ? mode.substring(5) : mode;

    final score = (row['score'] as Map?)?.cast<String, dynamic>();
    var correct = 0;
    var total = 0;
    if (score != null) {
      for (final section in score.values) {
        final s = (section as Map).cast<String, dynamic>();
        correct += s['correct'] as int? ?? 0;
        total += s['total'] as int? ?? 0;
      }
    }
    final accuracy = total == 0 ? 0.0 : correct / total;
    sumAccuracy += accuracy;
    if (accuracy > bestAccuracy) bestAccuracy = accuracy;
    accuraciesByVariant.putIfAbsent(variant, () => []).add(accuracy);

    final submittedAtStr = row['submitted_at'] as String?;
    if (submittedAtStr != null) {
      final submittedAt = DateTime.parse(submittedAtStr);
      if (now.difference(submittedAt).inDays < 7) weeklyCount++;
    }
  }

  return MiniTestStats(
    totalCount: rows.length,
    weeklyCount: weeklyCount,
    avgAccuracy: sumAccuracy / rows.length,
    bestAccuracy: bestAccuracy,
    byVariant: {
      for (final e in accuraciesByVariant.entries)
        e.key: MiniTestVariantStats(
          count: e.value.length,
          avgAccuracy: e.value.reduce((a, b) => a + b) / e.value.length,
          bestAccuracy: e.value.reduce((a, b) => a > b ? a : b),
        ),
    },
  );
});
