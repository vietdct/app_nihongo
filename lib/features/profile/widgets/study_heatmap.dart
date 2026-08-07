import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../providers/study_heatmap_providers.dart';

/// Lịch nhiệt (heatmap) kiểu GitHub — mỗi cột là 1 tuần (Thứ Hai→Chủ Nhật),
/// mỗi ô là 1 ngày, tô màu nếu có hoạt động thật ghi trong `study_days`.
/// Chỉ hiển thị có/không học (nhị phân), không suy diễn thời lượng vì app
/// chưa đo thời gian học thật theo phiên.
class StudyHeatmap extends StatelessWidget {
  const StudyHeatmap({super.key, required this.studyDays});

  final Set<DateTime> studyDays;

  static const _cellSize = 13.0;
  static const _cellGap = 3.0;
  static const _weekdayLabels = ['T2', '', 'T4', '', 'T6', '', 'CN'];

  @override
  Widget build(BuildContext context) {
    final gridStart = studyHeatmapGridStart();
    final today = DateTime.now();
    final todayOnly = DateTime(today.year, today.month, today.day);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      reverse: true,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              for (final label in _weekdayLabels)
                SizedBox(
                  height: _cellSize + _cellGap,
                  child: Text(
                    label,
                    style: const TextStyle(
                      fontSize: 9,
                      color: AppColors.inkFaint,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 6),
          for (var col = 0; col < studyHeatmapWeeks; col++)
            Padding(
              padding: const EdgeInsets.only(right: _cellGap),
              child: Column(
                children: [
                  for (var row = 0; row < 7; row++)
                    Padding(
                      padding: const EdgeInsets.only(bottom: _cellGap),
                      child: _buildCell(
                        gridStart.add(Duration(days: col * 7 + row)),
                        todayOnly,
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCell(DateTime date, DateTime todayOnly) {
    if (date.isAfter(todayOnly)) {
      return const SizedBox(width: _cellSize, height: _cellSize);
    }
    final studied = studyDays.contains(date);
    final isToday = date == todayOnly;
    return Container(
      width: _cellSize,
      height: _cellSize,
      decoration: BoxDecoration(
        color: studied ? AppColors.moss : AppColors.chip,
        borderRadius: BorderRadius.circular(3),
        border: isToday
            ? Border.all(color: AppColors.ink, width: 1.2)
            : null,
      ),
    );
  }
}
