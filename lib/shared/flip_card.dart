import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/theme/app_motion.dart';

/// Thẻ lật 2 mặt dùng chung cho flashcard từ vựng và kanji.
/// Gắn [key] theo id của item để state tự reset về mặt trước khi
/// chuyển sang thẻ khác (thay vì tự quản lý reset thủ công).
class FlipCard extends StatefulWidget {
  const FlipCard({super.key, required this.front, required this.back});

  final Widget front;
  final Widget back;

  @override
  State<FlipCard> createState() => FlipCardState();
}

/// Public state so parent widgets can trigger a flip programmatically (VD nút
/// "Xem lại"/"Tập viết" ở mặt sau quay ngược về mặt trước) qua GlobalKey,
/// giống cách KanjiStrokeCanvasState expose replay().
class FlipCardState extends State<FlipCard>
    with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 380),
  );
  bool _showingFront = true;

  void flip() {
    // Giảm chuyển động: lật ngay (duration 0) nhưng vẫn đổi mặt.
    _controller.duration =
        AppMotion.resolve(context, const Duration(milliseconds: 380));
    if (_showingFront) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
    setState(() => _showingFront = !_showingFront);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      onTapHint: _showingFront ? 'Lật xem mặt sau' : 'Lật về mặt trước',
      child: GestureDetector(
        onTap: flip,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            final angle = _controller.value * math.pi;
            final isFrontVisible = angle <= math.pi / 2;
            final displayAngle = isFrontVisible ? angle : angle - math.pi;
            // Nhấc nhẹ lên (tối đa 3%) ở giữa lúc lật cho có chiều sâu; về 1.0
            // khi dừng nên không đổi kích thước thẻ lúc đứng yên.
            final lift = 1 + 0.03 * math.sin(_controller.value * math.pi);
            return Transform.scale(
              scale: lift,
              child: Transform(
                alignment: Alignment.center,
                transform: Matrix4.identity()
                  ..setEntry(3, 2, 0.0015)
                  ..rotateY(displayAngle),
                child: isFrontVisible ? widget.front : widget.back,
              ),
            );
          },
        ),
      ),
    );
  }
}
