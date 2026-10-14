import 'package:flutter/material.dart';

import '../../core/theme/app_motion.dart';

/// Nội dung mới vào bằng fade + trượt ngắn mỗi khi widget này được TẠO MỚI (gắn
/// `key` theo câu hỏi/trạng thái để chạy lại; rebuild cùng key thì không chạy).
/// Khác `AnimatedSwitcher`: nội dung cũ biến mất ngay, không giữ bản cũ để
/// chồng lên và không thể bấm nhầm vào câu cũ. Tắt khi bật "Giảm chuyển động".
class EnterTransition extends StatelessWidget {
  const EnterTransition({
    super.key,
    required this.child,
    this.offset = const Offset(0.05, 0),
  });

  final Widget child;

  /// Độ lệch ban đầu theo tỉ lệ kích thước của [child] (0.05 = 5% chiều ngang).
  final Offset offset;

  @override
  Widget build(BuildContext context) {
    final duration = AppMotion.resolve(context, AppMotion.standard);
    if (duration == Duration.zero) return child;
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: duration,
      curve: AppMotion.curveEnter,
      child: child,
      builder: (context, t, child) => Opacity(
        opacity: t,
        child: FractionalTranslation(
          translation: Offset(offset.dx * (1 - t), offset.dy * (1 - t)),
          child: child,
        ),
      ),
    );
  }
}
