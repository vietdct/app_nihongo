import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/network/supabase_providers.dart';
import '../../../domain/entities/vocab_progress.dart';

/// Toàn bộ tiến độ (thuộc/chưa thuộc + đã lưu) của người dùng hiện tại,
/// theo vocab_id. Ghi trực tiếp qua Supabase (không qua Drift) vì đây là
/// dữ liệu riêng tư theo người dùng, không phải nội dung học liệu dùng chung.
final vocabProgressProvider = FutureProvider.autoDispose<Map<String, VocabProgress>>((ref) async {
  final sb = ref.watch(supabaseProvider);
  final userId = ref.watch(currentUserProvider)?.id;
  if (userId == null) return {};

  final rows = await sb.from('user_vocab_progress').select().eq('user_id', userId);
  return {
    for (final r in rows)
      r['vocab_id'] as String: VocabProgress(
        vocabId: r['vocab_id'] as String,
        isKnown: r['status'] == null ? null : r['status'] == 'known',
        starred: r['starred'] as bool? ?? false,
      ),
  };
});

final vocabProgressControllerProvider = Provider.autoDispose<VocabProgressController?>((ref) {
  final sb = ref.watch(supabaseProvider);
  final userId = ref.watch(currentUserProvider)?.id;
  if (userId == null) return null;
  return VocabProgressController(sb, userId);
});

/// Ghi nhận trạng thái thuộc/chưa thuộc và đánh dấu sao. Upsert theo
/// (user_id, vocab_id) — chỉ cột được truyền vào mới bị ghi đè, các cột
/// khác giữ nguyên giá trị cũ.
class VocabProgressController {
  VocabProgressController(this._sb, this._userId);

  final SupabaseClient _sb;
  final String _userId;

  // Postgrest builders are lazy — the HTTP request only fires once the
  // builder is awaited. Awaiting internally here means callers can safely
  // fire-and-forget without the write silently never happening.
  Future<void> setKnown(String vocabId, bool isKnown) async {
    await _sb.from('user_vocab_progress').upsert(
      {'user_id': _userId, 'vocab_id': vocabId, 'status': isKnown ? 'known' : 'unknown'},
      onConflict: 'user_id,vocab_id',
    );
  }

  Future<void> setStarred(String vocabId, bool starred) async {
    await _sb.from('user_vocab_progress').upsert(
      {'user_id': _userId, 'vocab_id': vocabId, 'starred': starred},
      onConflict: 'user_id,vocab_id',
    );
  }
}
