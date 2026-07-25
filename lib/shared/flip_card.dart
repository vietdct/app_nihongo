import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Thẻ lật 2 mặt dùng chung cho flashcard từ vựng và kanji.
/// Gắn [key] theo id của item để state tự reset về mặt trước khi
/// chuyển sang thẻ khác (thay vì tự quản lý reset thủ công).
class FlipCard extends StatefulWidget {
  const FlipCard({super.key, required this.front, required this.back});

  final Widget front;
  final Widget back;

  @override
  State<FlipCard> createState() => _FlipCardState();
}

class _FlipCardState extends State<FlipCard> with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 380),
  );
  bool _showingFront = true;

  void _flip() {
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
    return GestureDetector(
      onTap: _flip,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final angle = _controller.value * math.pi;
          final isFrontVisible = angle <= math.pi / 2;
          final displayAngle = isFrontVisible ? angle : angle - math.pi;
          return Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.0015)
              ..rotateY(displayAngle),
            child: isFrontVisible ? widget.front : widget.back,
          );
        },
      ),
    );
  }
}
