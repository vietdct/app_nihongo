import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _themePreferenceKey = 'appearance_theme_mode';
const _languagePreferenceKey = 'app_language';

/// Hai giao diện mà app hỗ trợ. Không dùng `system` để lựa chọn của người học
/// luôn rõ ràng và không tự đổi khi thiết bị đổi giao diện.
enum AppThemePreference { light, dark }

enum AppLanguage {
  vietnamese(Locale('vi')),
  english(Locale('en')),
  japanese(Locale('ja'));

  const AppLanguage(this.locale);

  final Locale locale;

  String get nativeLabel => switch (this) {
        AppLanguage.vietnamese => 'Tiếng Việt',
        AppLanguage.english => 'English',
        AppLanguage.japanese => '日本語',
      };
}

class AppSettings {
  const AppSettings({required this.theme, required this.language});

  static const defaults = AppSettings(
    theme: AppThemePreference.light,
    language: AppLanguage.vietnamese,
  );

  final AppThemePreference theme;
  final AppLanguage language;

  ThemeMode get themeMode => switch (theme) {
        AppThemePreference.light => ThemeMode.light,
        AppThemePreference.dark => ThemeMode.dark,
      };

  AppSettings copyWith({
    AppThemePreference? theme,
    AppLanguage? language,
  }) =>
      AppSettings(
        theme: theme ?? this.theme,
        language: language ?? this.language,
      );
}

/// Cài đặt giao diện/ngôn ngữ được lưu cục bộ, nên vẫn hoạt động khi offline
/// và được khôi phục ngay sau lần mở app tiếp theo.
final appSettingsProvider =
    AsyncNotifierProvider<AppSettingsController, AppSettings>(
  AppSettingsController.new,
);

class AppSettingsController extends AsyncNotifier<AppSettings> {
  @override
  Future<AppSettings> build() async {
    final preferences = await SharedPreferences.getInstance();
    return AppSettings(
      theme: _enumByName(
        AppThemePreference.values,
        preferences.getString(_themePreferenceKey),
        AppSettings.defaults.theme,
      ),
      language: _enumByName(
        AppLanguage.values,
        preferences.getString(_languagePreferenceKey),
        AppSettings.defaults.language,
      ),
    );
  }

  Future<void> setTheme(AppThemePreference theme) async {
    final updated = _current.copyWith(theme: theme);
    state = AsyncData(updated);
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_themePreferenceKey, theme.name);
  }

  Future<void> setLanguage(AppLanguage language) async {
    final updated = _current.copyWith(language: language);
    state = AsyncData(updated);
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_languagePreferenceKey, language.name);
  }

  AppSettings get _current => state.valueOrNull ?? AppSettings.defaults;
}

T _enumByName<T extends Enum>(List<T> values, String? name, T fallback) {
  for (final value in values) {
    if (value.name == name) return value;
  }
  return fallback;
}
