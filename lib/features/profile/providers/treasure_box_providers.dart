import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/network/supabase_providers.dart';
import '../../../domain/entities/treasure_box.dart';

/// Danh sách rương của user hiện tại — trước khi đọc, gọi
/// `claim_treasure_milestones()` để cấp rương mới nếu `streak_count` vừa
/// vượt mốc chưa nhận (idempotent: RPC tự bỏ qua mốc đã có rương).
final treasureBoxesProvider = FutureProvider.autoDispose<List<TreasureBox>>((
  ref,
) async {
  final sb = ref.watch(supabaseProvider);
  final userId = ref.watch(currentUserProvider)?.id;
  if (userId == null) return [];

  await sb.rpc('claim_treasure_milestones');

  final rows = await sb
      .from('treasure_boxes')
      .select('id, milestone, reward_coins, opened_at')
      .eq('user_id', userId)
      .order('milestone');

  return [
    for (final r in rows)
      TreasureBox(
        id: r['id'] as String,
        milestone: r['milestone'] as int,
        rewardCoins: r['reward_coins'] as int?,
        openedAt: r['opened_at'] == null
            ? null
            : DateTime.parse(r['opened_at'] as String),
      ),
  ];
});

final treasureBoxServiceProvider = Provider.autoDispose<TreasureBoxService?>((
  ref,
) {
  final sb = ref.watch(supabaseProvider);
  final userId = ref.watch(currentUserProvider)?.id;
  if (userId == null) return null;
  return TreasureBoxService(sb);
});

class TreasureBoxService {
  TreasureBoxService(this._sb);

  final SupabaseClient _sb;

  /// Mở 1 rương, trả về số Coin nhận được. Server tự tính thưởng ngẫu
  /// nhiên theo mốc (không tin số client gửi lên) — xem `open_treasure_box`.
  Future<int> open(String boxId) async {
    final result = await _sb.rpc(
      'open_treasure_box',
      params: {'p_box_id': boxId},
    );
    return (result as Map)['reward_coins'] as int;
  }
}
