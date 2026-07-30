import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/entities/grammar_point.dart';
import '../../../domain/services/shadowing_scorer.dart';
import '../../lesson/providers/content_providers.dart';

/// 1 phiên Shadowing mới mỗi lần vào màn (autoDispose) — câu luyện lấy từ
/// `grammar_points.example_jp` thật của cấp độ đang chọn, xem
/// `pickShadowingSentences`. Không sinh câu bằng AI (giữ tính năng miễn phí
/// token, xem trao đổi với người dùng trước khi làm đợt này).
final kaiwaShadowingSessionProvider = Provider.autoDispose<AsyncValue<List<GrammarPoint>>>((ref) {
  final grammarAsync = ref.watch(grammarListProvider);
  return grammarAsync.whenData((all) => pickShadowingSentences(all, count: 10));
});
