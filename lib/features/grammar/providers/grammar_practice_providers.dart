import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/services/grammar_practice_generator.dart';
import '../../lesson/providers/content_providers.dart';

/// Sinh 1 phiên Practice mới mỗi lần vào màn (autoDispose) từ toàn bộ ngữ
/// pháp của cấp độ đang chọn — xem `generatePracticeSession`.
final grammarPracticeSessionProvider =
    Provider.autoDispose<AsyncValue<List<GrammarExercise>>>((ref) {
  final grammarAsync = ref.watch(grammarListProvider);
  return grammarAsync.whenData(
    (all) => generatePracticeSession(pool: all, exerciseCount: 10),
  );
});
