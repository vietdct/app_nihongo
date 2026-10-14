import 'package:flutter/material.dart';

import '../../core/theme/app_motion.dart';

/// Xuất hiện bằng phóng nhẹ + mờ dần MỘT LẦN khi widget được tạo (VD dấu check
/// khi vừa hoàn thành bài). Rebuild không chạy lại. [enabled] = false hoặc bật
/// "Giảm chuyển động" thì hiện thẳng — dùng [enabled] để chỉ chạy khi có sự
/// kiện thật (không chạy cho trạng thái đã có từ trước).
class PopIn extends StatelessWidget {
  const PopIn({super.key, required this.child, this.enabled = true});

  final Widget child;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final duration = AppMotion.resolve(context, AppMotion.emphasized);
    if (!enabled || duration == Duration.zero) return child;
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: duration,
      curve: Curves.easeOutBack,
      child: child,
      builder: (context, t, child) => Opacity(
        opacity: t.clamp(0.0, 1.0),
        child: Transform.scale(scale: 0.6 + 0.4 * t, child: child),
      ),
    );
  }
}
