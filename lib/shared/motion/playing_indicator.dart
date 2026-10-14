import 'package:flutter/material.dart';

import '../../core/theme/app_motion.dart';

/// Vòng sóng lan ra quanh nút nghe KHI [active] (audio thật sự đang phát).
/// Chỉ quan sát cờ [active] do player cấp — không tự phát/dừng audio. Dừng
/// hẳn (không lặp vô hạn) ngay khi [active] về false hoặc widget bị gỡ; khi
/// bật "Giảm chuyển động" chỉ hiện một vòng tĩnh.
class PlayingRing extends StatefulWidget {
  const PlayingRing({
    super.key,
    required this.active,
    required this.color,
    required this.child,
  });

  final bool active;
  final Widget child;
  final Color color;

  @override
  State<PlayingRing> createState() => _PlayingRingState();
}

class _PlayingRingState extends State<PlayingRing>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sync();
  }

  @override
  void didUpdateWidget(PlayingRing old) {
    super.didUpdateWidget(old);
    if (old.active != widget.active) _sync();
  }

  void _sync() {
    if (widget.active && !AppMotion.reduced(context)) {
      if (!_controller.isAnimating) _controller.repeat();
    } else {
      _controller.stop();
      _controller.value = 0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduced = AppMotion.reduced(context);
    return Stack(
      alignment: Alignment.center,
      clipBehavior: Clip.none,
      children: [
        if (widget.active)
          Positioned.fill(
            child: IgnorePointer(
              child: reduced
                  ? _ring(1, 0.5)
                  : AnimatedBuilder(
                      animation: _controller,
                      builder: (context, _) {
                        final t = Curves.easeOut.transform(_controller.value);
                        return _ring(1 + 0.35 * t, 0.5 * (1 - t));
                      },
                    ),
            ),
          ),
        widget.child,
      ],
    );
  }

  Widget _ring(double scale, double opacity) {
    return Transform.scale(
      scale: scale,
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: widget.color.withValues(alpha: opacity),
            width: 2,
          ),
        ),
      ),
    );
  }
}

/// Icon đổi qua lại (phát ↔ tạm dừng) bằng co + mờ ngắn; tức thì khi giảm
/// chuyển động. Chỉ hiển thị [icon] do state thật quyết định.
class SwapIcon extends StatelessWidget {
  const SwapIcon({
    super.key,
    required this.icon,
    required this.size,
    required this.color,
  });

  final IconData icon;
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: AppMotion.resolve(context, AppMotion.fast),
      switchInCurve: AppMotion.curveEnter,
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: ScaleTransition(scale: animation, child: child),
      ),
      child: Icon(icon, key: ValueKey(icon), size: size, color: color),
    );
  }
}
