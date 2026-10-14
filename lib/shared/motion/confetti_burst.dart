import 'dart:math';

import 'package:flutter/material.dart';

import '../../core/theme/app_motion.dart';
import '../../core/theme/app_theme.dart';

/// Confetti rơi ĐÚNG MỘT LẦN (~2,2 giây) khi widget được tạo, rồi tự biến mất
/// (không lặp, không giữ controller chạy). Thuần hiệu ứng ăn mừng bằng Flutter
/// SDK, không thêm package; bọc `IgnorePointer` nên không chặn chạm; bỏ qua
/// hoàn toàn khi bật "Giảm chuyển động" hoặc [enabled] = false. Dùng cho cột
/// mốc đã được xác nhận (hoàn thành quiz/bài học), đặt trong `Positioned.fill`.
class ConfettiBurst extends StatefulWidget {
  const ConfettiBurst({super.key, this.enabled = true});

  final bool enabled;

  @override
  State<ConfettiBurst> createState() => _ConfettiBurstState();
}

class _ConfettiBurstState extends State<ConfettiBurst>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2200),
  );
  bool _started = false;

  // Cần MediaQuery nên khởi động ở didChangeDependencies, đúng 1 lần.
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (widget.enabled && !AppMotion.reduced(context)) _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  static final _pieces = List.generate(18, (i) {
    final random = Random(i * 37 + 1);
    const colors = [
      AppColors.accent,
      AppColors.moss,
      AppColors.indigo,
      AppColors.plum,
      AppColors.teal,
    ];
    return _ConfettiPiece(
      dx: random.nextDouble(),
      delay: random.nextDouble() * 0.3,
      color: colors[i % colors.length],
      size: 6 + random.nextDouble() * 5,
      spin: random.nextBool(),
    );
  });

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final value = _controller.value;
          if (value == 0 || value == 1) return const SizedBox.shrink();
          return LayoutBuilder(
            builder: (context, constraints) {
              return Stack(
                children: [
                  for (final piece in _pieces)
                    _buildPiece(piece, value, constraints),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildPiece(
    _ConfettiPiece piece,
    double value,
    BoxConstraints constraints,
  ) {
    final t = ((value - piece.delay) / (1 - piece.delay)).clamp(0.0, 1.0);
    final top = t * (constraints.maxHeight + 40) - 20;
    final angle = (piece.spin ? t : -t) * 6.2;
    return Positioned(
      left: piece.dx * constraints.maxWidth,
      top: top,
      child: Opacity(
        opacity: (1 - t).clamp(0.0, 1.0),
        child: Transform.rotate(
          angle: angle,
          child: Container(
            width: piece.size,
            height: piece.size * 1.6,
            decoration: BoxDecoration(
              color: piece.color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
      ),
    );
  }
}

class _ConfettiPiece {
  const _ConfettiPiece({
    required this.dx,
    required this.delay,
    required this.color,
    required this.size,
    required this.spin,
  });

  final double dx;
  final double delay;
  final Color color;
  final double size;
  final bool spin;
}
