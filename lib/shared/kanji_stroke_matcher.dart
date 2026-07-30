import 'dart:math' as math;
import 'dart:ui';

import '../domain/entities/kanji.dart';
import 'kanji_stroke_canvas.dart';

/// 1 kết quả khớp: kanji ứng viên + điểm lệch so với nét người dùng vừa vẽ
/// (càng thấp càng khớp).
class KanjiDrawMatch {
  const KanjiDrawMatch(this.kanji, this.score);

  final Kanji kanji;
  final double score;
}

const int _resampleCount = 24;

/// So khớp các nét người dùng vừa vẽ (mỗi nét là 1 danh sách điểm chạm liên
/// tục) với dữ liệu nét chuẩn (KanjiVG) của từng kanji ứng viên, theo đúng
/// thứ tự viết. Gọi lại sau mỗi nét mới để thu hẹp kết quả dần — không cần
/// vẽ xong cả chữ mới có gợi ý, giống kiểu gõ tìm kiếm dần dần.
List<KanjiDrawMatch> matchKanjiByStrokes({
  required List<List<Offset>> drawnStrokes,
  required List<Kanji> candidates,
  int topN = 12,
}) {
  if (drawnStrokes.isEmpty) return const [];
  final drawnCount = drawnStrokes.length;
  final normalizedDrawn = [
    for (final s in drawnStrokes) _normalize(_resamplePolyline(s, _resampleCount)),
  ];

  final scored = <KanjiDrawMatch>[];
  for (final kanji in candidates) {
    final data = KanjiStrokeData.tryParse(kanji.strokeData);
    if (data == null || data.strokes.length < drawnCount) continue;

    var total = 0.0;
    for (var i = 0; i < drawnCount; i++) {
      final refPoints = _normalize(_resamplePolyline(_pathToPolyline(data.strokes[i]), _resampleCount));
      total += _pointDistance(normalizedDrawn[i], refPoints);
    }
    final avg = total / drawnCount;
    // Ưu tiên nhẹ kanji có tổng số nét gần với số nét đã vẽ — nếu người
    // dùng vừa vẽ xong, khả năng cao đó chính là tổng số nét của chữ.
    final countPenalty = (data.strokes.length - drawnCount) * 0.01;
    scored.add(KanjiDrawMatch(kanji, avg + countPenalty));
  }

  scored.sort((a, b) => a.score.compareTo(b.score));
  return scored.take(topN).toList();
}

/// Kết quả chấm 1 lượt luyện viết so với ĐÚNG 1 kanji mục tiêu đã biết
/// (khác [matchKanjiByStrokes] là tìm trong nhiều ứng viên). [accuracy] là
/// chỉ số hình học thuần tuý (khoảng cách điểm-tới-điểm sau chuẩn hoá, quy
/// đổi tuyến tính về 0-1) — KHÔNG phải OCR/AI chấm chữ viết tay thật, chỉ nên
/// hiển thị như "độ khớp nét vẽ", không gọi là "AI chấm điểm" để không phóng
/// đại độ chính xác.
class KanjiPracticeResult {
  const KanjiPracticeResult({
    required this.strokeCountMatches,
    required this.accuracy,
  });

  final bool strokeCountMatches;
  final double accuracy;
}

// Khoảng cách chuẩn hoá trung bình quan sát được dao động ~0 (khớp gần như
// hoàn hảo) tới ~0.4+ (lệch nhiều/sai hình dạng) — dùng làm mốc quy đổi sang
// thang 0-1 để hiển thị phần trăm dễ hiểu, không phải số liệu tuyệt đối.
const double _maxExpectedDistance = 0.4;

/// So khớp nét vừa vẽ với dữ liệu nét chuẩn của [target]. Trả về `null` nếu
/// [target] chưa có `strokeData` hoặc người dùng chưa vẽ nét nào.
KanjiPracticeResult? scoreKanjiPractice({
  required List<List<Offset>> drawnStrokes,
  required Kanji target,
}) {
  final data = KanjiStrokeData.tryParse(target.strokeData);
  if (data == null || drawnStrokes.isEmpty) return null;

  final n = math.min(drawnStrokes.length, data.strokes.length);
  var total = 0.0;
  for (var i = 0; i < n; i++) {
    final drawn = _normalize(_resamplePolyline(drawnStrokes[i], _resampleCount));
    final ref = _normalize(
      _resamplePolyline(_pathToPolyline(data.strokes[i]), _resampleCount),
    );
    total += _pointDistance(drawn, ref);
  }
  final avgDistance = total / n;
  final accuracy = (1 - (avgDistance / _maxExpectedDistance)).clamp(0.0, 1.0);

  return KanjiPracticeResult(
    strokeCountMatches: drawnStrokes.length == data.strokes.length,
    accuracy: accuracy,
  );
}

List<Offset> _pathToPolyline(Path path, {int samples = 48}) {
  final metrics = path.computeMetrics().toList();
  final total = metrics.fold<double>(0, (s, m) => s + m.length);
  if (total == 0 || metrics.isEmpty) return const [Offset.zero];
  return [for (var i = 0; i < samples; i++) _pointAt(metrics, total * i / (samples - 1))];
}

Offset _pointAt(List<PathMetric> metrics, double target) {
  var consumed = 0.0;
  for (final m in metrics) {
    if (target <= consumed + m.length || m == metrics.last) {
      final local = (target - consumed).clamp(0.0, m.length);
      final tangent = m.getTangentForOffset(local);
      if (tangent != null) return tangent.position;
    }
    consumed += m.length;
  }
  return Offset.zero;
}

/// Lấy lại mẫu 1 đường gấp khúc (polyline) thành đúng [n] điểm cách đều
/// nhau theo chiều dài — để 2 nét có số điểm khác nhau vẫn so sánh được.
List<Offset> _resamplePolyline(List<Offset> points, int n) {
  if (points.length < 2) {
    return List.filled(n, points.isEmpty ? Offset.zero : points.first);
  }
  final lengths = <double>[0];
  for (var i = 1; i < points.length; i++) {
    lengths.add(lengths.last + (points[i] - points[i - 1]).distance);
  }
  final total = lengths.last;
  if (total == 0) return List.filled(n, points.first);

  final result = <Offset>[];
  var segIndex = 0;
  for (var i = 0; i < n; i++) {
    final target = total * i / (n - 1);
    while (segIndex < lengths.length - 2 && lengths[segIndex + 1] < target) {
      segIndex++;
    }
    final segStart = lengths[segIndex];
    final segEnd = lengths[segIndex + 1];
    final segLen = segEnd - segStart;
    final t = segLen == 0 ? 0.0 : ((target - segStart) / segLen).clamp(0.0, 1.0);
    result.add(Offset.lerp(points[segIndex], points[segIndex + 1], t)!);
  }
  return result;
}

/// Đưa các điểm về khung [0,1] (giữ đúng tỉ lệ) để so sánh được nét vẽ nhỏ
/// trên điện thoại với nét chuẩn theo toạ độ KanjiVG (0-109).
List<Offset> _normalize(List<Offset> points) {
  var minX = double.infinity, minY = double.infinity;
  var maxX = -double.infinity, maxY = -double.infinity;
  for (final p in points) {
    minX = math.min(minX, p.dx);
    minY = math.min(minY, p.dy);
    maxX = math.max(maxX, p.dx);
    maxY = math.max(maxY, p.dy);
  }
  final scale = math.max(maxX - minX, maxY - minY);
  if (scale == 0) return points.map((_) => Offset.zero).toList();
  return points.map((p) => Offset((p.dx - minX) / scale, (p.dy - minY) / scale)).toList();
}

double _pointDistance(List<Offset> a, List<Offset> b) {
  var sum = 0.0;
  for (var i = 0; i < a.length; i++) {
    sum += (a[i] - b[i]).distance;
  }
  return sum / a.length;
}
