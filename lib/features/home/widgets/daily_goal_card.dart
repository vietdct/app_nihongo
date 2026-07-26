import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

/// Thẻ "mục tiêu hôm nay" + chấm tuần trên Home — theo bố cục mockup nhưng
/// trung thực với dữ liệu thật: app chưa có bộ đếm "số thẻ đã học hôm nay"
/// nên vòng tròn chỉ hiện viền rỗng (không tô cung, không bịa phân số), và
/// trong 7 chấm tuần chỉ chấm "hôm nay" là có tín hiệu thật (so [lastStudyDate]
/// với ngày hiện tại) — 6 chấm còn lại không có lịch sử theo ngày nên hiện
/// trạng thái "chưa có dữ liệu" thay vì đoán mò.
class DailyGoalCard extends StatelessWidget {
  const DailyGoalCard({super.key, required this.lastStudyDate});

  final DateTime? lastStudyDate;

  static const _weekLabels = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];

  bool get _studiedToday {
    final d = lastStudyDate;
    if (d == null) return false;
    final now = DateTime.now();
    return d.year == now.year && d.month == now.month && d.day == now.day;
  }

  @override
  Widget build(BuildContext context) {
    final todayWeekday = DateTime.now().weekday; // 1=T2 ... 7=CN, khớp thứ tự _weekLabels

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border, width: 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.border, width: 6),
                ),
                alignment: Alignment.center,
                child: const Text('—', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.inkFaint)),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Mục tiêu hôm nay', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: AppColors.ink)),
                    SizedBox(height: 2),
                    Text('Số liệu sẽ hiện khi có dữ liệu học tập', style: TextStyle(fontSize: 11.5, color: AppColors.inkSoft)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              for (var i = 0; i < 7; i++) _WeekDot(label: _weekLabels[i], isToday: i + 1 == todayWeekday, done: i + 1 == todayWeekday && _studiedToday),
            ],
          ),
        ],
      ),
    );
  }
}

class _WeekDot extends StatelessWidget {
  const _WeekDot({required this.label, required this.isToday, required this.done});

  final String label;
  final bool isToday;
  final bool done;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 26,
          height: 26,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: done ? AppColors.accent : AppColors.chip,
            border: isToday && !done ? Border.all(color: AppColors.accent, width: 2) : null,
          ),
          alignment: Alignment.center,
          child: done
              ? const Icon(Icons.check_rounded, size: 14, color: Colors.white)
              : null,
        ),
        const SizedBox(height: 5),
        Text(label, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: AppColors.inkFaint)),
      ],
    );
  }
}
