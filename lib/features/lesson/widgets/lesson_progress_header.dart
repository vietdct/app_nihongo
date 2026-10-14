import 'package:flutter/material.dart';

import '../../../core/theme/app_motion.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/motion/fade_switcher.dart';
import '../lesson_runner_steps.dart';

enum _SegmentState { done, active, upcoming }

/// Thanh tiến trình 5 đoạn (1 đoạn = 1 pha) thay cho % tổng quát — người học
/// biết "còn mấy pha nữa" thay vì phải hình dung "còn 40%". Xem mục 13 (UX
/// rationale) trong bản thiết kế Lesson Module.
class LessonProgressHeader extends StatelessWidget {
  const LessonProgressHeader({
    super.key,
    required this.currentPhase,
    required this.onBack,
  });

  final LessonPhase currentPhase;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 4, 20, 4),
        child: Row(
          children: [
            IconButton(
              onPressed: onBack,
              icon: const Icon(Icons.close_rounded),
              color: AppColors.inkSoft,
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      for (final phase in LessonPhase.values) ...[
                        Expanded(
                          child: _PhaseSegment(
                            phase: phase,
                            state: _segmentStateFor(phase),
                          ),
                        ),
                        if (phase != LessonPhase.values.last) const SizedBox(width: 4),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  // Nhãn pha mờ chuyển khi sang pha mới (key theo pha, rebuild
                  // cùng pha thì không chạy).
                  FadeSwitcher(
                    child: Text(
                      '${currentPhase.index + 1}/${LessonPhase.values.length} · ${phaseLabel(currentPhase)}',
                      key: ValueKey(currentPhase),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.4,
                        color: _PhaseSegment._colorOf(currentPhase),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  _SegmentState _segmentStateFor(LessonPhase phase) {
    if (phase.index < currentPhase.index) return _SegmentState.done;
    if (phase.index == currentPhase.index) return _SegmentState.active;
    return _SegmentState.upcoming;
  }
}

class _PhaseSegment extends StatelessWidget {
  const _PhaseSegment({required this.phase, required this.state});

  final LessonPhase phase;
  final _SegmentState state;

  static Color _colorOf(LessonPhase phase) => switch (phase) {
        LessonPhase.input => AppColors.phaseInput,
        LessonPhase.understand => AppColors.phaseUnderstand,
        LessonPhase.practice => AppColors.phasePractice,
        LessonPhase.apply => AppColors.phaseApply,
        LessonPhase.review => AppColors.phaseReview,
      };

  @override
  Widget build(BuildContext context) {
    final color = state == _SegmentState.upcoming ? AppColors.chip : _colorOf(phase);
    return AnimatedContainer(
      duration: AppMotion.resolve(context, AppMotion.emphasized),
      curve: AppMotion.curveSmooth,
      height: 6,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(100),
      ),
    );
  }
}
