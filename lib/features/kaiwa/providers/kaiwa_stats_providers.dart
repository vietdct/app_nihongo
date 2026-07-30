import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/supabase_providers.dart';
import 'kaiwa_review_providers.dart';

/// Thống kê thật tính từ mọi tin nhắn người dùng đã được AI chấm (không
/// giới hạn theo hạn ôn như `kaiwaReviewQueueProvider`) — [averageRating]
/// null khi chưa có câu nào được chấm (honest-empty, không giả định 0).
class KaiwaMessageStats {
  const KaiwaMessageStats({
    required this.gradedTurnCount,
    required this.averageRating,
    required this.correctedCount,
    required this.reviewedCount,
  });

  final int gradedTurnCount;
  final double? averageRating;
  final int correctedCount;
  final int reviewedCount;
}

final kaiwaMessageStatsProvider =
    FutureProvider.autoDispose<KaiwaMessageStats>((ref) async {
  final sb = ref.watch(supabaseProvider);
  final userId = ref.watch(currentUserProvider)?.id;
  if (userId == null) {
    return const KaiwaMessageStats(
      gradedTurnCount: 0,
      averageRating: null,
      correctedCount: 0,
      reviewedCount: 0,
    );
  }

  final rows = await sb
      .from('kaiwa_messages')
      .select()
      .eq('user_id', userId)
      .eq('role', 'user')
      .not('feedback', 'is', null);

  var graded = 0;
  var ratingSum = 0;
  var corrected = 0;
  var reviewed = 0;
  for (final r in rows) {
    final message = parseKaiwaMessageRow(r);
    final feedback = message.feedback;
    if (feedback == null || !feedback.hasContent) continue;
    graded++;
    ratingSum += feedback.rating;
    if (message.isReviewable) corrected++;
    if (message.reviewCount > 0) reviewed++;
  }

  return KaiwaMessageStats(
    gradedTurnCount: graded,
    averageRating: graded == 0 ? null : ratingSum / graded,
    correctedCount: corrected,
    reviewedCount: reviewed,
  );
});
