import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/entities/vocab_progress.dart';
import '../../../domain/entities/vocabulary.dart';
import '../../lesson/providers/content_providers.dart';
import 'vocab_progress_providers.dart';

/// Lý do 1 từ đang nằm trong hàng đợi ôn tập, ưu tiên theo mức khẩn cấp giảm
/// dần (dùng để sắp xếp hàng đợi) — xem `classifyVocabReview`.
enum VocabReviewReason { forgotten, overdue, weak, due }

/// 1 mục trong hàng đợi ôn tập: từ vựng thật kèm lý do đang due.
class VocabReviewItem {
  const VocabReviewItem({required this.vocab, required this.reason});

  final Vocabulary vocab;
  final VocabReviewReason reason;
}

const _overdueThresholdDays = 2;
const _weakEaseThreshold = 2.0;

/// Phân loại 1 từ thành 1 trong 4 lý do due, thuần từ field SRS có sẵn trên
/// [VocabProgress] (không cần schema mới), ưu tiên theo mức khẩn cấp:
/// - [VocabReviewReason.forgotten]: đã ôn ít nhất 1 lần và lượt gần nhất bị
///   đánh "quên" — SRS reset `intervalDays` về 1 ngày (xem `computeNextSchedule`).
/// - [VocabReviewReason.overdue]: đã quá hạn ôn từ [_overdueThresholdDays]
///   ngày trở lên.
/// - [VocabReviewReason.weak]: ease factor thấp hơn mặc định (2.5) đáng kể —
///   từ khó nhớ hơn trung bình dù chưa quá hạn lâu.
/// - [VocabReviewReason.due]: các trường hợp còn lại, kể cả từ chưa từng ôn.
VocabReviewReason classifyVocabReview(VocabProgress? progress, {DateTime? now}) {
  if (progress == null) return VocabReviewReason.due;

  if (progress.reviewCount > 0 && progress.intervalDays <= 1) {
    return VocabReviewReason.forgotten;
  }

  final dueAt = progress.dueAt;
  if (dueAt != null && (now ?? DateTime.now()).difference(dueAt).inDays >= _overdueThresholdDays) {
    return VocabReviewReason.overdue;
  }

  if (progress.easeFactor < _weakEaseThreshold) {
    return VocabReviewReason.weak;
  }

  return VocabReviewReason.due;
}

/// Hàng đợi ôn tập thật — chỉ những từ đã tới/qua hạn
/// ([VocabProgress.isDueNow], từ chưa từng ôn cũng tính là due), gắn kèm lý
/// do due và sắp theo mức khẩn cấp giảm dần để màn Review ưu tiên đúng.
final vocabReviewQueueProvider = FutureProvider.autoDispose<List<VocabReviewItem>>((ref) async {
  final vocab = await ref.watch(vocabularyListProvider.future);
  final progress = await ref.watch(vocabProgressProvider.future);

  final items = [
    for (final v in vocab)
      if (progress[v.id]?.isDueNow ?? true)
        VocabReviewItem(vocab: v, reason: classifyVocabReview(progress[v.id])),
  ];
  items.sort((a, b) => a.reason.index.compareTo(b.reason.index));
  return items;
});
