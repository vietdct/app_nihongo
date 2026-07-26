import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

/// Vòng tròn đếm ngược cho mỗi câu hỏi quiz — [controller].value chạy từ
/// 1.0 (đầy, mới bắt đầu câu) về 0.0 (hết giờ). Đổi sang màu `danger` khi
/// còn dưới 30% thời gian để tạo cảm giác gấp gáp.
class CountdownRing extends StatelessWidget {
  const CountdownRing(
      {super.key,
      required this.controller,
      required this.totalSeconds,
      this.size = 48,});

  final AnimationController controller;
  final int totalSeconds;
  final double size;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final t = controller.value.clamp(0.0, 1.0);
        final color = t < 0.3 ? AppColors.danger : AppColors.accent;
        final secondsLeft = (t * totalSeconds).ceil();
        return SizedBox(
          width: size,
          height: size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CircularProgressIndicator(
                value: t,
                strokeWidth: 4,
                backgroundColor: AppColors.chip,
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
              Text(
                '$secondsLeft',
                style: TextStyle(
                    fontWeight: FontWeight.w800, fontSize: 14, color: color,),
              ),
            ],
          ),
        );
      },
    );
  }
}
