import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../domain/entities/lesson.dart';
import '../../../shared/motion/enter_transition.dart';
import '../../../shared/motion/pop_in.dart';
import '../lesson_runner_steps.dart';

Color _phaseColor(LessonPhase phase) => switch (phase) {
      LessonPhase.input => AppColors.phaseInput,
      LessonPhase.understand => AppColors.phaseUnderstand,
      LessonPhase.practice => AppColors.phasePractice,
      LessonPhase.apply => AppColors.phaseApply,
      LessonPhase.review => AppColors.phaseReview,
    };

/// Số liệu đếm thật từ danh sách bước của pha vừa xong — không có điểm số vì
/// phiên học chưa lưu kết quả từng câu.
List<String> phaseSummaryLines(List<LessonStep> steps, LessonPhase phase) {
  final inPhase = steps.where((s) => phaseOfStep(s) == phase).toList();
  switch (phase) {
    case LessonPhase.input:
      return const [];
    case LessonPhase.understand:
      final items = inPhase.whereType<LessonUnderstandStep>().map((s) => s.item).toList();
      int n(LessonItemType t) => items.where((i) => i.type == t).length;
      return [
        'Đã xem ${items.length} thẻ',
        if (n(LessonItemType.vocabulary) > 0) 'Từ vựng: ${n(LessonItemType.vocabulary)}',
        if (n(LessonItemType.kanji) > 0) 'Kanji: ${n(LessonItemType.kanji)}',
        if (n(LessonItemType.grammar) > 0) 'Ngữ pháp: ${n(LessonItemType.grammar)}',
      ];
    case LessonPhase.practice:
      final listening = inPhase.whereType<LessonListeningStep>().length;
      final exercise = inPhase.whereType<LessonExerciseStep>().length;
      return [
        if (listening > 0) 'Câu nghe: $listening',
        if (exercise > 0) 'Câu luyện tập: $exercise',
      ];
    case LessonPhase.apply:
      return const ['Đã hoàn thành Mission hội thoại'];
    case LessonPhase.review:
      return const [];
  }
}

/// "Chốt chặng": hiện khi xong 1 pha, trả `true` nếu người học bấm sang pha
/// kế tiếp (null/false = đóng, ở lại bước hiện tại).
Future<bool?> showPhaseCompleteSheet(
  BuildContext context, {
  required LessonPhase done,
  required LessonPhase next,
  required List<String> lines,
}) {
  final color = _phaseColor(done);
  return showModalBottomSheet<bool>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (ctx) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 4, 24, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Chốt chặng vừa được xác nhận (sheet chỉ mở khi xong 1 pha):
                // check nảy một lần lúc sheet mở.
                PopIn(
                  child: Icon(Icons.check_circle_rounded, color: color, size: 28),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '${phaseLabel(done)} HOÀN THÀNH',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: color),
                  ),
                ),
              ],
            ),
            if (lines.isNotEmpty) ...[
              const SizedBox(height: 14),
              EnterTransition(
                offset: const Offset(0, 0.15),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final l in lines)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(l, style: const TextStyle(fontSize: 14.5, color: AppColors.ink)),
                      ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                child: Text('Sang ${phaseLabel(next)} →'),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
