import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_motion.dart';
import '../../../core/theme/app_theme.dart';
import '../providers/progress_change_providers.dart';

/// Viền sáng nhẹ quanh thẻ streak MỘT lần khi streak vừa đạt mốc 3/7/30 giữa
/// hai snapshot thành công (xác nhận bởi [ProgressChangeTracker]). Không modal,
/// không chặn chạm, không cộng XP/huy hiệu.
///
/// Chỉ chạy khi thẻ đang hiển thị — sự kiện chưa hiển thị được giữ lại tới khi
/// hiển thị; bật "Giảm chuyển động" thì nhận sự kiện nhưng không phát hiệu ứng.
/// [child] luôn là phần tử đầu của Stack nên không bị dựng lại.
class StreakMilestoneGlow extends ConsumerStatefulWidget {
  const StreakMilestoneGlow({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<StreakMilestoneGlow> createState() =>
      _StreakMilestoneGlowState();
}

class _StreakMilestoneGlowState extends ConsumerState<StreakMilestoneGlow>
    with SingleTickerProviderStateMixin {
  AnimationController? _glow;
  bool _consumeScheduled = false;
  bool _reduced = false;

  void _scheduleConsume() {
    if (_consumeScheduled) return;
    _consumeScheduled = true;
    SchedulerBinding.instance
      ..addPostFrameCallback((_) => _consume())
      ..ensureVisualUpdate();
  }

  void _consume() {
    _consumeScheduled = false;
    if (!mounted) return;
    final milestone =
        ref.read(progressChangeTrackerProvider.notifier).takeMilestone();
    if (milestone == null || _reduced) return;
    setState(() {
      (_glow ??= AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 600),
      ))
          .forward(from: 0);
    });
  }

  @override
  void dispose() {
    _glow?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _reduced = AppMotion.reduced(context);
    final pending = ref.watch(
      progressChangeTrackerProvider.select((e) => e.milestone != null),
    );
    // TickerMode tắt = tab/route đang che: giữ sự kiện tới khi hiển thị lại.
    if (pending && TickerMode.valuesOf(context).enabled) _scheduleConsume();

    final glow = _glow;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        widget.child,
        if (glow != null)
          Positioned.fill(
            child: IgnorePointer(
              child: AnimatedBuilder(
                animation: glow,
                builder: (context, _) {
                  // Lên rồi xuống một nhịp (0 → 1 → 0).
                  final t = math.sin(glow.value * math.pi);
                  // Hết nhịp (hoặc chưa bắt đầu): không còn lớp phủ nào.
                  if (!glow.isAnimating || t <= 0.001) {
                    return const SizedBox.shrink();
                  }
                  return DecoratedBox(
                    key: const ValueKey('streak-milestone-glow'),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.9 * t),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.accent.withValues(alpha: 0.55 * t),
                          blurRadius: 14 * t,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
      ],
    );
  }
}
