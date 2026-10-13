import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import 'kanji_stroke_canvas.dart';

/// Bảng vẽ nét chữ Hán bằng ngón tay. Ghi lại từng nét thành danh sách điểm
/// chạm; báo [onStrokesChanged] mỗi khi nhấc tay (hết 1 nét) để tầng trên xử
/// lý dần — dùng cho cả vẽ-để-tìm-kiếm (không cần vẽ xong cả chữ mới có gợi
/// ý) và luyện viết (truyền [guideData] để hiện nét mẫu mờ làm nền).
class KanjiDrawCanvas extends StatefulWidget {
  const KanjiDrawCanvas({
    super.key,
    required this.onStrokesChanged,
    this.size = 280,
    this.guideData,
  });

  final ValueChanged<List<List<Offset>>> onStrokesChanged;
  final double size;
  final KanjiStrokeData? guideData;

  @override
  State<KanjiDrawCanvas> createState() => KanjiDrawCanvasState();
}

class KanjiDrawCanvasState extends State<KanjiDrawCanvas> {
  static const _minPointDistanceSquared = 1.5;

  final List<List<Offset>> _strokes = [];
  final List<Path> _completedPaths = [];
  final ValueNotifier<int> _inkRevision = ValueNotifier(0);
  List<Offset>? _current;
  Path? _currentPath;
  ui.Picture? _baseLayer;

  bool get isEmpty => _strokes.isEmpty;

  @override
  void initState() {
    super.initState();
    _rebuildBaseLayer();
  }

  @override
  void didUpdateWidget(covariant KanjiDrawCanvas oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.size != widget.size ||
        oldWidget.guideData != widget.guideData) {
      _rebuildBaseLayer();
    }
  }

  @override
  void dispose() {
    _baseLayer?.dispose();
    _inkRevision.dispose();
    super.dispose();
  }

  void undoStroke() {
    if (_strokes.isEmpty) return;
    _strokes.removeLast();
    _completedPaths.removeLast();
    _rebuildBaseLayer();
    setState(() {});
    widget.onStrokesChanged(List.of(_strokes));
  }

  void clear() {
    _strokes.clear();
    _completedPaths.clear();
    _current = null;
    _currentPath = null;
    _rebuildBaseLayer();
    setState(() {});
    widget.onStrokesChanged(const []);
  }

  void _startStroke(DragStartDetails details) {
    final point = details.localPosition;
    setState(() {
      _current = [point];
      _currentPath = Path()..moveTo(point.dx, point.dy);
    });
  }

  void _extendStroke(DragUpdateDetails details) {
    final points = _current;
    final path = _currentPath;
    if (points == null || path == null) return;

    final point = details.localPosition;
    if ((point - points.last).distanceSquared < _minPointDistanceSquared) {
      return;
    }
    points.add(point);
    path.lineTo(point.dx, point.dy);
    // Không rebuild widget cho từng pointer event; CustomPainter chỉ repaint
    // lớp nét đang viết, còn lưới/nét mẫu/nét hoàn thành đã được cache.
    _inkRevision.value++;
  }

  void _finishStroke() {
    final stroke = _current;
    final path = _currentPath;
    if (stroke != null && path != null && stroke.length > 1) {
      _strokes.add(stroke);
      _completedPaths.add(path);
      _current = null;
      _currentPath = null;
      _rebuildBaseLayer();
      setState(() {});
      widget.onStrokesChanged(List.of(_strokes));
    } else {
      setState(() {
        _current = null;
        _currentPath = null;
      });
    }
  }

  void _rebuildBaseLayer() {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final size = Size.square(widget.size);
    _drawBase(canvas, size, widget.guideData, _completedPaths);
    final oldLayer = _baseLayer;
    _baseLayer = recorder.endRecording();
    oldLayer?.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanStart: _startStroke,
      onPanUpdate: _extendStroke,
      onPanEnd: (_) => _finishStroke(),
      onPanCancel: _finishStroke,
      child: Container(
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border, width: 0.6),
        ),
        clipBehavior: Clip.antiAlias,
        child: RepaintBoundary(
          child: CustomPaint(
            painter: _InkPainter(
              baseLayer: _baseLayer!,
              currentPath: _currentPath,
              repaint: _inkRevision,
            ),
            size: Size.square(widget.size),
          ),
        ),
      ),
    );
  }
}

class _InkPainter extends CustomPainter {
  _InkPainter({
    required this.baseLayer,
    required this.currentPath,
    required Listenable repaint,
  }) : super(repaint: repaint);

  final ui.Picture baseLayer;
  final Path? currentPath;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawPicture(baseLayer);
    final inkPaint = Paint()
      ..color = AppColors.ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = 7
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = currentPath;
    if (path != null) canvas.drawPath(path, inkPaint);
  }

  @override
  bool shouldRepaint(covariant _InkPainter oldDelegate) =>
      oldDelegate.baseLayer != baseLayer ||
      oldDelegate.currentPath != currentPath;
}

void _drawBase(
  Canvas canvas,
  Size size,
  KanjiStrokeData? guideData,
  List<Path> completedPaths,
) {
  final guidePaint = Paint()
    ..color = AppColors.border
    ..strokeWidth = 1;
  canvas.drawLine(
    Offset(size.width / 2, 0),
    Offset(size.width / 2, size.height),
    guidePaint,
  );
  canvas.drawLine(
    Offset(0, size.height / 2),
    Offset(size.width, size.height / 2),
    guidePaint,
  );

  final data = guideData;
  if (data != null) {
    canvas.save();
    final scale = size.width / data.viewBox;
    canvas.scale(scale, scale);
    final referencePaint = Paint()
      ..color = AppColors.ink.withValues(alpha: 0.14)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    for (final stroke in data.strokes) {
      canvas.drawPath(stroke, referencePaint);
    }
    canvas.restore();
  }

  final inkPaint = Paint()
    ..color = AppColors.ink
    ..style = PaintingStyle.stroke
    ..strokeWidth = 7
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;
  for (final path in completedPaths) {
    canvas.drawPath(path, inkPaint);
  }
}
