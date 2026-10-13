import 'dart:ui' show ColorSpace;

import 'package:flutter/material.dart';

/// Bảng màu ấm — nền kem, cam san hô làm điểm nhấn chính, mỗi mảng nội dung
/// (Từ vựng/Kanji/Ngữ pháp/Kaiwa) một màu riêng. Theo bản mockup
/// "Nihongo App Redesign" (claude.ai/design), thay cho bảng cam đất cũ.
abstract final class AppColors {
  static const accent = Color(0xFFFF7A45); // cam san hô — CTA, Bài học
  static const Color accentSoft = ThemeAdaptiveColor(
    Color(0xFFFFE4D1),
    Color(0xFF152825),
  );
  static const accentStrong = Color(0xFFE85A1A);

  static const moss =
      Color(0xFF3FB35B); // xanh lá — Từ vựng, trạng thái hoàn thành
  static const Color mossSoft = ThemeAdaptiveColor(
    Color(0xFFDEF7E3),
    Color(0xFF183D25),
  );

  static const indigo =
      Color(0xFF4C7EF0); // xanh dương — Kanji, huy hiệu cấp độ
  static const Color indigoSoft = ThemeAdaptiveColor(
    Color(0xFFE6EDFF),
    Color(0xFF1E315F),
  );

  static const plum = Color(0xFFC8559E); // hồng mận — Ngữ pháp
  static const Color plumSoft = ThemeAdaptiveColor(
    Color(0xFFFCE7F5),
    Color(0xFF4B203E),
  );

  static const teal = Color(0xFF12B8AA); // ngọc lam — AI Kaiwa
  static const Color tealSoft = ThemeAdaptiveColor(
    Color(0xFFD7F3F0),
    Color(0xFF153D3A),
  );

  static const Color canvas = ThemeAdaptiveColor(
    Color(0xFFFFF9EF),
    Color(0xFF0E1214),
  ); // nền màn hình
  static const Color card = ThemeAdaptiveColor(
    Color(0xFFFFFFFF),
    Color(0xFF141A1C),
  );
  static const Color chip = ThemeAdaptiveColor(
    Color(0xFFF1EADA),
    Color(0xFF1C2426),
  ); // nền pill/chip chưa chọn
  static const Color border = ThemeAdaptiveColor(
    Color(0xFFF0E6D3),
    Color(0xFF1E2E2C),
  );

  static const Color ink = ThemeAdaptiveColor(
    Color(0xFF241C15),
    Color(0xFFE0E8E6),
  ); // chữ chính
  static const Color inkSoft = ThemeAdaptiveColor(
    Color(0xFF8C8072),
    Color(0xFF8A9694),
  ); // chữ phụ
  static const Color inkFaint = ThemeAdaptiveColor(
    Color(0xFFB7AE9F),
    Color(0xFF5A6664),
  ); // placeholder/hint

  // Trạng thái lỗi thật sự (VD hộp "Lỗi thường gặp" ở Ngữ pháp) — tách khỏi
  // accentStrong vì accentStrong giờ mang nghĩa "cam đậm/nổi bật" trung tính
  // (badge đếm số thẻ chưa thuộc), không phải lỗi.
  static const danger = Color(0xFFC11F30);
  static const Color dangerSoft = ThemeAdaptiveColor(
    Color(0xFFFFE1E4),
    Color(0xFF4A2027),
  );

  // Hero giữ cam-hồng ở Light, chuyển sang teal tối để không chói ở Dark.
  static const Color heroGradientStart = ThemeAdaptiveColor(
    Color(0xFFFF9C5A),
    Color(0xFF0F2A2E),
  );
  static const Color heroGradientEnd = ThemeAdaptiveColor(
    Color(0xFFD85A93),
    Color(0xFF0E1416),
  );

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

/// Các màu trung tính được lấy theo giao diện hiện tại. Màu nhận diện của từng
/// module (cam/xanh/hồng...) vẫn dùng [AppColors], còn nền/card/chữ/viền phải
/// đi qua palette này để Light và Dark đều có độ tương phản đúng.
@immutable
class AppSurfacePalette {
  const AppSurfacePalette({
    required this.canvas,
    required this.card,
    required this.chip,
    required this.border,
    required this.ink,
    required this.inkSoft,
    required this.inkFaint,
  });

  final Color canvas;
  final Color card;
  final Color chip;
  final Color border;
  final Color ink;
  final Color inkSoft;
  final Color inkFaint;

  static const light = AppSurfacePalette(
    canvas: Color(0xFFFFF9EF),
    card: Color(0xFFFFFFFF),
    chip: Color(0xFFF1EADA),
    border: Color(0xFFF0E6D3),
    ink: Color(0xFF241C15),
    inkSoft: Color(0xFF8C8072),
    inkFaint: Color(0xFFB7AE9F),
  );

  static const dark = AppSurfacePalette(
    canvas: Color(0xFF0E1214),
    card: Color(0xFF141A1C),
    chip: Color(0xFF1C2426),
    border: Color(0xFF1E2E2C),
    ink: Color(0xFFE0E8E6),
    inkSoft: Color(0xFF8A9694),
    inkFaint: Color(0xFF5A6664),
  );
}

extension AppSurfacePaletteContext on BuildContext {
  AppSurfacePalette get appColors =>
      Theme.of(this).brightness == Brightness.dark
          ? AppSurfacePalette.dark
          : AppSurfacePalette.light;
}

/// Cho phép các widget cũ vốn dùng `AppColors.card`, `AppColors.ink`... giữ
/// nguyên cấu trúc (kể cả `const`) nhưng vẫn nhận màu Dark ở thời điểm vẽ.
/// [isDark] được đồng bộ trước khi [MaterialApp] dựng frame mới.
class ThemeAdaptiveColor extends Color {
  const ThemeAdaptiveColor(this.light, this.dark) : super(0x00000000);

  static bool isDark = false;

  final Color light;
  final Color dark;

  Color get _resolved => isDark ? dark : light;

  @override
  double get a => _resolved.a;

  @override
  double get r => _resolved.r;

  @override
  double get g => _resolved.g;

  @override
  double get b => _resolved.b;

  @override
  ColorSpace get colorSpace => _resolved.colorSpace;

  @override
  int toARGB32() => _resolved.toARGB32();

  @override
  Color withValues({
    double? alpha,
    double? red,
    double? green,
    double? blue,
    ColorSpace? colorSpace,
  }) =>
      _resolved.withValues(
        alpha: alpha,
        red: red,
        green: green,
        blue: blue,
        colorSpace: colorSpace,
      );
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
      TextStyle(
        fontFamily: 'ZenMaruGothic',
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
      );
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
    } else {
      scheme = scheme.copyWith(
        primary: AppColors.accent,
        onPrimary: Colors.white,
        secondary: AppColors.moss,
        tertiary: AppColors.indigo,
        surface: AppSurfacePalette.dark.canvas,
        onSurface: AppSurfacePalette.dark.ink,
        surfaceContainer: const Color(0xFF121819),
        surfaceContainerHigh: AppSurfacePalette.dark.card,
        surfaceContainerHighest: AppSurfacePalette.dark.chip,
        onSurfaceVariant: AppSurfacePalette.dark.inkSoft,
        outline: AppSurfacePalette.dark.inkFaint,
        outlineVariant: AppSurfacePalette.dark.border,
      );
    }

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      fontFamily: 'BeVietnamPro',
      scaffoldBackgroundColor: isLight ? AppColors.canvas : scheme.surface,
      textTheme:
          (isLight ? ThemeData.light().textTheme : ThemeData.dark().textTheme)
              .apply(
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
        color: isLight ? AppColors.card : AppSurfacePalette.dark.card,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: isLight ? AppColors.border : AppSurfacePalette.dark.border,
            width: 1.0,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: isLight,
        fillColor: isLight ? AppColors.card : AppSurfacePalette.dark.card,
        hintStyle: TextStyle(
          color: isLight ? AppColors.inkFaint : AppSurfacePalette.dark.inkFaint,
          fontSize: 14.5,
        ),
        labelStyle: TextStyle(
          color: isLight ? AppColors.inkSoft : AppSurfacePalette.dark.inkSoft,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: isLight ? AppColors.border : AppSurfacePalette.dark.border,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: isLight ? AppColors.border : AppSurfacePalette.dark.border,
          ),
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
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: isLight ? AppColors.card : AppSurfacePalette.dark.card,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),
    );
  }
}
