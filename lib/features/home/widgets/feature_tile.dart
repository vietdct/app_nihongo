import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

/// Ô nhỏ hơn dùng trong lưới "Ôn tập nhanh" — viền mảnh, không có nền đầy.
/// Icon outline (không phải chữ Hán) để khớp bộ icon trong mockup thiết kế.
/// Truyền [onTap] khi tính năng đã có thật (ẩn badge "SẮP CÓ"); ngược lại
/// truyền [phaseNote] để bấm vào chỉ hiện snackbar báo tiến độ.
class ReviewTile extends StatelessWidget {
  const ReviewTile(
      {super.key,
      required this.icon,
      required this.label,
      this.phaseNote,
      this.onTap,})
      : assert(onTap != null || phaseNote != null,
            'Cần truyền onTap (tính năng thật) hoặc phaseNote (stub)',);

  final IconData icon;
  final String label;
  final String? phaseNote;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isStub = onTap == null;
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap ??
          () {
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(SnackBar(content: Text('$label — $phaseNote')));
          },
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.border),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 21, color: AppColors.inkSoft),
                const SizedBox(height: 8),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.inkSoft,),
                ),
              ],
            ),
          ),
          if (isStub)
            Positioned(
              top: -6,
              right: 2,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                decoration: BoxDecoration(
                    color: AppColors.accentSoft,
                    borderRadius: BorderRadius.circular(5),),
                child: const Text(
                  'SẮP CÓ',
                  style: TextStyle(
                      fontSize: 7,
                      fontWeight: FontWeight.w800,
                      color: AppColors.accentStrong,),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
