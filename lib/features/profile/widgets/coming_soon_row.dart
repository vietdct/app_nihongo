import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

/// Giữ chỗ cho tính năng chưa có backend/công thức thưởng nào được xác nhận
/// (VD Coins/Treasure/League) — chỉ hiển thị placeholder, không có logic
/// thật, tránh bịa số liệu.
class ComingSoonRow extends StatelessWidget {
  const ComingSoonRow({super.key, required this.emoji, required this.title});

  final String emoji;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: 0.55,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border, width: 1.0),
        ),
        child: Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 20)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                  color: AppColors.ink,
                ),
              ),
            ),
            const Text(
              'Sắp ra mắt',
              style: TextStyle(fontSize: 10, color: AppColors.inkFaint),
            ),
          ],
        ),
      ),
    );
  }
}
