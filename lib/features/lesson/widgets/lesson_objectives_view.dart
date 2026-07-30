import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

/// Danh sách mục tiêu — luôn nhận [objectives] đã suy ra từ nội dung thật
/// của bài (xem `deriveLessonObjectives`), không có văn bản marketing bịa.
class LessonObjectivesView extends StatelessWidget {
  const LessonObjectivesView({
    super.key,
    required this.objectives,
    required this.onReady,
  });

  final List<String> objectives;
  final VoidCallback onReady;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                const Text(
                  'Mục tiêu bài học',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.ink),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Học xong bài này bạn sẽ:',
                  style: TextStyle(fontSize: 14, color: AppColors.inkSoft),
                ),
                const SizedBox(height: 20),
                if (objectives.isEmpty)
                  const Text(
                    'Bài ôn tập — không có mục tiêu nội dung mới, chuyển thẳng sang luyện tập.',
                    style: TextStyle(fontSize: 14, color: AppColors.inkSoft),
                  )
                else
                  for (final objective in objectives) _ObjectiveRow(text: objective),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: FilledButton(onPressed: onReady, child: const Text('Sẵn sàng')),
        ),
      ],
    );
  }
}

class _ObjectiveRow extends StatelessWidget {
  const _ObjectiveRow({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_circle_outline_rounded, color: AppColors.phaseInput, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text, style: const TextStyle(fontSize: 14.5, color: AppColors.ink, height: 1.35)),
          ),
        ],
      ),
    );
  }
}
