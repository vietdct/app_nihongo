import 'package:flutter/material.dart';

import '../../core/theme/app_motion.dart';

/// Co nhẹ phần tử con khi người dùng đang nhấn giữ — bọc quanh card/nút đã có
/// sẵn `InkWell`/`onTap` (không thay thế chúng, không đổi vùng chạm hay
/// callback). Dùng `onTapDown/Up/Cancel` nên cùng quy tắc với `InkWell`:
/// bắt đầu cuộn thì tự thả về kích thước gốc, và chạm nhanh (<100ms) không
/// nháy. Tắt hẳn khi hệ điều hành bật "Giảm chuyển động" hoặc [enabled] = false.
class PressScale extends StatefulWidget {
  const PressScale({
    super.key,
    required this.child,
    this.enabled = true,
    this.scale = AppMotion.pressedScale,
  });

  final Widget child;
  final bool enabled;
  final double scale;

  @override
  State<PressScale> createState() => _PressScaleState();
}

class _PressScaleState extends State<PressScale> {
  bool _pressed = false;

  void _set(bool value) {
    if (_pressed == value || !mounted) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled || AppMotion.reduced(context)) return widget.child;
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTapDown: (_) => _set(true),
      onTapUp: (_) => _set(false),
      onTapCancel: () => _set(false),
      child: AnimatedScale(
        scale: _pressed ? widget.scale : 1,
        duration: AppMotion.fast,
        curve: AppMotion.curveEnter,
        child: widget.child,
      ),
    );
  }
}
