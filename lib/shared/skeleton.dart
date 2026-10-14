import 'package:flutter/material.dart';

import '../core/theme/app_motion.dart';

/// Khung giữ chỗ khi nội dung đang tải (chỉ mô phỏng hình dạng, KHÔNG chứa dữ
/// liệu giả). Dùng bọc [SkeletonScope] quanh cả cụm skeleton của một vùng rồi
/// đặt các [SkeletonBox] bên trong.
///
/// [SkeletonScope] giữ MỘT AnimationController chung cho mọi ô bên trong (không
/// mỗi ô một controller), nhịp nhấp nhẹ ~1,4 giây; tự dừng và dispose khi bị gỡ
/// khỏi cây (tức là ngay khi dữ liệu tải xong). Bật "Giảm chuyển động" → ô tĩnh,
/// không chạy gì. Đọc màn hình chỉ nghe thấy một nhãn "Đang tải nội dung" thay
/// vì từng ô.
class SkeletonScope extends StatefulWidget {
  const SkeletonScope({super.key, required this.child});

  final Widget child;

  @override
  State<SkeletonScope> createState() => _SkeletonScopeState();
}

class _SkeletonScopeState extends State<SkeletonScope>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (AppMotion.reduced(context)) {
      _controller
        ..stop()
        ..value = 0;
    } else if (!_controller.isAnimating) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _SkeletonAnimation(
      animation: _controller,
      child: Semantics(
        label: 'Đang tải nội dung',
        child: ExcludeSemantics(child: widget.child),
      ),
    );
  }
}

class _SkeletonAnimation extends InheritedWidget {
  const _SkeletonAnimation({required this.animation, required super.child});

  final Animation<double> animation;

  static Animation<double>? maybeOf(BuildContext context) => context
      .dependOnInheritedWidgetOfExactType<_SkeletonAnimation>()
      ?.animation;

  // Animation là Listenable ổn định (cùng 1 controller); không cần thông báo.
  @override
  bool updateShouldNotify(_SkeletonAnimation old) => animation != old.animation;
}

/// Một ô giữ chỗ (dòng chữ, thẻ, avatar...). Đặt trong [SkeletonScope] để có
/// nhịp nhấp; đứng ngoài scope thì hiện tĩnh. Màu riêng cho sáng/tối (nền tối
/// dịu, không chói).
class SkeletonBox extends StatelessWidget {
  const SkeletonBox({
    super.key,
    this.width,
    this.height = 12,
    this.radius = 6,
    this.circle = false,
  });

  /// null = giãn theo ràng buộc của cha.
  final double? width;
  final double height;
  final double radius;

  /// Hình tròn (avatar/icon); khi đó dùng [width] (hoặc [height]) làm đường kính.
  final bool circle;

  static const _lightBase = Color(0xFFF1EADA);
  static const _lightHighlight = Color(0xFFF8F3E8);
  static const _darkBase = Color(0xFF1C2426);
  static const _darkHighlight = Color(0xFF242E31);

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final base = dark ? _darkBase : _lightBase;
    final highlight = dark ? _darkHighlight : _lightHighlight;
    final animation = _SkeletonAnimation.maybeOf(context);
    final size = circle ? (width ?? height) : null;

    Widget box(Color color) => Container(
          width: circle ? size : width,
          height: circle ? size : height,
          decoration: BoxDecoration(
            color: color,
            shape: circle ? BoxShape.circle : BoxShape.rectangle,
            borderRadius: circle ? null : BorderRadius.circular(radius),
          ),
        );

    if (animation == null) return box(base);
    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) => box(
        Color.lerp(
          base,
          highlight,
          Curves.easeInOut.transform(animation.value),
        )!,
      ),
    );
  }
}
