import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:path_drawing/path_drawing.dart';

/// Dữ liệu nét vẽ 1 chữ Hán, rút gọn từ KanjiVG (viewBox vuông + danh sách
/// path SVG "d" của từng nét, đúng thứ tự viết).
class KanjiStrokeData {
  const KanjiStrokeData({required this.viewBox, required this.strokes});

  final double viewBox;
  final List<Path> strokes;

  static KanjiStrokeData? tryParse(String? json) {
    if (json == null || json.isEmpty) return null;
    try {
      final map = jsonDecode(json) as Map<String, dynamic>;
      final viewBox = (map['viewBox'] as num).toDouble();
      final strokes = (map['strokes'] as List)
          .cast<String>()
          .map(parseSvgPathData)
          .toList();
      if (strokes.isEmpty) return null;
      return KanjiStrokeData(viewBox: viewBox, strokes: strokes);
    } catch (_) {
      return null;
    }
  }
}

/// Vẽ hoạt hoạ nét chữ Hán theo đúng thứ tự (kiểu Mazii): nét mờ làm nền,
/// nét đen tô dần theo thời gian. Chạm vào để xem lại từ đầu.
class KanjiStrokeCanvas extends StatefulWidget {
  const KanjiStrokeCanvas({
    super.key,
    required this.character,
    required this.strokeData,
    this.size = 240,
    this.strokeColor = const Color(0xFF2A2420),
    this.guideColor = const Color(0x1F2A2420),
  });

  final String character;
  final KanjiStrokeData? strokeData;
  final double size;
  final Color strokeColor;
  final Color guideColor;

  @override
  State<KanjiStrokeCanvas> createState() => KanjiStrokeCanvasState();
}

class KanjiStrokeCanvasState extends State<KanjiStrokeCanvas> with SingleTickerProviderStateMixin {
  static const _perStroke = Duration(milliseconds: 420);

  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    final n = widget.strokeData?.strokes.length ?? 0;
    _controller = AnimationController(vsync: this, duration: _perStroke * (n == 0 ? 1 : n));
    if (n > 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _controller.forward(from: 0);
      });
    }
  }

  @override
  void didUpdateWidget(covariant KanjiStrokeCanvas oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.character != widget.character) {
      final n = widget.strokeData?.strokes.length ?? 0;
      _controller.duration = _perStroke * (n == 0 ? 1 : n);
      if (n > 0) _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void replay() {
    if (widget.strokeData == null) return;
    _controller.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.strokeData;
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: data == null
          ? Center(
              child: Text(
                widget.character,
                style: TextStyle(fontFamily: 'ZenMaruGothic', fontSize: widget.size * 0.55, color: widget.strokeColor),
              ),
            )
          : AnimatedBuilder(
              animation: _controller,
              builder: (context, _) => CustomPaint(
                painter: _StrokePainter(
                  data: data,
                  progress: _controller.value * data.strokes.length,
                  strokeColor: widget.strokeColor,
                  guideColor: widget.guideColor,
                ),
              ),
            ),
    );
  }
}

class _StrokePainter extends CustomPainter {
  _StrokePainter({required this.data, required this.progress, required this.strokeColor, required this.guideColor});

  final KanjiStrokeData data;
  final double progress;
  final Color strokeColor;
  final Color guideColor;

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / data.viewBox;
    canvas.scale(scale, scale);

    final guidePaint = Paint()
      ..color = guideColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    for (final stroke in data.strokes) {
      canvas.drawPath(stroke, guidePaint);
    }

    final strokePaint = Paint()
      ..color = strokeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.4
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final completeCount = progress.floor().clamp(0, data.strokes.length);
    for (var i = 0; i < completeCount; i++) {
      canvas.drawPath(data.strokes[i], strokePaint);
    }
    var currentFraction = 0.0;
    if (completeCount < data.strokes.length) {
      final fraction = progress - completeCount;
      if (fraction > 0) {
        currentFraction = fraction;
        final partial = _extractPartial(data.strokes[completeCount], fraction);
        canvas.drawPath(partial, strokePaint);
      }
    }

    // Đánh số thứ tự nét: nét đã/đang vẽ hiện số đậm, nét chưa tới hiện mờ
    // để người học vẫn thấy trước được toàn bộ thứ tự viết.
    for (var i = 0; i < data.strokes.length; i++) {
      final start = _strokeStart(data.strokes[i]);
      if (start == null) continue;
      final drawn = i < completeCount || (i == completeCount && currentFraction > 0);
      final numberColor = drawn ? strokeColor : strokeColor.withValues(alpha: 0.32);
      final painter = TextPainter(
        text: TextSpan(
          text: '${i + 1}',
          style: TextStyle(fontSize: 7.5, fontWeight: FontWeight.w700, color: numberColor, height: 1),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      painter.paint(canvas, start + const Offset(-6, -8));
    }
  }

  Offset? _strokeStart(Path path) {
    for (final metric in path.computeMetrics()) {
      return metric.getTangentForOffset(0)?.position;
    }
    return null;
  }

  Path _extractPartial(Path path, double fraction) {
    final metrics = path.computeMetrics().toList();
    final total = metrics.fold<double>(0, (sum, m) => sum + m.length);
    final target = total * fraction;
    final result = Path();
    var consumed = 0.0;
    for (final metric in metrics) {
      if (consumed + metric.length < target) {
        result.addPath(metric.extractPath(0, metric.length), Offset.zero);
        consumed += metric.length;
      } else {
        result.addPath(metric.extractPath(0, target - consumed), Offset.zero);
        break;
      }
    }
    return result;
  }

  @override
  bool shouldRepaint(covariant _StrokePainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.data != data;
}
