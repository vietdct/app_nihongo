import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../theme/app_motion.dart';

/// Chuyển cảnh trang theo hệ điều hành, có tôn trọng "Giảm chuyển động".
///
/// Bình thường: giữ nguyên chuyển cảnh gốc của [base] (iOS: trượt Cupertino +
/// vuốt cạnh trái để quay lại; không thay thế để không mất cử chỉ). Khi bật
/// "Giảm chuyển động": màn mới chỉ mờ dần (không trượt, không parallax màn
/// bên dưới). Cử chỉ vuốt-back vẫn nằm trong cây widget của [base] nên không
/// bị vô hiệu; khi vuốt, độ mờ bám theo ngón tay.
///
/// Chỉ cấu hình trong [PageTransitionsTheme] — không route nào tự bọc thêm
/// transition, nên không có chuyển cảnh kép.
class ReducedMotionPageTransitionsBuilder extends PageTransitionsBuilder {
  const ReducedMotionPageTransitionsBuilder([
    this.base = const CupertinoPageTransitionsBuilder(),
  ]);

  final PageTransitionsBuilder base;

  /// Phần đầu của thời lượng route dùng cho fade khi giảm chuyển động.
  static const _fadeEnd = 0.4;

  @override
  Duration get transitionDuration => base.transitionDuration;

  @override
  Duration get reverseTransitionDuration => base.reverseTransitionDuration;

  @override
  DelegatedTransitionBuilder? get delegatedTransition {
    final inner = base.delegatedTransition;
    if (inner == null) return null;
    return (context, animation, secondaryAnimation, allowSnapshotting, child) {
      // Giảm chuyển động: màn bên dưới đứng yên thay vì dịch/parallax.
      if (AppMotion.reduced(context)) return child;
      return inner(
        context,
        animation,
        secondaryAnimation,
        allowSnapshotting,
        child,
      );
    };
  }

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    if (!AppMotion.reduced(context)) {
      return base.buildTransitions<T>(
        route,
        context,
        animation,
        secondaryAnimation,
        child,
      );
    }
    // Dựng bản "đứng yên" (animation hoàn tất) để vẫn giữ lớp cử chỉ vuốt-back
    // của base, rồi chỉ mờ dần lớp ngoài theo animation thật của route.
    final still = base.buildTransitions<T>(
      route,
      context,
      kAlwaysCompleteAnimation,
      kAlwaysDismissedAnimation,
      child,
    );
    return FadeTransition(
      opacity: animation.drive(CurveTween(curve: const Interval(0, _fadeEnd))),
      child: still,
    );
  }
}
