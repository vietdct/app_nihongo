import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';

/// Thống kê "Đã thuộc / Chưa thuộc" hiển thị dưới flashcard, cập nhật theo
/// từng thẻ đã vuốt qua trong lượt hiện tại — dùng chung cho mọi flashcard
/// lật 2 mặt (Kanji, Từ vựng...).
class CardKnownStats extends StatelessWidget {
  const CardKnownStats({super.key, required this.known, required this.unknown});

  final int known;
  final int unknown;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 58,
      child: Row(
        children: [
          Expanded(
            child: _Stat(
              icon: Icons.check_circle_rounded,
              color: AppColors.moss,
              label: 'Đã thuộc',
              value: known,
            ),
          ),
          Container(width: 1, height: 34, color: AppColors.border),
          Expanded(
            child: _Stat(
              icon: Icons.cancel_rounded,
              color: AppColors.danger,
              label: 'Chưa thuộc',
              value: unknown,
            ),
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final Color color;
  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          '$value',
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: AppColors.ink,
          ),
        ),
      ],
    );
  }
}
