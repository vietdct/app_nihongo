import 'package:flutter/material.dart';

import '../../core/theme/app_motion.dart';

/// Chuyển nội dung bằng fade + trượt rất ngắn khi [child] đổi (VD: đang tải →
/// có dữ liệu → trống/lỗi). Animation chỉ chạy khi key/kiểu của [child] đổi,
/// không chạy khi chỉ rebuild. Giữ nguyên ràng buộc kích thước của cha (không
/// co/giãn như `Stack` mặc định của `AnimatedSwitcher`) và bỏ qua hiệu ứng khi
/// bật "Giảm chuyển động".
class FadeSwitcher extends StatelessWidget {
  const FadeSwitcher({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final duration = AppMotion.resolve(context, AppMotion.standard);
    return AnimatedSwitcher(
      duration: duration,
      reverseDuration: duration,
      switchInCurve: AppMotion.curveEnter,
      switchOutCurve: AppMotion.curveEnter,
      layoutBuilder: (current, previous) => Stack(
        fit: StackFit.passthrough,
        children: [...previous, if (current != null) current],
      ),
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.02),
            end: Offset.zero,
          ).animate(animation),
          child: child,
        ),
      ),
      child: child,
    );
  }
}
