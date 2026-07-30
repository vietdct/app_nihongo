import 'dart:math';

import '../entities/grammar_point.dart';

/// Chọn ngẫu nhiên tối đa [count] mẫu ngữ pháp có câu ví dụ thật
/// (`exampleJp`) từ [pool] để luyện Shadowing — mẫu chưa soạn ví dụ bị loại,
/// không bịa câu đọc.
List<GrammarPoint> pickShadowingSentences(
  List<GrammarPoint> pool, {
  int count = 10,
  Random? random,
}) {
  final eligible = pool.where((g) => (g.exampleJp ?? '').trim().isNotEmpty).toList()
    ..shuffle(random ?? Random());
  return eligible.take(count).toList();
}

/// Chấm điểm Shadowing bằng độ khớp văn bản thuần (không gọi AI — câu nhận
/// diện được từ speech_to_text so với câu mẫu thật, tính theo khoảng cách
/// Levenshtein ở mức ký tự vì tiếng Nhật không có khoảng trắng giữa từ).
/// Không đo được pitch/rhythm/ngữ điệu thật — đây là giới hạn đã biết, không
/// giả vờ là "phân tích phát âm" đầy đủ.
int computeShadowingScore(String target, String recognized) {
  final a = _normalize(target);
  final b = _normalize(recognized);
  if (a.isEmpty) return 0;
  if (b.isEmpty) return 0;

  final distance = _levenshtein(a, b);
  final maxLen = a.length > b.length ? a.length : b.length;
  final score = ((maxLen - distance) / maxLen * 100).round();
  return score.clamp(0, 100);
}

final _stripPattern = RegExp(r'[。、！？!?.,「」『』・\s]');

String _normalize(String input) => input.replaceAll(_stripPattern, '');

int _levenshtein(String a, String b) {
  final m = a.length;
  final n = b.length;
  if (m == 0) return n;
  if (n == 0) return m;

  var previous = List<int>.generate(n + 1, (j) => j);
  var current = List<int>.filled(n + 1, 0);

  for (var i = 1; i <= m; i++) {
    current[0] = i;
    for (var j = 1; j <= n; j++) {
      final cost = a[i - 1] == b[j - 1] ? 0 : 1;
      final deletion = previous[j] + 1;
      final insertion = current[j - 1] + 1;
      final substitution = previous[j - 1] + cost;
      current[j] = [deletion, insertion, substitution].reduce((x, y) => x < y ? x : y);
    }
    final swap = previous;
    previous = current;
    current = swap;
  }
  return previous[n];
}
