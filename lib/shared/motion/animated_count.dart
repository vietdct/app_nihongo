import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/app_motion.dart';

/// Số nguyên đếm mượt tới giá trị mới — CHỈ trình bày, không đọc/ghi dữ liệu.
///
/// - [value] null (chưa tải): hiện [placeholder].
/// - Lần đầu có giá trị: hiện thẳng giá trị đó, không đếm từ 0 giả (không biết
///   giá trị trước). Truyền [from] khi "giá trị trước" thật sự là [from] (VD
///   XP nhận được trong phiên bắt đầu từ 0).
/// - Giá trị đổi khi widget còn sống (VD profile tải lại sau khi làm quiz): đếm
///   từ số đang hiển thị tới giá trị mới; đổi tiếp giữa chừng thì đếm tiếp từ
///   số hiện tại, luôn kết thúc đúng [value]. Rebuild cùng giá trị: không chạy.
/// - Khi tăng, số nảy nhẹ một lần ([popOnIncrease]).
/// - Giảm chuyển động: hiện thẳng giá trị mới.
class AnimatedCount extends StatefulWidget {
  const AnimatedCount({
    super.key,
    required this.value,
    required this.style,
    this.from,
    this.prefix = '',
    this.placeholder = '–',
    this.popOnIncrease = true,
    this.duration = const Duration(milliseconds: 700),
  });

  final int? value;
  final TextStyle style;
  final int? from;
  final String prefix;
  final String placeholder;
  final bool popOnIncrease;
  final Duration duration;

  @override
  State<AnimatedCount> createState() => _AnimatedCountState();
}

class _AnimatedCountState extends State<AnimatedCount>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pop = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 360),
  );

  @override
  void didUpdateWidget(AnimatedCount old) {
    super.didUpdateWidget(old);
    final before = old.value;
    final after = widget.value;
    if (widget.popOnIncrease &&
        before != null &&
        after != null &&
        after > before &&
        !AppMotion.reduced(context)) {
      _pop.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _pop.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final value = widget.value;
    if (value == null) {
      return Text(widget.placeholder, style: widget.style);
    }
    final text = TweenAnimationBuilder<double>(
      tween:
          Tween<double>(begin: widget.from?.toDouble(), end: value.toDouble()),
      duration: AppMotion.resolve(context, widget.duration),
      curve: AppMotion.curveSmooth,
      builder: (context, v, _) =>
          Text('${widget.prefix}${v.round()}', style: widget.style),
    );
    return AnimatedBuilder(
      animation: _pop,
      child: text,
      builder: (context, child) => Transform.scale(
        scale: 1 + 0.14 * math.sin(_pop.value * math.pi),
        child: child,
      ),
    );
  }
}
