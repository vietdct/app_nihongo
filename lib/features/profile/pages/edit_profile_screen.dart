import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/supabase_providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../home/providers/profile_providers.dart';

/// Chỉnh sửa hồ sơ — tên hiển thị + quốc gia (cột `country` thêm ở Phase 2,
/// migration `20260806140000_profile_country.sql`). Avatar chưa có vì cần
/// luồng upload ảnh thật (Supabase Storage) — để lại cho phase sau, tránh
/// dựng UI cho tính năng chưa hoạt động được.
class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  late final TextEditingController _nameController;
  late final TextEditingController _countryController;
  bool _saving = false;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _countryController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _countryController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;
    final userId = ref.read(currentUserProvider)?.id;
    if (userId == null) return;
    final country = _countryController.text.trim();

    setState(() => _saving = true);
    try {
      await ref.read(supabaseProvider).from('profiles').update({
        'display_name': name,
        'country': country.isEmpty ? null : country,
      }).eq('id', userId);
      ref.invalidate(profileProvider);
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi lưu hồ sơ: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(profileProvider).valueOrNull;
    if (!_initialized && profile != null) {
      _nameController.text = profile.displayName;
      _countryController.text = profile.country ?? '';
      _initialized = true;
    }

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        backgroundColor: AppColors.canvas,
        title: const Text('Chỉnh sửa hồ sơ'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Tên hiển thị',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.inkSoft,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _nameController,
              maxLength: 100,
              decoration: const InputDecoration(hintText: 'Tên của bạn'),
            ),
            const SizedBox(height: 16),
            const Text(
              'Quốc gia',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.inkSoft,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _countryController,
              maxLength: 60,
              decoration: const InputDecoration(hintText: 'VD: Việt Nam'),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Lưu'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
