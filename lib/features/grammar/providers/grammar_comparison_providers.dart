import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/supabase_providers.dart';
import '../../../domain/entities/grammar_comparison_pair.dart';

/// Toàn bộ cặp ngữ pháp dễ nhầm — nội dung học liệu dùng chung (không phải
/// dữ liệu riêng theo người dùng), nhưng bảng nhỏ gần như tĩnh nên fetch
/// thẳng qua Supabase thay vì đi qua Drift offline cache như grammar_points
/// (tránh thêm bảng Drift + build_runner cho ~21 dòng quan hệ).
final grammarComparisonPairsProvider =
    FutureProvider<List<GrammarComparisonPair>>((ref) async {
  final sb = ref.watch(supabaseProvider);
  final rows = await sb.from('grammar_comparison_pairs').select();
  return [
    for (final r in rows)
      GrammarComparisonPair(
        id: r['id'] as String,
        grammarIdA: r['grammar_id_a'] as String,
        grammarIdB: r['grammar_id_b'] as String,
      ),
  ];
});
