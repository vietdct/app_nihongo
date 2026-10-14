import 'package:flutter/material.dart';

/// Quy ước chuyển động dùng chung toàn app — mọi animation nhỏ lấy thời lượng
/// và curve từ đây thay vì tự hardcode, để cảm giác nhất quán.
///
/// Mức thời lượng: [fast] cho phản hồi chạm, [standard] cho đổi trạng thái,
/// [emphasized] cho thay đổi lớn hơn (thanh tiến độ, mở/đóng panel).
abstract final class AppMotion {
  static const fast = Duration(milliseconds: 140);
  static const standard = Duration(milliseconds: 220);
  static const emphasized = Duration(milliseconds: 300);

  /// Phần tử xuất hiện / nhấn.
  static const curveEnter = Curves.easeOut;

  /// Đổi trạng thái qua lại.
  static const curveChange = Curves.easeInOut;

  /// Chuyển động ngắn cần mượt (thanh tiến độ, đổi kích thước).
  static const curveSmooth = Curves.easeOutCubic;

  /// Độ co khi nhấn card/nút (rất nhẹ để không làm vỡ bố cục).
  static const pressedScale = 0.97;

  /// Người dùng bật "Giảm chuyển động" của hệ điều hành.
  static bool reduced(BuildContext context) =>
      MediaQuery.maybeDisableAnimationsOf(context) ?? false;

  /// [d], hoặc [Duration.zero] khi đang giảm chuyển động.
  static Duration resolve(BuildContext context, Duration d) =>
      reduced(context) ? Duration.zero : d;
}
