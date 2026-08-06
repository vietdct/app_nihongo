import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show FileOptions;

import '../../../core/network/supabase_providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../home/providers/profile_providers.dart';

/// Chỉnh sửa hồ sơ — tên hiển thị, quốc gia và ảnh đại diện (Supabase
/// Storage bucket `avatars`, migration `20260807090000_avatar_storage.sql`).
/// Mỗi user 1 file cố định `{user_id}/avatar.jpg` — ghi đè khi đổi ảnh, kèm
/// query `?v=<timestamp>` để phá cache ảnh cũ trên `NetworkImage`.
class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  late final TextEditingController _nameController;
  late final TextEditingController _countryController;
  bool _saving = false;
  bool _uploadingAvatar = false;
  bool _initialized = false;
  File? _pickedAvatar;

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

  Future<void> _pickAndUploadAvatar() async {
    final userId = ref.read(currentUserProvider)?.id;
    if (userId == null) return;

    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 85,
    );
    if (picked == null) return;

    final file = File(picked.path);
    setState(() {
      _pickedAvatar = file;
      _uploadingAvatar = true;
    });
    try {
      final storage = ref.read(supabaseProvider).storage.from('avatars');
      final path = '$userId/avatar.jpg';
      await storage.upload(
        path,
        file,
        fileOptions: const FileOptions(
          upsert: true,
          contentType: 'image/jpeg',
        ),
      );
      final publicUrl = storage.getPublicUrl(path);
      final avatarUrl = '$publicUrl?v=${DateTime.now().millisecondsSinceEpoch}';
      await ref.read(supabaseProvider).from('profiles').update({
        'avatar_url': avatarUrl,
      }).eq('id', userId);
      ref.invalidate(profileProvider);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi tải ảnh đại diện: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _uploadingAvatar = false);
    }
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
            Center(
              child: GestureDetector(
                onTap: _uploadingAvatar ? null : _pickAndUploadAvatar,
                child: Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    CircleAvatar(
                      radius: 44,
                      backgroundColor: AppColors.accent.withValues(alpha: 0.9),
                      backgroundImage: _pickedAvatar != null
                          ? FileImage(_pickedAvatar!)
                          : (profile?.avatarUrl != null
                              ? NetworkImage(profile!.avatarUrl!)
                              : null),
                      child: _uploadingAvatar
                          ? const CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            )
                          : (_pickedAvatar == null && profile?.avatarUrl == null
                              ? Text(
                                  profile?.displayName.isNotEmpty == true
                                      ? profile!.displayName[0].toUpperCase()
                                      : '?',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 30,
                                  ),
                                )
                              : null),
                    ),
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                        color: AppColors.ink,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.camera_alt_rounded,
                        size: 14,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
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
