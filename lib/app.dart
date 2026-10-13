import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/router/app_router.dart';
import 'core/settings/app_settings_provider.dart';
import 'core/theme/app_theme.dart';

class NihongoApp extends ConsumerWidget {
  const NihongoApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final settings =
        ref.watch(appSettingsProvider).valueOrNull ?? AppSettings.defaults;
    ThemeAdaptiveColor.isDark = settings.theme == AppThemePreference.dark;
    return MaterialApp.router(
      title: 'Nihongo',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: settings.themeMode,
      locale: settings.language.locale,
      supportedLocales: const [Locale('vi'), Locale('en'), Locale('ja')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      // Nhiều tab được giữ trong IndexedStack để tránh tải lại dữ liệu. Khi
      // đổi giao diện, ép subtree dựng lại để các BoxDecoration/TextStyle
      // hard-code từ các màn cũ nhận palette mới ngay lập tức.
      builder: (context, child) => KeyedSubtree(
        key: ValueKey(settings.theme),
        child: child ?? const SizedBox.shrink(),
      ),
      routerConfig: router,
    );
  }
}
