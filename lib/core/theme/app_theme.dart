import 'package:flutter/material.dart';

/// Bảng màu lấy cảm hứng mỹ thuật truyền thống Nhật:
/// kon-iro (chàm) làm màu chủ đạo, shu-iro (chu sa — màu mực đóng dấu hanko) làm điểm nhấn.
abstract final class AppColors {
  static const konIro = Color(0xFF22405E); // chàm — primary
  static const shuIro = Color(0xFFB23A2E); // chu sa — secondary / CTA, XP, streak
  static const moss = Color(0xFF3F6A4C); // rêu — trạng thái đúng/hoàn thành
}

abstract final class AppTheme {
  static ThemeData light() => _base(Brightness.light);
  static ThemeData dark() => _base(Brightness.dark);

  static ThemeData _base(Brightness brightness) {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.konIro,
      brightness: brightness,
    ).copyWith(
      secondary: AppColors.shuIro,
      tertiary: AppColors.moss,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surface,
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        centerTitle: false,
      ),
      inputDecorationTheme: const InputDecorationTheme(
        border: OutlineInputBorder(),
      ),
    );
  }
}
