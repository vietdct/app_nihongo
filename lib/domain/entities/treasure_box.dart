/// 1 rương phần thưởng mở khoá theo mốc chuỗi ngày học (`streak_count`).
/// Xem bảng `treasure_boxes` + RPC `claim_treasure_milestones`/
/// `open_treasure_box` (`supabase/migrations/20260807180000_coins_treasure_box.sql`).
class TreasureBox {
  const TreasureBox({
    required this.id,
    required this.milestone,
    this.rewardCoins,
    this.openedAt,
  });

  final String id;

  /// Mốc chuỗi ngày đã mở khoá rương này (3/7/14/30/60/100).
  final int milestone;

  /// Số Coin nhận được — null nếu chưa mở.
  final int? rewardCoins;

  final DateTime? openedAt;

  bool get isOpened => openedAt != null;
}
