import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:path_drawing/path_drawing.dart';

import '../core/theme/app_theme.dart';

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
    this.numberColor = AppColors.accentStrong,
  });

  final String character;
  final KanjiStrokeData? strokeData;
  final double size;
  final Color strokeColor;
  final Color guideColor;
  final Color numberColor;

  @override
  State<KanjiStrokeCanvas> createState() => KanjiStrokeCanvasState();
}

class KanjiStrokeCanvasState extends State<KanjiStrokeCanvas> with SingleTickerProviderStateMixin {
  static const _perStroke = Duration(milliseconds: 420);

  late final AnimationController _controller;
  _NumberLayout? _layout;
  String? _layoutFor;
  bool _showNumbers = true;

  _NumberLayout? _numberLayout() {
    final data = widget.strokeData;
    if (data == null) return null;
    if (_layout == null || _layoutFor != widget.character) {
      _layout = _NumberLayout.compute(data);
      _layoutFor = widget.character;
    }
    return _layout;
  }

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
          : Stack(
              children: [
                Positioned.fill(
                  child: AnimatedBuilder(
                    animation: _controller,
                    builder: (context, _) => CustomPaint(
                      painter: _StrokePainter(
                        data: data,
                        progress: _controller.value * data.strokes.length,
                        layout: _numberLayout()!,
                        showNumbers: _showNumbers,
                        numberColor: widget.numberColor,
                        strokeColor: widget.strokeColor,
                        guideColor: widget.guideColor,
                      ),
                    ),
                  ),
                ),
                if (widget.size >= 140)
                  Positioned(
                    right: 2,
                    bottom: 2,
                    child: Tooltip(
                      message: _showNumbers ? 'Ẩn số thứ tự nét' : 'Hiện số thứ tự nét',
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: () => setState(() => _showNumbers = !_showNumbers),
                        child: Padding(
                          padding: const EdgeInsets.all(6),
                          child: Icon(
                            Icons.pin_outlined,
                            size: 20,
                            color: _showNumbers ? widget.numberColor : widget.strokeColor.withValues(alpha: 0.35),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}

/// Vị trí số thứ tự của từng nét: gần điểm bắt đầu nét nhất nhưng không đè
/// lên nét chữ và không chồng lên số khác. Tính 1 lần cho mỗi chữ.
class _NumberLayout {
  _NumberLayout(this.starts, this.centers);

  final List<Offset?> starts;
  final List<Offset?> centers;

  static const _strokeHalf = 1.7;
  static const _step = 1.5;
  static const _reach = 14.0;

  /// Bán kính vùng chiếm chỗ của số (1 chữ số nhỏ hơn 2 chữ số).
  static double radiusOf(int index) => index < 9 ? 3.0 : 4.0;

  static _NumberLayout compute(KanjiStrokeData data) {
    final box = data.viewBox;
    final samples = <Offset>[];
    final starts = <Offset?>[];
    for (final path in data.strokes) {
      Offset? start;
      for (final metric in path.computeMetrics()) {
        start ??= metric.getTangentForOffset(0)?.position;
        for (var d = 0.0; d < metric.length; d += 2) {
          final t = metric.getTangentForOffset(d);
          if (t != null) samples.add(t.position);
        }
        final end = metric.getTangentForOffset(metric.length);
        if (end != null) samples.add(end.position);
      }
      starts.add(start);
    }

    double clearance(Offset c) {
      var best = double.infinity;
      for (final p in samples) {
        final dx = p.dx - c.dx;
        final dy = p.dy - c.dy;
        final d2 = dx * dx + dy * dy;
        if (d2 < best) best = d2;
      }
      return math.sqrt(best) - _strokeHalf;
    }

    final centers = <Offset?>[];
    final placed = <(Offset, double)>[];
    for (var i = 0; i < starts.length; i++) {
      final start = starts[i];
      if (start == null) {
        centers.add(null);
        continue;
      }
      final r = radiusOf(i);
      final candidates = <(Offset, double, double)>[];
      for (var dx = -_reach; dx <= _reach; dx += _step) {
        for (var dy = -_reach; dy <= _reach; dy += _step) {
          final c = start + Offset(dx, dy);
          if (c.dx < r || c.dy < r) continue;
          if (c.dx > box - r || c.dy > box - r) continue;
          if (placed.any((q) => (q.$1 - c).distance < q.$2 + r + 0.6)) continue;
          candidates.add((c, (c - start).distance, clearance(c)));
        }
      }
      // Số có viền trắng nên chịu được chạm nhẹ mép nét: ưu tiên chỗ gần điểm
      // bắt đầu, hạ dần yêu cầu khoảng cách tới nét nếu chữ quá dày.
      Offset? chosen;
      for (final need in [r - 0.4, r - 1.4, r - 2.4, 0.0]) {
        double? bestDist;
        for (final (c, dist, clear) in candidates) {
          if (clear < need) continue;
          if (bestDist == null || dist < bestDist) {
            bestDist = dist;
            chosen = c;
          }
        }
        if (chosen != null) break;
      }
      chosen ??= start;
      placed.add((chosen, r));
      centers.add(chosen);
    }
    return _NumberLayout(starts, centers);
  }
}

class _StrokePainter extends CustomPainter {
  _StrokePainter({
    required this.data,
    required this.progress,
    required this.layout,
    required this.showNumbers,
    required this.numberColor,
    required this.strokeColor,
    required this.guideColor,
  });

  final KanjiStrokeData data;
  final _NumberLayout layout;
  final bool showNumbers;
  final Color numberColor;
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

    // Số thứ tự: chỉ hiện cho nét đã/đang vẽ, dạng chữ số cam có viền trắng đặt
    // ở chỗ trống cạnh điểm bắt đầu nét (xem _NumberLayout); nét đang vẽ có ô
    // cam nổi bật để biết đang tới đâu. Không vẽ số cho nét chưa tới nên nhìn gọn.
    if (!showNumbers) return;
    for (var i = 0; i < data.strokes.length; i++) {
      final start = layout.starts[i];
      final center = layout.centers[i];
      if (start == null || center == null) continue;
      final current = i == completeCount && currentFraction > 0;
      if (i >= completeCount && !current) continue;

      final r = _NumberLayout.radiusOf(i);
      if ((center - start).distance > 9) {
        final toStart = (start - center) / (start - center).distance;
        canvas.drawLine(
          center + toStart * r,
          start,
          Paint()
            ..color = numberColor.withValues(alpha: 0.4)
            ..strokeWidth = 0.5,
        );
      }
      final fontSize = i >= 9 ? 5.6 : 6.6;
      TextPainter label(Paint? foreground, Color? color) => TextPainter(
            text: TextSpan(
              text: '${i + 1}',
              style: TextStyle(
                fontSize: fontSize,
                fontWeight: FontWeight.w800,
                height: 1,
                color: color,
                foreground: foreground,
              ),
            ),
            textDirection: TextDirection.ltr,
          )..layout();

      if (current) {
        canvas.drawCircle(center, r + 1.0, Paint()..color = numberColor);
        final text = label(null, Colors.white);
        text.paint(canvas, center - Offset(text.width / 2, text.height / 2));
      } else {
        final halo = label(
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.8
            ..strokeJoin = StrokeJoin.round
            ..color = Colors.white,
          null,
        );
        final text = label(null, numberColor);
        final at = center - Offset(text.width / 2, text.height / 2);
        halo.paint(canvas, at);
        text.paint(canvas, at);
      }
    }
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
      oldDelegate.progress != progress ||
      oldDelegate.data != data ||
      oldDelegate.showNumbers != showNumbers;
}
