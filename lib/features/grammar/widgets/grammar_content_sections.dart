import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

/// Tiêu đề 1 mục nội dung ngữ pháp — chấm màu + label in hoa nhỏ. Dùng
/// chung giữa thẻ flashcard (`grammar_flashcard_screen.dart`) và trang tra
/// cứu tĩnh (`grammar_detail_screen.dart`) để đồng bộ cách trình bày.
class GrammarSection extends StatelessWidget {
  const GrammarSection({
    super.key,
    required this.color,
    required this.label,
    required this.child,
  });

  final Color color;
  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: AppColors.ink,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        child,
      ],
    );
  }
}

class GrammarInfoBox extends StatelessWidget {
  const GrammarInfoBox({
    super.key,
    required this.child,
    this.background = AppColors.card,
  });

  final Widget child;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(16),
        border: background == AppColors.card
            ? Border.all(color: AppColors.border)
            : null,
      ),
      child: child,
    );
  }
}
