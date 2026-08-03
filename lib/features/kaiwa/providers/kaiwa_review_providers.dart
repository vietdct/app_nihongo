import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/network/supabase_providers.dart';
import '../../../domain/entities/kaiwa_message.dart';
import '../../../domain/services/quiz_generator.dart' show ConversationTurn;
import '../../../domain/services/srs_scheduler.dart';

/// Hàng đợi ôn tập thật — chỉ những câu người học đã nói bị AI sửa
/// ([KaiwaMessage.isReviewable]) và đã tới hạn ôn ([KaiwaMessage.isDueNow]),
/// lấy trực tiếp từ `kaiwa_messages` (không qua từng hội thoại) vì đây là
/// ôn xuyên suốt mọi buổi Kaiwa đã có, không giới hạn 1 buổi cụ thể.
final kaiwaReviewQueueProvider =
    FutureProvider.autoDispose<List<KaiwaMessage>>((ref) async {
  final sb = ref.watch(supabaseProvider);
  final userId = ref.watch(currentUserProvider)?.id;
  if (userId == null) return [];

  final rows = await sb
      .from('kaiwa_messages')
      .select()
      .eq('user_id', userId)
      .eq('role', 'user')
      .not('feedback', 'is', null)
      .order('due_at', ascending: true);

  final messages = [for (final r in rows) parseKaiwaMessageRow(r)];
  return [for (final m in messages) if (m.isReviewable && m.isDueNow) m];
});

/// Toàn bộ tin nhắn Kaiwa THẬT SỰ có sửa lỗi ([KaiwaMessage.isReviewable]),
/// không lọc theo hạn ôn — khác [kaiwaReviewQueueProvider] (hàng đợi SRS
/// riêng cho `KaiwaReviewScreen`). Dùng cho câu hỏi Error Correction ở Quiz
/// tổng hợp (`mixed_quiz_providers.dart`), nơi không có khái niệm "đến hạn".
final kaiwaReviewableMessagesProvider =
    FutureProvider.autoDispose<List<KaiwaMessage>>((ref) async {
  final sb = ref.watch(supabaseProvider);
  final userId = ref.watch(currentUserProvider)?.id;
  if (userId == null) return [];

  final rows = await sb
      .from('kaiwa_messages')
      .select()
      .eq('user_id', userId)
      .eq('role', 'user')
      .not('feedback', 'is', null);

  final messages = [for (final r in rows) parseKaiwaMessageRow(r)];
  return [for (final m in messages) if (m.isReviewable) m];
});

/// Mọi cặp (câu người học thật đã nói → câu AI thật trả lời tiếp theo,
/// trong đúng cùng 1 hội thoại) xuyên suốt toàn bộ Kaiwa History — nguồn cho
/// câu hỏi Hoàn thành hội thoại ở Quiz tổng hợp
/// (`QuizGenerator.generateConversationCompletion`). Sắp theo
/// `conversation_id` rồi `created_at` để gom cặp liền kề cùng hội thoại
/// bằng 1 lượt duyệt tuyến tính, không cần group-by phía SQL. Lượt AI mở
/// đầu hội thoại (chưa có câu người học đứng trước) không tạo cặp — thiếu
/// ngữ cảnh thật để hỏi.
final kaiwaConversationTurnsProvider =
    FutureProvider.autoDispose<List<ConversationTurn>>((ref) async {
  final sb = ref.watch(supabaseProvider);
  final userId = ref.watch(currentUserProvider)?.id;
  if (userId == null) return [];

  final rows = await sb
      .from('kaiwa_messages')
      .select('conversation_id, role, content_jp, created_at')
      .eq('user_id', userId)
      .order('conversation_id', ascending: true)
      .order('created_at', ascending: true);

  final turns = <ConversationTurn>[];
  Map<String, dynamic>? previous;
  for (final r in rows) {
    if (previous != null &&
        previous['conversation_id'] == r['conversation_id'] &&
        previous['role'] == 'user' &&
        r['role'] == 'ai') {
      turns.add(ConversationTurn(
        promptContextJp: previous['content_jp'] as String,
        nextAiReplyJp: r['content_jp'] as String,
      ),);
    }
    previous = r;
  }
  return turns;
});

/// Parse 1 hàng `kaiwa_messages` (kèm cột SRS) thành [KaiwaMessage] — dùng
/// chung cho hàng đợi ôn tập và `kaiwa_stats_providers.dart`.
KaiwaMessage parseKaiwaMessageRow(Map<String, dynamic> r) {
  final feedbackJson = r['feedback'];
  return KaiwaMessage(
    id: r['id'] as String,
    role: KaiwaMessageRole.user,
    contentJp: r['content_jp'] as String,
    feedback: feedbackJson == null
        ? null
        : KaiwaFeedback.fromJson((feedbackJson as Map).cast<String, dynamic>()),
    intervalDays: (r['interval_days'] as num?)?.toDouble() ?? 0,
    easeFactor: (r['ease_factor'] as num?)?.toDouble() ?? 2.5,
    dueAt: DateTime.tryParse(r['due_at'] as String? ?? ''),
    reviewCount: r['review_count'] as int? ?? 0,
  );
}

final kaiwaReviewControllerProvider =
    Provider.autoDispose<KaiwaReviewController?>((ref) {
  final sb = ref.watch(supabaseProvider);
  final userId = ref.watch(currentUserProvider)?.id;
  if (userId == null) return null;
  return KaiwaReviewController(sb, userId);
});

/// Ghi nhận lịch ôn SRS tiếp theo cho 1 tin nhắn — khác
/// `KanjiProgressController`/`GrammarProgressController` (upsert 1 bảng
/// progress riêng): ở đây UPDATE thẳng vào `kaiwa_messages` vì chính tin
/// nhắn đó đã là mục ôn tập, không cần bảng trung gian.
class KaiwaReviewController {
  KaiwaReviewController(this._sb, this._userId);

  final SupabaseClient _sb;
  final String _userId;

  Future<void> recordReview(
    String messageId,
    KaiwaMessage current,
    SrsGrade grade,
  ) async {
    final result = computeNextSchedule(
      previousIntervalDays: current.intervalDays,
      previousEaseFactor: current.easeFactor,
      grade: grade,
    );
    await _sb
        .from('kaiwa_messages')
        .update({
          'interval_days': result.intervalDays,
          'ease_factor': result.easeFactor,
          'due_at': result.dueAt.toUtc().toIso8601String(),
          'review_count': current.reviewCount + 1,
        })
        .eq('id', messageId)
        .eq('user_id', _userId);
  }
}
