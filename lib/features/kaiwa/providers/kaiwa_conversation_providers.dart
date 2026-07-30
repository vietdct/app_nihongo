import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/supabase_providers.dart';
import '../../../domain/entities/kaiwa_conversation.dart';

/// Danh sách buổi hội thoại thật của người dùng hiện tại, mới nhất trước —
/// dùng cho phụ đề "AI Kaiwa" ở màn Ôn tập và mục "Lịch sử Kaiwa" ở Hồ sơ.
final kaiwaConversationsProvider =
    FutureProvider.autoDispose<List<KaiwaConversation>>((ref) async {
  final sb = ref.watch(supabaseProvider);
  final userId = ref.watch(currentUserProvider)?.id;
  if (userId == null) return [];

  final rows = await sb
      .from('kaiwa_conversations')
      .select()
      .eq('user_id', userId)
      .order('last_message_at', ascending: false);

  return [
    for (final r in rows)
      KaiwaConversation(
        id: r['id'] as String,
        personaId: r['persona_id'] as String,
        scenarioId: r['scenario_id'] as String,
        startedAt: DateTime.parse(r['started_at'] as String),
        lastMessageAt: DateTime.parse(r['last_message_at'] as String),
      ),
  ];
});
