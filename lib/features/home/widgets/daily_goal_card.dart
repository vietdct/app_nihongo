import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_motion.dart';
import '../../../core/theme/app_theme.dart';
import '../providers/progress_change_providers.dart';

/// Thẻ "mục tiêu hôm nay" + chấm tuần trên Home — theo bố cục mockup nhưng
/// trung thực với dữ liệu thật: app chưa có bộ đếm "số thẻ đã học hôm nay"
/// nên vòng tròn chỉ hiện viền rỗng (không tô cung, không bịa phân số). 7
/// chấm tuần nối [studyDays] thật (bảng `study_days`, cùng nguồn với heatmap
/// Thành tích ở Profile) — null nghĩa là đang tải, chưa có nghĩa là chưa học.
///
/// Ô ngày học MỚI (xác nhận bởi [ProgressChangeTracker] từ hai snapshot thành
/// công trong phiên) hiện tick bằng fade ngắn đúng một lần; mọi ô khác giữ
/// nguyên. Hiệu ứng chỉ chạy khi thẻ đang hiển thị (sự kiện chưa hiển thị
/// được giữ lại), và bỏ qua khi bật "Giảm chuyển động".
class DailyGoalCard extends ConsumerStatefulWidget {
  const DailyGoalCard({super.key, required this.studyDays});

  final Set<DateTime>? studyDays;

  static const _weekLabels = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];

  @override
  ConsumerState<DailyGoalCard> createState() => _DailyGoalCardState();
}

class _DailyGoalCardState extends ConsumerState<DailyGoalCard> {
  /// Ngày đang chạy hiệu ứng tick (tối đa 7, mỗi ô chỉ chạy 1 lần).
  final Set<DateTime> _celebrating = {};
  bool _consumeScheduled = false;
  bool _reduced = false;

  Set<DateTime>? get studyDays => widget.studyDays;

  List<DateTime> _weekDays() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final monday = today.subtract(Duration(days: today.weekday - 1));
    return List.generate(7, (i) => monday.add(Duration(days: i)));
  }

  void _scheduleConsume() {
    if (_consumeScheduled) return;
    _consumeScheduled = true;
    SchedulerBinding.instance
      ..addPostFrameCallback((_) => _consume())
      ..ensureVisualUpdate();
  }

  /// Nhận sự kiện ngày mới khỏi hàng chờ rồi phát hiệu ứng. Không đặt trong
  /// `build` (đổi state provider khi đang dựng là sai); chỉ chạy khi thẻ đang
  /// hiển thị.
  void _consume() {
    _consumeScheduled = false;
    if (!mounted) return;
    final days = ref.read(progressChangeTrackerProvider.notifier).takeNewDays();
    if (days.isEmpty || _reduced) return; // giảm chuyển động: nhận & bỏ qua
    final week = _weekDays().toSet();
    final mine = days.where(week.contains).toSet();
    if (mine.isNotEmpty) setState(() => _celebrating.addAll(mine));
  }

  @override
  Widget build(BuildContext context) {
    _reduced = AppMotion.reduced(context);
    final pending = ref.watch(
      progressChangeTrackerProvider.select((e) => e.newDays.isNotEmpty),
    );
    // TickerMode tắt = tab/route đang che thẻ: giữ sự kiện, đợi hiển thị lại.
    if (pending && TickerMode.valuesOf(context).enabled) _scheduleConsume();

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final monday = today.subtract(Duration(days: today.weekday - 1));
    final todayWeekday = now.weekday; // 1=T2 ... 7=CN, khớp thứ tự _weekLabels
    final completedThisWeek = studyDays == null
        ? null
        : List.generate(7, (i) => monday.add(Duration(days: i)))
            .where(studyDays!.contains)
            .length;
    const weekLabels = DailyGoalCard._weekLabels;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? const [Color(0xFF162124), Color(0xFF101719)]
              : const [Colors.white, Color(0xFFFFFBF5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border, width: 1.0),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF9B6A43).withValues(alpha: 0.07),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Nhịp học tuần này',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: AppColors.ink,
                ),
              ),
              if (completedThisWeek != null)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.mossSoft,
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: Text(
                    '$completedThisWeek/7',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: AppColors.moss,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              for (var i = 0; i < 7; i++)
                _WeekDot(
                  label: weekLabels[i],
                  isToday: i + 1 == todayWeekday,
                  done: studyDays?.contains(monday.add(Duration(days: i))) ??
                      false,
                  celebrate:
                      _celebrating.contains(monday.add(Duration(days: i))),
                  onCelebrated: () {
                    if (mounted) {
                      setState(
                        () =>
                            _celebrating.remove(monday.add(Duration(days: i))),
                      );
                    }
                  },
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _WeekDot extends StatefulWidget {
  const _WeekDot({
    required this.label,
    required this.isToday,
    required this.done,
    required this.celebrate,
    required this.onCelebrated,
  });

  final String label;
  final bool isToday;
  final bool done;

  /// true khi ngày này vừa được xác nhận là ngày học MỚI: phát fade tick một
  /// lần (cạnh lên false→true). Controller chỉ tạo khi thật sự cần.
  final bool celebrate;
  final VoidCallback onCelebrated;

  @override
  State<_WeekDot> createState() => _WeekDotState();
}

class _WeekDotState extends State<_WeekDot>
    with SingleTickerProviderStateMixin {
  AnimationController? _fade;

  @override
  void didUpdateWidget(covariant _WeekDot old) {
    super.didUpdateWidget(old);
    if (widget.celebrate && !old.celebrate) _play();
  }

  void _play() {
    final c = _fade ??= AnimationController(
      vsync: this,
      duration: AppMotion.standard,
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed) widget.onCelebrated();
      });
    c.forward(from: 0);
  }

  @override
  void dispose() {
    _fade?.dispose();
    super.dispose();
  }

  Widget _circle(bool done) {
    final isToday = widget.isToday;
    return Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: done
            ? AppColors.accent
            : isToday
                ? AppColors.accentSoft
                : AppColors.chip,
        border: isToday ? Border.all(color: AppColors.accent, width: 2) : null,
        boxShadow: done
            ? [
                BoxShadow(
                  color: AppColors.accent.withValues(alpha: 0.24),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ]
            : null,
      ),
      alignment: Alignment.center,
      child: done
          ? const Icon(Icons.check_rounded, size: 14, color: Colors.white)
          : isToday
              ? const Text(
                  '!',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: AppColors.accent,
                  ),
                )
              : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final label = widget.label;
    final isToday = widget.isToday;
    final fade = _fade;
    return Column(
      children: [
        fade == null
            ? _circle(widget.done)
            : AnimatedBuilder(
                animation: fade,
                builder: (context, _) => fade.isAnimating
                    // Đang hiện tick mới: lớp "chưa học" bên dưới, lớp "đã
                    // học" mờ dần lên trên (không lerp màu của token theme).
                    ? Stack(
                        children: [
                          _circle(false),
                          Opacity(
                            opacity: Curves.easeOut.transform(fade.value),
                            child: _circle(true),
                          ),
                        ],
                      )
                    : _circle(widget.done),
              ),
        const SizedBox(height: 5),
        Text(
          label,
          style: TextStyle(
            fontSize: 9,
            fontWeight: isToday ? FontWeight.w800 : FontWeight.w700,
            color: isToday ? AppColors.accent : AppColors.inkSoft,
          ),
        ),
      ],
    );
  }
}
