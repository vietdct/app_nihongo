import 'package:flutter/material.dart';

import '../../core/theme/app_motion.dart';

/// Thanh tiến độ bo tròn chạy mượt từ giá trị cũ sang giá trị mới khi [value]
/// đổi. Lần hiển thị đầu hiện thẳng giá trị hiện tại (không chạy từ 0), và
/// rebuild của widget cha với cùng [value] không chạy lại animation. Chỉ vẽ lại
/// dữ liệu truyền vào — không tính tiến độ, không ghi dữ liệu.
class AnimatedProgressBar extends StatelessWidget {
  const AnimatedProgressBar({
    super.key,
    required this.value,
    required this.minHeight,
    required this.backgroundColor,
    required this.color,
    this.borderRadius = 100,
  });

  /// 0–1. Giá trị ngoài khoảng hoặc không hợp lệ được kẹp về 0–1.
  final double value;
  final double minHeight;
  final Color backgroundColor;
  final Color color;
  final double borderRadius;

  static double _clean(double v) => v.isNaN ? 0 : v.clamp(0.0, 1.0);

  @override
  Widget build(BuildContext context) {
    final target = _clean(value);
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(end: target),
      duration: AppMotion.resolve(context, AppMotion.emphasized),
      curve: AppMotion.curveSmooth,
      builder: (context, v, _) => ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: LinearProgressIndicator(
          value: v,
          minHeight: minHeight,
          backgroundColor: backgroundColor,
          valueColor: AlwaysStoppedAnimation(color),
        ),
      ),
    );
  }
}
