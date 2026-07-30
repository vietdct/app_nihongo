import 'package:flutter/material.dart';

/// Bảng màu ấm — nền kem, cam san hô làm điểm nhấn chính, mỗi mảng nội dung
/// (Từ vựng/Kanji/Ngữ pháp/Kaiwa) một màu riêng. Theo bản mockup
/// "Nihongo App Redesign" (claude.ai/design), thay cho bảng cam đất cũ.
abstract final class AppColors {
  static const accent = Color(0xFFFF7A45); // cam san hô — CTA, Bài học
  static const accentSoft = Color(0xFFFFE4D1);
  static const accentStrong = Color(0xFFE85A1A);

  static const moss = Color(0xFF3FB35B); // xanh lá — Từ vựng, trạng thái hoàn thành
  static const mossSoft = Color(0xFFDEF7E3);

  static const indigo = Color(0xFF4C7EF0); // xanh dương — Kanji, huy hiệu cấp độ
  static const indigoSoft = Color(0xFFE6EDFF);

  static const plum = Color(0xFFC8559E); // hồng mận — Ngữ pháp
  static const plumSoft = Color(0xFFFCE7F5);

  static const teal = Color(0xFF12B8AA); // ngọc lam — AI Kaiwa
  static const tealSoft = Color(0xFFD7F7F3);

  static const canvas = Color(0xFFFFF9EF); // nền màn hình
  static const card = Color(0xFFFFFFFF);
  static const chip = Color(0xFFF1EADA); // nền pill/chip chưa chọn
  static const border = Color(0xFFF0E6D3);

  static const ink = Color(0xFF241C15); // chữ chính
  static const inkSoft = Color(0xFF8C8072); // chữ phụ
  static const inkFaint = Color(0xFFB7AE9F); // placeholder/hint

  // Trạng thái lỗi thật sự (VD hộp "Lỗi thường gặp" ở Ngữ pháp) — tách khỏi
  // accentStrong vì accentStrong giờ mang nghĩa "cam đậm/nổi bật" trung tính
  // (badge đếm số thẻ chưa thuộc), không phải lỗi.
  static const danger = Color(0xFFC11F30);
  static const dangerSoft = Color(0xFFFFE1E4);

  // Gradient header hero ở Home — cam san hô ngả hồng, theo mockup.
  static const heroGradientStart = Color(0xFFFF9C5A);
  static const heroGradientEnd = Color(0xFFD85A93);

  // Màu 5 pha của Lesson Runner (Input→Understand→Practice→Apply→Review) —
  // alias thẳng vào màu module đã có, không thêm màu mới: người học đã quen
  // "indigo = Kanji", "teal = AI Kaiwa"... nên thấy lại đúng màu đó khi pha
  // tương ứng xuất hiện trong 1 bài học, không cần học lại ý nghĩa màu.
  static const phaseInput = accent;
  static const phaseUnderstand = indigo;
  static const phasePractice = moss;
  static const phaseApply = teal;
  static const phaseReview = plum;
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
          side: isLight ? const BorderSide(color: AppColors.border, width: 1.0) : BorderSide.none,
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
