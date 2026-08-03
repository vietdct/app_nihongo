import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/network/supabase_providers.dart';
import '../../../domain/entities/review_mistake.dart';

/// Toàn bộ lỗi đã ghi nhận của người dùng hiện tại, mới nhất trước — nguồn
/// cho Mistake Notebook (`/review/mistakes`).
final reviewMistakesProvider =
    FutureProvider.autoDispose<List<ReviewMistake>>((ref) async {
  final sb = ref.watch(supabaseProvider);
  final userId = ref.watch(currentUserProvider)?.id;
  if (userId == null) return [];

  final rows = await sb
      .from('review_mistakes')
      .select()
      .eq('user_id', userId)
      .order('updated_at', ascending: false);

  return [
    for (final r in rows)
      ReviewMistake(
        id: r['id'] as String,
        sourceType: r['source_type'] as String,
        sourceId: r['source_id'] as String,
        originalAnswer: r['original_answer'] as String?,
        correctAnswer: r['correct_answer'] as String,
        explanation: r['explanation'] as String?,
        note: r['note'] as String?,
        bookmarked: r['bookmarked'] as bool? ?? false,
        occurrenceCount: r['occurrence_count'] as int? ?? 1,
        updatedAt: DateTime.parse(r['updated_at'] as String),
      ),
  ];
});

final reviewMistakesControllerProvider =
    Provider.autoDispose<ReviewMistakesController?>((ref) {
  final sb = ref.watch(supabaseProvider);
  final userId = ref.watch(currentUserProvider)?.id;
  if (userId == null) return null;
  return ReviewMistakesController(sb, userId);
});

/// Ghi lại lỗi khi người học tự chấm "Quên" ở màn Review (Từ vựng/Kanji/Ngữ
/// pháp) — nguồn dữ liệu thật cho Mistake Notebook (`docs/REVIEW_DESIGN.md`
/// §3). Upsert theo (user_id, source_type, source_id), tăng
/// `occurrence_count` thay vì tạo dòng mới mỗi lần sai lại — đọc số hiện tại
/// trước để cộng dồn đúng (bảng `review_mistakes` không tự tăng qua upsert).
class ReviewMistakesController {
  ReviewMistakesController(this._sb, this._userId);

  final SupabaseClient _sb;
  final String _userId;

  Future<void> recordMistake({
    required String sourceType,
    required String sourceId,
    required String correctAnswer,
    String? originalAnswer,
    String? explanation,
  }) async {
    final existing = await _sb
        .from('review_mistakes')
        .select('occurrence_count')
        .eq('user_id', _userId)
        .eq('source_type', sourceType)
        .eq('source_id', sourceId)
        .maybeSingle();

    await _sb.from('review_mistakes').upsert(
      {
        'user_id': _userId,
        'source_type': sourceType,
        'source_id': sourceId,
        'correct_answer': correctAnswer,
        if (originalAnswer != null) 'original_answer': originalAnswer,
        if (explanation != null) 'explanation': explanation,
        'occurrence_count': (existing?['occurrence_count'] as int? ?? 0) + 1,
      },
      onConflict: 'user_id,source_type,source_id',
    );
  }

  Future<void> setBookmarked(String mistakeId, bool bookmarked) async {
    await _sb
        .from('review_mistakes')
        .update({'bookmarked': bookmarked})
        .eq('id', mistakeId)
        .eq('user_id', _userId);
  }

  Future<void> setNote(String mistakeId, String note) async {
    await _sb
        .from('review_mistakes')
        .update({'note': note})
        .eq('id', mistakeId)
        .eq('user_id', _userId);
  }
}
