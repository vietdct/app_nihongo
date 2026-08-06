import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../lesson/providers/level_providers.dart';

/// Bước 2 của "Thi thử JLPT": chọn 1 trong 6 chế độ thi (docs/JLPT_MOCK_EXAM_DESIGN.md §3).
/// Giai đoạn này (task "route + màn chọn Level/Mode") chỉ dựng khung điều
/// hướng — exam engine thật (sinh đề, chấm điểm) làm ở các task tiếp theo,
/// nên mỗi chế độ tạm báo "đang phát triển" khi bấm, thay vì dẫn tới màn hỏng.
class JlptExamModeScreen extends ConsumerWidget {
  const JlptExamModeScreen({required this.levelId, super.key});

  final String levelId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final levels = ref.watch(jlptLevelsProvider).valueOrNull;
    var levelCode = '';
    if (levels != null) {
      for (final level in levels) {
        if (level.id == levelId) {
          levelCode = level.code;
          break;
        }
      }
    }

    void notifyInDevelopment(String modeName) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '$modeName đang được phát triển, sẽ có ở bản cập nhật tiếp theo.',
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        title: Text(
          levelCode.isEmpty
              ? 'Chọn chế độ thi'
              : 'Chọn chế độ thi — $levelCode',
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _ModeCard(
            icon: Icons.assignment_outlined,
            title: 'Full Exam',
            subtitle: 'Mô phỏng đề thi đầy đủ 4 phần, đúng thời gian thật',
            onTap: () =>
                context.push('/review/jlpt-exam/$levelId/session/full_exam'),
          ),
          const SizedBox(height: 10),
          _ModeCard(
            icon: Icons.timer_outlined,
            title: 'Mini Test',
            subtitle: 'Luyện nhanh vài phút — Quick 5/Daily/Weak Point/AI',
            onTap: () => context.push('/review/jlpt-exam/$levelId/mini'),
          ),
          const SizedBox(height: 10),
          _ModeCard(
            icon: Icons.view_agenda_outlined,
            title: 'Section Practice',
            subtitle: 'Luyện riêng từng phần, không giới hạn giờ',
            onTap: () => notifyInDevelopment('Section Practice'),
          ),
          const SizedBox(height: 10),
          _ModeCard(
            icon: Icons.tune_outlined,
            title: 'Custom Test',
            subtitle: 'Tự chọn phần và số câu muốn làm',
            onTap: () => notifyInDevelopment('Custom Test'),
          ),
          const SizedBox(height: 10),
          _ModeCard(
            icon: Icons.trending_down_outlined,
            title: 'Weak Point Test',
            subtitle: 'Ưu tiên câu thuộc điểm yếu của bạn',
            onTap: () => notifyInDevelopment('Weak Point Test'),
          ),
          const SizedBox(height: 10),
          _ModeCard(
            icon: Icons.auto_awesome_outlined,
            title: 'AI Mock Exam',
            subtitle: 'AI soạn đề riêng theo lỗi bạn hay gặp',
            onTap: () => notifyInDevelopment('AI Mock Exam'),
          ),
        ],
      ),
    );
  }
}

class _ModeCard extends StatelessWidget {
  const _ModeCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.border, width: 1.0),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.indigoSoft,
                borderRadius: BorderRadius.circular(14),
              ),
              alignment: Alignment.center,
              child: Icon(icon, color: AppColors.indigo, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                      color: AppColors.ink,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style:
                        const TextStyle(fontSize: 11, color: AppColors.inkSoft),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: AppColors.inkFaint),
          ],
        ),
      ),
    );
  }
}
