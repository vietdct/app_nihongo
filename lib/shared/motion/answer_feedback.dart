import 'package:flutter/material.dart';

import '../../core/theme/app_motion.dart';
import '../../core/theme/app_theme.dart';
import 'press_scale.dart';
import 'shake_once.dart';

/// Khung bao 1 đáp án trắc nghiệm: mờ/rõ mượt theo [opacity], co nhẹ khi nhấn
/// (chỉ khi [pressable]) và rung nhẹ 1 lần khi [wrong] vừa bật. Không đổi
/// callback hay vùng chạm của đáp án; [child] vẫn tự lo InkWell/onTap.
class AnswerOptionFrame extends StatelessWidget {
  const AnswerOptionFrame({
    super.key,
    required this.opacity,
    required this.wrong,
    required this.pressable,
    required this.child,
  });

  final double opacity;
  final bool wrong;
  final bool pressable;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: opacity,
      duration: AppMotion.resolve(context, AppMotion.fast),
      curve: AppMotion.curveChange,
      child: ShakeOnce(
        trigger: wrong,
        child: PressScale(enabled: pressable, child: child),
      ),
    );
  }
}

/// Biểu tượng đúng/sai hiện ở cuối đáp án (không chỉ dựa vào màu): dấu tick
/// cho đáp án đúng, dấu X cho đáp án người dùng chọn sai. Hiện bằng phóng nhẹ.
class AnswerResultIcon extends StatelessWidget {
  const AnswerResultIcon({super.key, required this.correct});

  final bool correct;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.5, end: 1),
      duration: AppMotion.resolve(context, AppMotion.standard),
      curve: Curves.easeOutBack,
      builder: (context, t, child) => Transform.scale(scale: t, child: child),
      child: Icon(
        correct ? Icons.check_circle_rounded : Icons.cancel_rounded,
        size: 22,
        color: correct ? AppColors.moss : AppColors.danger,
        semanticLabel: correct ? 'Đáp án đúng' : 'Đáp án sai',
      ),
    );
  }
}
