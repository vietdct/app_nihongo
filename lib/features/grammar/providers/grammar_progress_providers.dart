import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/network/supabase_providers.dart';
import '../../../domain/entities/grammar_progress.dart';

/// Toàn bộ tiến độ (thuộc/chưa thuộc + đã lưu) của người dùng hiện tại,
/// theo grammar_id. Ghi trực tiếp qua Supabase (không qua Drift) vì đây là
/// dữ liệu riêng tư theo người dùng, không phải nội dung học liệu dùng chung.
final grammarProgressProvider = FutureProvider.autoDispose<Map<String, GrammarProgress>>((ref) async {
  final sb = ref.watch(supabaseProvider);
  final userId = ref.watch(currentUserProvider)?.id;
  if (userId == null) return {};

  final rows = await sb.from('user_grammar_progress').select().eq('user_id', userId);
  return {
    for (final r in rows)
      r['grammar_id'] as String: GrammarProgress(
        grammarId: r['grammar_id'] as String,
        isKnown: r['status'] == null ? null : r['status'] == 'known',
        starred: r['starred'] as bool? ?? false,
      ),
  };
});

final grammarProgressControllerProvider = Provider.autoDispose<GrammarProgressController?>((ref) {
  final sb = ref.watch(supabaseProvider);
  final userId = ref.watch(currentUserProvider)?.id;
  if (userId == null) return null;
  return GrammarProgressController(sb, userId);
});

/// Ghi nhận trạng thái thuộc/chưa thuộc và đánh dấu sao. Upsert theo
/// (user_id, grammar_id) — chỉ cột được truyền vào mới bị ghi đè, các cột
/// khác giữ nguyên giá trị cũ.
class GrammarProgressController {
  GrammarProgressController(this._sb, this._userId);

  final SupabaseClient _sb;
  final String _userId;

  // Postgrest builders là lazy — request chỉ thực sự gửi khi được await.
  // Await ngay trong này để caller có thể fire-and-forget an toàn.
  Future<void> setKnown(String grammarId, bool isKnown) async {
    await _sb.from('user_grammar_progress').upsert(
      {'user_id': _userId, 'grammar_id': grammarId, 'status': isKnown ? 'known' : 'unknown'},
      onConflict: 'user_id,grammar_id',
    );
  }

  Future<void> setStarred(String grammarId, bool starred) async {
    await _sb.from('user_grammar_progress').upsert(
      {'user_id': _userId, 'grammar_id': grammarId, 'starred': starred},
      onConflict: 'user_id,grammar_id',
    );
  }
}
