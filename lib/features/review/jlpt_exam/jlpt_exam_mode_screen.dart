import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../lesson/providers/level_providers.dart';

/// Bước 2 của "Thi thử JLPT": chọn 1 trong 3 chế độ thi (docs/JLPT_MOCK_EXAM_DESIGN.md §3).
/// Rút từ 6 xuống 3 (2026-08-06, theo yêu cầu người dùng — 4 chế độ còn lại
/// chưa từng có code thật, chỉ toast "đang phát triển"): bỏ hẳn Weak Point
/// Test (trùng "Weak Point Mini" đã có trong Mini Test) và AI Mock Exam
/// (cùng lý do đã bỏ AI Mini Test — AI tự soạn đề không nằm trong phạm vi
/// sản phẩm); gộp Section Practice vào Custom Test (chọn đúng 1 section +
/// không giới hạn giờ trong Custom Test = Section Practice cũ). Custom Test
/// vẫn tạm báo "đang phát triển" khi bấm — exam engine cho chế độ này chưa
/// build, chỉ mới quyết định giữ nó lại.
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
            subtitle: 'Luyện nhanh vài phút — Quick 5/Daily/Weak Point',
            onTap: () => context.push('/review/jlpt-exam/$levelId/mini'),
          ),
          const SizedBox(height: 10),
          _ModeCard(
            icon: Icons.tune_outlined,
            title: 'Custom Test',
            subtitle: 'Tự chọn phần và số câu muốn làm — kể cả luyện riêng 1 phần, không giới hạn giờ',
            onTap: () => notifyInDevelopment('Custom Test'),
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
