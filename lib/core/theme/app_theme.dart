import 'package:flutter/material.dart';

/// Bảng màu ấm — nền giấy kem, cam đất làm điểm nhấn chính, lam/rêu cho
/// hai nhóm nội dung Kanji/Từ vựng. Thiết kế lại theo bản mockup
/// "Nihongo App Redesign" (claude.ai/design), thay cho bảng chàm/chu sa cũ.
abstract final class AppColors {
  static const accent = Color(0xFFE2632E); // cam đất — CTA, Bài học
  static const accentSoft = Color(0xFFFBE6D8);
  static const accentStrong = Color(0xFFB94A1E);

  static const moss = Color(0xFF5C8A5F); // rêu — Từ vựng, trạng thái hoàn thành
  static const mossSoft = Color(0xFFE5EFE1);

  static const indigo = Color(0xFF4B6278); // lam xám — Kanji, huy hiệu cấp độ
  static const indigoSoft = Color(0xFFE7ECF0);

  static const plum = Color(0xFF8C5E83); // mận — Ngữ pháp
  static const plumSoft = Color(0xFFF0E5EE);

  static const teal = Color(0xFF2E8E82); // ngọc lam — AI Kaiwa
  static const tealSoft = Color(0xFFE1F0EC);

  static const canvas = Color(0xFFFAF7F2); // nền màn hình
  static const card = Color(0xFFFFFFFF);
  static const chip = Color(0xFFF2EBE0); // nền pill/chip chưa chọn
  static const border = Color(0xFFEAE1D2);

  static const ink = Color(0xFF2A2420); // chữ chính
  static const inkSoft = Color(0xFF948A7C); // chữ phụ
  static const inkFaint = Color(0xFFB7AE9F); // placeholder/hint
}

/// Font chữ Nhật (器 glyph, tiêu đề 日本語) — dùng riêng, tách khỏi text theme
/// chung vì Zen Maru Gothic chỉ đẹp với ký tự Hán/Kana, không hợp chữ Latin dài.
/// Đóng gói cục bộ trong assets/fonts (xem pubspec.yaml) thay vì tải qua CDN.
abstract final class AppFonts {
  static TextStyle zenMaruGothic({
    required double fontSize,
    FontWeight fontWeight = FontWeight.w700,
    Color? color,
  }) =>
      TextStyle(fontFamily: 'ZenMaruGothic', fontSize: fontSize, fontWeight: fontWeight, color: color);
}

abstract final class AppTheme {
  static ThemeData light() => _base(Brightness.light);
  static ThemeData dark() => _base(Brightness.dark);

  static ThemeData _base(Brightness brightness) {
    final isLight = brightness == Brightness.light;

    var scheme = ColorScheme.fromSeed(
      seedColor: AppColors.accent,
      brightness: brightness,
    ).copyWith(
      secondary: AppColors.moss,
      tertiary: AppColors.indigo,
    );

    if (isLight) {
      scheme = scheme.copyWith(
        primary: AppColors.accent,
        onPrimary: Colors.white,
        secondary: AppColors.moss,
        tertiary: AppColors.indigo,
        surface: AppColors.canvas,
        onSurface: AppColors.ink,
        surfaceContainerHighest: AppColors.chip,
        onSurfaceVariant: AppColors.inkSoft,
        outline: AppColors.inkFaint,
        outlineVariant: AppColors.border,
      );
    }

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      fontFamily: 'BeVietnamPro',
      scaffoldBackgroundColor: isLight ? AppColors.canvas : scheme.surface,
      textTheme: (isLight ? ThemeData.light().textTheme : ThemeData.dark().textTheme).apply(
        fontFamily: 'BeVietnamPro',
        bodyColor: isLight ? AppColors.ink : null,
        displayColor: isLight ? AppColors.ink : null,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: isLight ? AppColors.canvas : scheme.surface,
        foregroundColor: isLight ? AppColors.ink : scheme.onSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontFamily: 'BeVietnamPro',
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: isLight ? AppColors.ink : scheme.onSurface,
        ),
      ),
      cardTheme: CardThemeData(
        color: isLight ? AppColors.card : null,
        elevation: isLight ? 0 : null,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: isLight ? const BorderSide(color: AppColors.border, width: 0.6) : BorderSide.none,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: isLight,
        fillColor: isLight ? AppColors.card : null,
        hintStyle: TextStyle(color: isLight ? AppColors.inkFaint : null, fontSize: 14.5),
        labelStyle: TextStyle(color: isLight ? AppColors.inkSoft : null),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: isLight ? const BorderSide(color: AppColors.border) : BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: isLight ? const BorderSide(color: AppColors.border) : BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: scheme.primary, width: 1.6),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.accent,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: isLight ? AppColors.card : null,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),
    );
  }
}
