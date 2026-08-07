import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../auth/auth_controller.dart';
import '../widgets/profile_section_label.dart';
import '../widgets/profile_settings_row.dart';

/// Nhóm "Tài khoản" — Settings/Premium/Đăng xuất + Bộ nhớ đệm + Hỗ trợ &
/// Pháp lý (Phase 6). Email hỗ trợ và nội dung Privacy Policy/Terms of
/// Service là giá trị thật/bản nháp do người dùng xác nhận dùng
/// (2026-08-07) — không còn là "chưa có giá trị thật" như quyết định ban
/// đầu. Rate App CHƯA thêm vì app chưa publish lên App Store/Play Store,
/// chưa có link thật để trỏ tới.
const _supportEmail = 'tranquocvietdct@gmail.com';
class AccountScreen extends ConsumerWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        backgroundColor: AppColors.canvas,
        title: const Text('Tài khoản'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        children: [
          const ProfileSectionLabel('Cài đặt'),
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border, width: 1.0),
            ),
            child: Column(
              children: [
                ProfileSettingsRow(
                  icon: Icons.workspace_premium_outlined,
                  label: 'Nâng cấp Premium',
                  labelColor: AppColors.accentStrong,
                  onTap: () => context.push('/premium'),
                ),
                const Divider(height: 1, color: AppColors.border),
                const ProfileSettingsRow(
                  icon: Icons.dark_mode_outlined,
                  label: 'Giao diện',
                  trailingText: 'Theo hệ thống',
                ),
                const Divider(height: 1, color: AppColors.border),
                const ProfileSettingsRow(
                  icon: Icons.language_rounded,
                  label: 'Ngôn ngữ',
                  trailingText: 'Tiếng Việt',
                ),
                const Divider(height: 1, color: AppColors.border),
                ProfileSettingsRow(
                  icon: Icons.logout_rounded,
                  label: 'Đăng xuất',
                  labelColor: AppColors.danger,
                  onTap: () =>
                      ref.read(authControllerProvider.notifier).signOut(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          const ProfileSectionLabel('Bộ nhớ đệm'),
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border, width: 1.0),
            ),
            child: ProfileSettingsRow(
              icon: Icons.cleaning_services_outlined,
              label: 'Xoá bộ nhớ đệm hình ảnh',
              onTap: () {
                PaintingBinding.instance.imageCache.clear();
                PaintingBinding.instance.imageCache.clearLiveImages();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Đã xoá bộ nhớ đệm hình ảnh')),
                );
              },
            ),
          ),
          const SizedBox(height: 22),
          const ProfileSectionLabel('Hỗ trợ & Pháp lý'),
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border, width: 1.0),
            ),
            child: Column(
              children: [
                ProfileSettingsRow(
                  icon: Icons.mail_outline_rounded,
                  label: 'Hỗ trợ',
                  trailingText: _supportEmail,
                  onTap: () async {
                    await Clipboard.setData(
                      const ClipboardData(text: _supportEmail),
                    );
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Đã sao chép email hỗ trợ'),
                        ),
                      );
                    }
                  },
                ),
                const Divider(height: 1, color: AppColors.border),
                ProfileSettingsRow(
                  icon: Icons.privacy_tip_outlined,
                  label: 'Chính sách bảo mật',
                  onTap: () => context.push('/profile/privacy'),
                ),
                const Divider(height: 1, color: AppColors.border),
                ProfileSettingsRow(
                  icon: Icons.description_outlined,
                  label: 'Điều khoản dịch vụ',
                  onTap: () => context.push('/profile/terms'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
