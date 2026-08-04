import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';

/// Con dấu "ĐÃ THUỘC"/"CHƯA THUỘC" nghiêng hiện ra khi vuốt thẻ — dùng chung
/// cho mọi flashcard lật 2 mặt (Kanji, Từ vựng...).
class CardStampLabel extends StatelessWidget {
  const CardStampLabel({
    super.key,
    required this.text,
    required this.color,
    this.angle = 0,
  });

  final String text;
  final Color color;

  /// Góc nghiêng (radian) — khớp con dấu nghiêng trong thiết kế thay vì nằm
  /// ngang.
  final double angle;

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: angle,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.card,
          border: Border.all(color: color, width: 3),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w900,
            fontSize: 15,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }
}
