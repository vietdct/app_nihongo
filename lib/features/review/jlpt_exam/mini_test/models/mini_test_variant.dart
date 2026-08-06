/// 3 biến thể Mini Test (docs/JLPT_MINI_TEST_DESIGN.md §2) — đề xuất người
/// dùng 2026-08-06 thay cho 1 nút "Mini Test" đơn. AI Mini Test đã bỏ khỏi
/// phạm vi theo yêu cầu người dùng (2026-08-06) — dừng ở Weak Point Mini.
enum MiniTestVariant {
  quick5,
  daily,
  weakPoint;

  /// Nhãn hiển thị UI, khớp đúng chữ đã dùng ở Home Screen
  /// (`mini_test_home_screen.dart`).
  String get label => switch (this) {
        MiniTestVariant.quick5 => '⚡ Quick 5',
        MiniTestVariant.daily => '📚 Daily Mini Test',
        MiniTestVariant.weakPoint => '🎯 Weak Point Mini',
      };
}
