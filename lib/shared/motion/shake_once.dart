import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/app_motion.dart';

/// Rung ngang rất nhẹ ĐÚNG MỘT LẦN khi [trigger] chuyển từ false sang true
/// (VD đáp án sai vừa được chọn). Biên độ nhỏ, tắt dần, không lặp; không chạy
/// khi bật "Giảm chuyển động". Không ảnh hưởng bố cục (chỉ dịch hình vẽ).
class ShakeOnce extends StatefulWidget {
  const ShakeOnce({super.key, required this.trigger, required this.child});

  final bool trigger;
  final Widget child;

  @override
  State<ShakeOnce> createState() => _ShakeOnceState();
}

class _ShakeOnceState extends State<ShakeOnce>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 320),
  );

  @override
  void didUpdateWidget(ShakeOnce old) {
    super.didUpdateWidget(old);
    if (widget.trigger && !old.trigger && !AppMotion.reduced(context)) {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      child: widget.child,
      builder: (context, child) {
        final t = _controller.value;
        final dx = math.sin(t * math.pi * 4) * 5 * (1 - t);
        return Transform.translate(offset: Offset(dx, 0), child: child);
      },
    );
  }
}
