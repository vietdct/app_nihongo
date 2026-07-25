import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';

/// Bảng vẽ nét chữ Hán bằng ngón tay để tìm kiếm. Ghi lại từng nét thành
/// danh sách điểm chạm; báo [onStrokesChanged] mỗi khi nhấc tay (hết 1 nét)
/// để tầng trên so khớp dần — không cần vẽ xong cả chữ mới có gợi ý.
class KanjiDrawCanvas extends StatefulWidget {
  const KanjiDrawCanvas({super.key, required this.onStrokesChanged, this.size = 280});

  final ValueChanged<List<List<Offset>>> onStrokesChanged;
  final double size;

  @override
  State<KanjiDrawCanvas> createState() => KanjiDrawCanvasState();
}

class KanjiDrawCanvasState extends State<KanjiDrawCanvas> {
  final List<List<Offset>> _strokes = [];
  List<Offset>? _current;

  bool get isEmpty => _strokes.isEmpty;

  void undoStroke() {
    if (_strokes.isEmpty) return;
    setState(() => _strokes.removeLast());
    widget.onStrokesChanged(List.of(_strokes));
  }

  void clear() {
    setState(() {
      _strokes.clear();
      _current = null;
    });
    widget.onStrokesChanged(const []);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanStart: (d) => setState(() => _current = [d.localPosition]),
      onPanUpdate: (d) => setState(() => _current?.add(d.localPosition)),
      onPanEnd: (_) {
        final stroke = _current;
        if (stroke != null && stroke.length > 1) {
          setState(() {
            _strokes.add(stroke);
            _current = null;
          });
          widget.onStrokesChanged(List.of(_strokes));
        } else {
          setState(() => _current = null);
        }
      },
      child: Container(
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border, width: 0.6),
        ),
        clipBehavior: Clip.antiAlias,
        child: CustomPaint(
          painter: _InkPainter(strokes: _strokes, current: _current),
          size: Size.square(widget.size),
        ),
      ),
    );
  }
}

class _InkPainter extends CustomPainter {
  _InkPainter({required this.strokes, required this.current});

  final List<List<Offset>> strokes;
  final List<Offset>? current;

  @override
  void paint(Canvas canvas, Size size) {
    final guidePaint = Paint()
      ..color = AppColors.border
      ..strokeWidth = 1;
    canvas.drawLine(Offset(size.width / 2, 0), Offset(size.width / 2, size.height), guidePaint);
    canvas.drawLine(Offset(0, size.height / 2), Offset(size.width, size.height / 2), guidePaint);

    final inkPaint = Paint()
      ..color = AppColors.ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = 7
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    for (final stroke in strokes) {
      _drawStroke(canvas, stroke, inkPaint);
    }
    if (current != null) _drawStroke(canvas, current!, inkPaint);
  }

  void _drawStroke(Canvas canvas, List<Offset> points, Paint paint) {
    if (points.length < 2) return;
    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (final p in points.skip(1)) {
      path.lineTo(p.dx, p.dy);
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _InkPainter oldDelegate) =>
      oldDelegate.strokes != strokes || oldDelegate.current != current;
}
