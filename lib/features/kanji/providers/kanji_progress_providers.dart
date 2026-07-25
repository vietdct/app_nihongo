import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/network/supabase_providers.dart';
import '../../../domain/entities/kanji_progress.dart';

/// Toàn bộ tiến độ (thuộc/chưa thuộc + đã lưu) của người dùng hiện tại,
/// theo kanji_id. Ghi trực tiếp qua Supabase (không qua Drift) vì đây là
/// dữ liệu riêng tư theo người dùng, không phải nội dung học liệu dùng chung.
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
      ),
  };
});

final kanjiProgressControllerProvider = Provider.autoDispose<KanjiProgressController?>((ref) {
  final sb = ref.watch(supabaseProvider);
  final userId = ref.watch(currentUserProvider)?.id;
  if (userId == null) return null;
  return KanjiProgressController(sb, userId);
});

/// Ghi nhận trạng thái thuộc/chưa thuộc và đánh dấu sao. Upsert theo
/// (user_id, kanji_id) — chỉ cột được truyền vào mới bị ghi đè, các cột
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
}
