import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/network/supabase_providers.dart';
import '../../../domain/entities/kanji_progress.dart';
import '../../../domain/services/srs_scheduler.dart';

/// Toàn bộ tiến độ (thuộc/chưa thuộc + đã lưu + SRS) của người dùng hiện
/// tại, theo kanji_id. Ghi trực tiếp qua Supabase (không qua Drift) vì đây
/// là dữ liệu riêng tư theo người dùng, không phải nội dung học liệu dùng chung.
final kanjiProgressProvider = FutureProvider.autoDispose<Map<String, KanjiProgress>>((ref) async {
  final sb = ref.watch(supabaseProvider);
  final userId = ref.watch(currentUserProvider)?.id;
  if (userId == null) return {};

  final rows = await sb.from('user_kanji_progress').select().eq('user_id', userId);
  return {
    for (final r in rows)
      r['kanji_id'] as String: KanjiProgress(
        kanjiId: r['kanji_id'] as String,
        isKnown: r['status'] == null ? null : r['status'] == 'known',
        starred: r['starred'] as bool? ?? false,
        updatedAt: DateTime.tryParse(r['updated_at'] as String? ?? ''),
        intervalDays: (r['interval_days'] as num?)?.toDouble() ?? 0,
        easeFactor: (r['ease_factor'] as num?)?.toDouble() ?? 2.5,
        dueAt: DateTime.tryParse(r['due_at'] as String? ?? ''),
        reviewCount: r['review_count'] as int? ?? 0,
      ),
  };
});

final kanjiProgressControllerProvider = Provider.autoDispose<KanjiProgressController?>((ref) {
  final sb = ref.watch(supabaseProvider);
  final userId = ref.watch(currentUserProvider)?.id;
  if (userId == null) return null;
  return KanjiProgressController(sb, userId);
});

/// Ghi nhận trạng thái thuộc/chưa thuộc, đánh dấu sao, và lịch ôn SRS. Upsert
/// theo (user_id, kanji_id) — chỉ cột được truyền vào mới bị ghi đè, các cột
/// khác giữ nguyên giá trị cũ.
class KanjiProgressController {
  KanjiProgressController(this._sb, this._userId);

  final SupabaseClient _sb;
  final String _userId;

  // Postgrest builders là lazy — request chỉ thực sự gửi khi được await.
  // Await ngay trong này để caller có thể fire-and-forget an toàn.
  Future<void> setKnown(String kanjiId, bool isKnown) async {
    await _sb.from('user_kanji_progress').upsert(
      {'user_id': _userId, 'kanji_id': kanjiId, 'status': isKnown ? 'known' : 'unknown'},
      onConflict: 'user_id,kanji_id',
    );
  }

  Future<void> setStarred(String kanjiId, bool starred) async {
    await _sb.from('user_kanji_progress').upsert(
      {'user_id': _userId, 'kanji_id': kanjiId, 'starred': starred},
      onConflict: 'user_id,kanji_id',
    );
  }

  /// Tính lịch ôn tiếp theo (xem `computeNextSchedule`) từ [current] (null
  /// nếu chưa từng ôn) và ghi lại — dùng ở `KanjiReviewScreen`.
  Future<void> recordReview(
    String kanjiId,
    KanjiProgress? current,
    SrsGrade grade,
  ) async {
    final result = computeNextSchedule(
      previousIntervalDays: current?.intervalDays,
      previousEaseFactor: current?.easeFactor,
      grade: grade,
    );
    await _sb.from('user_kanji_progress').upsert(
      {
        'user_id': _userId,
        'kanji_id': kanjiId,
        'interval_days': result.intervalDays,
        'ease_factor': result.easeFactor,
        'due_at': result.dueAt.toUtc().toIso8601String(),
        'review_count': (current?.reviewCount ?? 0) + 1,
      },
      onConflict: 'user_id,kanji_id',
    );
  }
}
