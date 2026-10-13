import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/settings/app_settings_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/auth_controller.dart';
import '../widgets/profile_section_label.dart';
import '../widgets/profile_settings_row.dart';

const _supportEmail = 'tranquocvietdct@gmail.com';

class AccountScreen extends ConsumerWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings =
        ref.watch(appSettingsProvider).valueOrNull ?? AppSettings.defaults;
    final copy = _AccountCopy(settings.language);
    final colors = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? colors.surfaceContainerHigh : AppColors.card;
    final borderColor = isDark ? colors.outlineVariant : AppColors.border;

    return Scaffold(
      backgroundColor: isDark ? colors.surface : AppColors.canvas,
      appBar: AppBar(
        backgroundColor: isDark ? colors.surface : AppColors.canvas,
        title: Text(copy.account),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        children: [
          ProfileSectionLabel(copy.settings),
          const SizedBox(height: 10),
          _SettingsGroup(
            color: cardColor,
            borderColor: borderColor,
            children: [
              ProfileSettingsRow(
                icon: Icons.workspace_premium_outlined,
                label: copy.premium,
                labelColor: AppColors.accentStrong,
                onTap: () => context.push('/premium'),
              ),
              Divider(height: 1, color: borderColor),
              ProfileSettingsRow(
                icon: settings.theme == AppThemePreference.dark
                    ? Icons.dark_mode_outlined
                    : Icons.light_mode_outlined,
                label: copy.appearance,
                trailingText: copy.themeLabel(settings.theme),
                onTap: () => _showThemePicker(context, ref, copy, settings),
              ),
              Divider(height: 1, color: borderColor),
              ProfileSettingsRow(
                icon: Icons.language_rounded,
                label: copy.language,
                trailingText: settings.language.nativeLabel,
                onTap: () => _showLanguagePicker(context, ref, copy, settings),
              ),
              Divider(height: 1, color: borderColor),
              ProfileSettingsRow(
                icon: Icons.logout_rounded,
                label: copy.signOut,
                labelColor: AppColors.danger,
                onTap: () =>
                    ref.read(authControllerProvider.notifier).signOut(),
              ),
            ],
          ),
          const SizedBox(height: 22),
          ProfileSectionLabel(copy.cache),
          const SizedBox(height: 10),
          _SettingsGroup(
            color: cardColor,
            borderColor: borderColor,
            children: [
              ProfileSettingsRow(
                icon: Icons.cleaning_services_outlined,
                label: copy.clearImageCache,
                onTap: () {
                  PaintingBinding.instance.imageCache.clear();
                  PaintingBinding.instance.imageCache.clearLiveImages();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(copy.cacheCleared)),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 22),
          ProfileSectionLabel(copy.supportAndLegal),
          const SizedBox(height: 10),
          _SettingsGroup(
            color: cardColor,
            borderColor: borderColor,
            children: [
              ProfileSettingsRow(
                icon: Icons.mail_outline_rounded,
                label: copy.support,
                trailingText: _supportEmail,
                onTap: () async {
                  await Clipboard.setData(
                    const ClipboardData(text: _supportEmail),
                  );
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(copy.supportCopied)),
                    );
                  }
                },
              ),
              Divider(height: 1, color: borderColor),
              ProfileSettingsRow(
                icon: Icons.privacy_tip_outlined,
                label: copy.privacy,
                onTap: () => context.push('/profile/privacy'),
              ),
              Divider(height: 1, color: borderColor),
              ProfileSettingsRow(
                icon: Icons.description_outlined,
                label: copy.terms,
                onTap: () => context.push('/profile/terms'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _showThemePicker(
    BuildContext context,
    WidgetRef ref,
    _AccountCopy copy,
    AppSettings settings,
  ) =>
      showModalBottomSheet<void>(
        context: context,
        builder: (sheetContext) => _SettingsPicker<AppThemePreference>(
          title: copy.appearance,
          value: settings.theme,
          options: [
            _PickerOption(
              AppThemePreference.light,
              copy.lightMode,
              Icons.light_mode_outlined,
            ),
            _PickerOption(
              AppThemePreference.dark,
              copy.darkMode,
              Icons.dark_mode_outlined,
            ),
          ],
          onSelected: (theme) async {
            await ref.read(appSettingsProvider.notifier).setTheme(theme);
            if (sheetContext.mounted) Navigator.pop(sheetContext);
          },
        ),
      );

  Future<void> _showLanguagePicker(
    BuildContext context,
    WidgetRef ref,
    _AccountCopy copy,
    AppSettings settings,
  ) =>
      showModalBottomSheet<void>(
        context: context,
        builder: (sheetContext) => _SettingsPicker<AppLanguage>(
          title: copy.language,
          value: settings.language,
          options: const [
            _PickerOption(
              AppLanguage.vietnamese,
              'Tiếng Việt',
              Icons.translate_rounded,
            ),
            _PickerOption(
              AppLanguage.english,
              'English',
              Icons.translate_rounded,
            ),
            _PickerOption(
              AppLanguage.japanese,
              '日本語',
              Icons.translate_rounded,
            ),
          ],
          onSelected: (language) async {
            await ref.read(appSettingsProvider.notifier).setLanguage(language);
            if (sheetContext.mounted) Navigator.pop(sheetContext);
          },
        ),
      );
}

class _SettingsGroup extends StatelessWidget {
  const _SettingsGroup({
    required this.color,
    required this.borderColor,
    required this.children,
  });

  final Color color;
  final Color borderColor;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor),
        ),
        child: Column(children: children),
      );
}

class _PickerOption<T> {
  const _PickerOption(this.value, this.label, this.icon);

  final T value;
  final String label;
  final IconData icon;
}

class _SettingsPicker<T> extends StatelessWidget {
  const _SettingsPicker({
    required this.title,
    required this.value,
    required this.options,
    required this.onSelected,
  });

  final String title;
  final T value;
  final List<_PickerOption<T>> options;
  final ValueChanged<T> onSelected;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: colors.outlineVariant,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            for (final option in options)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(option.icon),
                title: Text(option.label),
                trailing: Icon(
                  option.value == value
                      ? Icons.check_circle_rounded
                      : Icons.circle_outlined,
                  color:
                      option.value == value ? colors.primary : colors.outline,
                ),
                onTap: () => onSelected(option.value),
              ),
          ],
        ),
      ),
    );
  }
}

class _AccountCopy {
  const _AccountCopy(this.appLanguage);

  final AppLanguage appLanguage;

  String get account => switch (appLanguage) {
        AppLanguage.vietnamese => 'Tài khoản',
        AppLanguage.english => 'Account',
        AppLanguage.japanese => 'アカウント',
      };
  String get settings => switch (appLanguage) {
        AppLanguage.vietnamese => 'Cài đặt',
        AppLanguage.english => 'Settings',
        AppLanguage.japanese => '設定',
      };
  String get premium => switch (appLanguage) {
        AppLanguage.vietnamese => 'Nâng cấp Premium',
        AppLanguage.english => 'Upgrade to Premium',
        AppLanguage.japanese => 'プレミアムにアップグレード',
      };
  String get appearance => switch (appLanguage) {
        AppLanguage.vietnamese => 'Giao diện',
        AppLanguage.english => 'Appearance',
        AppLanguage.japanese => 'テーマ',
      };
  String get language => switch (appLanguage) {
        AppLanguage.vietnamese => 'Ngôn ngữ',
        AppLanguage.english => 'Language',
        AppLanguage.japanese => '言語',
      };
  String get signOut => switch (appLanguage) {
        AppLanguage.vietnamese => 'Đăng xuất',
        AppLanguage.english => 'Sign out',
        AppLanguage.japanese => 'ログアウト',
      };
  String get cache => switch (appLanguage) {
        AppLanguage.vietnamese => 'Bộ nhớ đệm',
        AppLanguage.english => 'Cache',
        AppLanguage.japanese => 'キャッシュ',
      };
  String get clearImageCache => switch (appLanguage) {
        AppLanguage.vietnamese => 'Xoá bộ nhớ đệm hình ảnh',
        AppLanguage.english => 'Clear image cache',
        AppLanguage.japanese => '画像キャッシュを削除',
      };
  String get cacheCleared => switch (appLanguage) {
        AppLanguage.vietnamese => 'Đã xoá bộ nhớ đệm hình ảnh',
        AppLanguage.english => 'Image cache cleared',
        AppLanguage.japanese => '画像キャッシュを削除しました',
      };
  String get supportAndLegal => switch (appLanguage) {
        AppLanguage.vietnamese => 'Hỗ trợ & Pháp lý',
        AppLanguage.english => 'Support & Legal',
        AppLanguage.japanese => 'サポートと法的情報',
      };
  String get support => switch (appLanguage) {
        AppLanguage.vietnamese => 'Hỗ trợ',
        AppLanguage.english => 'Support',
        AppLanguage.japanese => 'サポート',
      };
  String get supportCopied => switch (appLanguage) {
        AppLanguage.vietnamese => 'Đã sao chép email hỗ trợ',
        AppLanguage.english => 'Support email copied',
        AppLanguage.japanese => 'サポートメールをコピーしました',
      };
  String get privacy => switch (appLanguage) {
        AppLanguage.vietnamese => 'Chính sách bảo mật',
        AppLanguage.english => 'Privacy policy',
        AppLanguage.japanese => 'プライバシーポリシー',
      };
  String get terms => switch (appLanguage) {
        AppLanguage.vietnamese => 'Điều khoản dịch vụ',
        AppLanguage.english => 'Terms of service',
        AppLanguage.japanese => '利用規約',
      };
  String get lightMode => switch (appLanguage) {
        AppLanguage.vietnamese => 'Chế độ sáng',
        AppLanguage.english => 'Light mode',
        AppLanguage.japanese => 'ライトモード',
      };
  String get darkMode => switch (appLanguage) {
        AppLanguage.vietnamese => 'Chế độ tối',
        AppLanguage.english => 'Dark mode',
        AppLanguage.japanese => 'ダークモード',
      };

  String themeLabel(AppThemePreference theme) => switch (theme) {
        AppThemePreference.light => lightMode,
        AppThemePreference.dark => darkMode,
      };
}
