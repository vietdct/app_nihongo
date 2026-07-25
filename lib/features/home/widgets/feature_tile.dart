import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

/// Ô tính năng vuông bo góc, hiện chữ Hán thay icon (theo mockup thiết kế lại) —
/// dùng cho lưới tính năng chính trên Home.
class FeatureTile extends StatelessWidget {
  const FeatureTile({
    super.key,
    required this.glyph,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final String glyph;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AspectRatio(
            aspectRatio: 1,
            child: Container(
              decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(18)),
              alignment: Alignment.center,
              child: Text(glyph, style: AppFonts.zenMaruGothic(fontSize: 26, color: Colors.white)),
            ),
          ),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12.5, color: AppColors.ink)),
        ],
      ),
    );
  }
}

/// Ô tính năng "Sắp ra mắt" — nhạt màu, có badge, bấm vào chỉ báo chưa sẵn sàng
/// thay vì im lặng không phản hồi hay dẫn tới màn hình trống.
class ComingSoonTile extends StatelessWidget {
  const ComingSoonTile({super.key, required this.glyph, required this.label, required this.phaseNote});

  final String glyph;
  final String label;
  final String phaseNote;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text('$label — $phaseNote')));
      },
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AspectRatio(
                aspectRatio: 1,
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.chip,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppColors.border),
                  ),
                  alignment: Alignment.center,
                  child: Text(glyph, style: AppFonts.zenMaruGothic(fontSize: 26, color: AppColors.inkFaint)),
                ),
              ),
              const SizedBox(height: 8),
              Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12.5, color: AppColors.inkSoft)),
            ],
          ),
          Positioned(
            top: -6,
            right: -6,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
              decoration: BoxDecoration(color: AppColors.accentSoft, borderRadius: BorderRadius.circular(6)),
              child: const Text(
                'SẮP CÓ',
                style: TextStyle(fontSize: 7.5, fontWeight: FontWeight.w800, color: AppColors.accentStrong, letterSpacing: 0.2),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Ô nhỏ hơn dùng trong lưới "Ôn tập & luyện thi" — viền mảnh, không có nền đầy.
class ReviewTile extends StatelessWidget {
  const ReviewTile({super.key, required this.glyph, required this.label, required this.phaseNote});

  final String glyph;
  final String label;
  final String phaseNote;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () {
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
                Text(glyph, style: AppFonts.zenMaruGothic(fontSize: 20, color: AppColors.inkFaint)),
                const SizedBox(height: 8),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: AppColors.inkSoft),
                ),
              ],
            ),
          ),
          Positioned(
            top: -6,
            right: 2,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              decoration: BoxDecoration(color: AppColors.accentSoft, borderRadius: BorderRadius.circular(5)),
              child: const Text(
                'SẮP CÓ',
                style: TextStyle(fontSize: 7, fontWeight: FontWeight.w800, color: AppColors.accentStrong),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
