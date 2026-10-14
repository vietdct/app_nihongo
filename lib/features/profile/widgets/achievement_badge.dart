import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/app_motion.dart';
import '../../../core/theme/app_theme.dart';

/// Huy hiệu trong lưới Thành tích. [celebrate] = true chỉ khi bộ theo dõi
/// (`AchievementUnlockTracker`) xác định huy hiệu này VỪA mở khóa trong phiên:
/// khi đó nảy nhẹ + quầng sáng mờ dần đúng MỘT lần (mỗi State), không lặp khi
/// rebuild/đổi theme. Không có hiệu ứng liên tục; giảm chuyển động → bỏ qua.
class AchievementBadge extends StatefulWidget {
  const AchievementBadge({
    super.key,
    required this.earned,
    required this.icon,
    required this.label,
    required this.sub,
    this.celebrate = false,
  });

  final bool earned;
  final IconData icon;
  final String label;
  final String sub;
  final bool celebrate;

  @override
  State<AchievementBadge> createState() => _AchievementBadgeState();
}

class _AchievementBadgeState extends State<AchievementBadge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );
  bool _played = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _maybePlay();
  }

  @override
  void didUpdateWidget(AchievementBadge old) {
    super.didUpdateWidget(old);
    _maybePlay();
  }

  void _maybePlay() {
    if (_played || !widget.celebrate || !widget.earned) return;
    _played = true;
    if (!AppMotion.reduced(context)) _controller.forward(from: 0);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final earned = widget.earned;
    return SizedBox(
      width: 72,
      child: Column(
        children: [
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              final t = _controller.value;
              final pop = math.sin(Curves.easeOut.transform(t) * math.pi);
              return Transform.scale(
                scale: 1 + 0.18 * pop,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: t == 0 || t == 1
                        ? null
                        : [
                            BoxShadow(
                              color: AppColors.accent
                                  .withValues(alpha: 0.45 * (1 - t)),
                              blurRadius: 14,
                              spreadRadius: 3 * (1 - t),
                            ),
                          ],
                  ),
                  child: child,
                ),
              );
            },
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: earned ? AppColors.accentSoft : AppColors.chip,
                borderRadius: BorderRadius.circular(16),
                border: earned
                    ? null
                    : Border.all(
                        color: AppColors.border,
                        width: 2,
                        style: BorderStyle.solid,
                      ),
              ),
              alignment: Alignment.center,
              child: Icon(
                widget.icon,
                size: 22,
                color: earned ? AppColors.accentStrong : AppColors.inkFaint,
              ),
            ),
          ),
          const SizedBox(height: 5),
          Text(
            widget.label,
            textAlign: TextAlign.center,
            maxLines: 1,
            style: const TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              color: AppColors.ink,
            ),
          ),
          Text(
            widget.sub,
            textAlign: TextAlign.center,
            maxLines: 1,
            style: const TextStyle(fontSize: 8, color: AppColors.inkSoft),
          ),
        ],
      ),
    );
  }
}
