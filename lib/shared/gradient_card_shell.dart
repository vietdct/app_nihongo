import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';

/// Khung thẻ viền gradient dùng chung cho các flashcard lật 2 mặt (Kanji,
/// Từ vựng...) — kích thước theo % màn hình (không theo constraint cha) để
/// khớp yêu cầu thiết kế "90-92% chiều ngang / 62-66% chiều cao màn hình",
/// có nới lỏng cho màn nhỏ (<=375) và màn lớn (>=430). Nội dung tự cuộn nếu
/// dài hơn chiều cao thẻ (vd. từ vựng nhiều nghĩa) nhưng vẫn căn giữa khi
/// vừa đủ, tránh tràn khi kích thước thẻ cố định thay vì co theo nội dung.
class GradientCardShell extends StatelessWidget {
  const GradientCardShell({
    super.key,
    required this.child,
    required this.gradientColors,
    required this.shadowColor,
    this.innerBackground,
  });

  final Widget child;
  final List<Color> gradientColors;
  final Color shadowColor;
  final Color? innerBackground;

  @override
  Widget build(BuildContext context) {
    final surface = innerBackground ?? AppColors.card;
    final screen = MediaQuery.sizeOf(context);
    final isSmall = screen.width <= 375;
    final isLarge = screen.width >= 430;
    final widthFactor = isSmall ? 0.88 : (isLarge ? 0.92 : 0.90);
    final heightFactor = isSmall ? 0.60 : (isLarge ? 0.66 : 0.64);

    return Container(
      width: (screen.width * widthFactor).clamp(280.0, 520.0),
      height: (screen.height * heightFactor).clamp(380.0, 720.0),
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradientColors,
        ),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: shadowColor,
            blurRadius: 32,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Container(
        width: double.infinity,
        height: double.infinity,
        padding: const EdgeInsets.fromLTRB(24, 32, 24, 28),
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(28),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Center(child: child),
              ),
            );
          },
        ),
      ),
    );
  }
}
