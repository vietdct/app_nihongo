/// 3 biến thể Mini Test (docs/JLPT_MINI_TEST_DESIGN.md §2) — đề xuất người
/// dùng 2026-08-06 thay cho 1 nút "Mini Test" đơn. AI Mini Test đã bỏ khỏi
/// phạm vi theo yêu cầu người dùng (2026-08-06) — dừng ở Weak Point Mini.
///
/// `listening` (thêm 2026-08-07): điểm vào "Nghe hiểu" riêng ở tab Ôn tập
/// (`review_screen.dart`) — chạy thẳng qua hạ tầng Mini Test có sẵn với
/// `sources: ['listening']`, không viết runner mới (xem
/// `docs/REVIEW_DESIGN.md` §15.6).
enum MiniTestVariant {
  quick5,
  daily,
  weakPoint,
  listening;

  /// Nhãn hiển thị UI, khớp đúng chữ đã dùng ở Home Screen
  /// (`mini_test_home_screen.dart`).
  String get label => switch (this) {
        MiniTestVariant.quick5 => '⚡ Quick 5',
        MiniTestVariant.daily => '📚 Daily Mini Test',
        MiniTestVariant.weakPoint => '🎯 Weak Point Mini',
        MiniTestVariant.listening => '🎧 Nghe hiểu',
      };
}
