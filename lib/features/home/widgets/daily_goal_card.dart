import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

/// Thẻ "mục tiêu hôm nay" + chấm tuần trên Home — theo bố cục mockup nhưng
/// trung thực với dữ liệu thật: app chưa có bộ đếm "số thẻ đã học hôm nay"
/// nên vòng tròn chỉ hiện viền rỗng (không tô cung, không bịa phân số). 7
/// chấm tuần nối [studyDays] thật (bảng `study_days`, cùng nguồn với heatmap
/// Thành tích ở Profile) — null nghĩa là đang tải, chưa có nghĩa là chưa học.
class DailyGoalCard extends StatelessWidget {
  const DailyGoalCard({super.key, required this.studyDays});

  final Set<DateTime>? studyDays;

  static const _weekLabels = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];

  @override
  Widget build(BuildContext context) {
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
                  label: _weekLabels[i],
                  isToday: i + 1 == todayWeekday,
                  done: studyDays?.contains(monday.add(Duration(days: i))) ??
                      false,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _WeekDot extends StatelessWidget {
  const _WeekDot({
    required this.label,
    required this.isToday,
    required this.done,
  });

  final String label;
  final bool isToday;
  final bool done;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: done
                ? AppColors.accent
                : isToday
                    ? AppColors.accentSoft
                    : AppColors.chip,
            border:
                isToday ? Border.all(color: AppColors.accent, width: 2) : null,
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
