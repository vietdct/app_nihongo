import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

/// Màn Premium — theo mockup "Nihongo App Redesign". App chưa tích hợp
/// thanh toán nào (không App Store IAP/RevenueCat) nên đây chỉ là giao diện;
/// bấm nút giá hiện snackbar báo chưa có, không có giao dịch thật nào xảy ra.
/// Vào từ mục "Nâng cấp Premium" trong Hồ sơ (không còn là tab riêng vì
/// mockup gốc chỉ có 7 tab điều hướng, không có Premium).
class PremiumScreen extends StatelessWidget {
  const PremiumScreen({super.key});

  static const _benefits = [
    (
      icon: Icons.all_inclusive_rounded,
      bg: Color(0xFFFFE4D1),
      color: AppColors.accentStrong,
      title: 'Tim không giới hạn',
      sub: 'Học bao nhiêu cũng không bị dừng',
    ),
    (
      icon: Icons.check_circle_rounded,
      bg: AppColors.mossSoft,
      color: AppColors.moss,
      title: 'Toàn bộ bài học N5 → N1',
      sub: 'Mở khoá tất cả cấp độ',
    ),
    (
      icon: Icons.forum_rounded,
      bg: AppColors.indigoSoft,
      color: AppColors.indigo,
      title: 'AI Kaiwa không giới hạn',
      sub: 'Luyện nói cùng AI mọi lúc',
    ),
    (
      icon: Icons.workspace_premium_rounded,
      bg: AppColors.tealSoft,
      color: AppColors.teal,
      title: 'Không quảng cáo',
      sub: 'Tập trung 100% vào việc học',
    ),
  ];

  void _showComingSoon(BuildContext context) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(content: Text('Thanh toán sẽ có ở bản sau')),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(title: const Text('Premium')),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFFB020), AppColors.accent],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                children: [
                  Text(
                    '日本語',
                    style: AppFonts.zenMaruGothic(
                      fontSize: 36,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'P R E M I U M',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 2,
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'Mở khoá toàn bộ bài học, không giới hạn tim, không quảng cáo',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.5,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            for (final b in _benefits) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.border, width: 1.0),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: b.bg,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      alignment: Alignment.center,
                      child: Icon(b.icon, color: b.color, size: 18),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            b.title,
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 13.5,
                              color: AppColors.ink,
                            ),
                          ),
                          const SizedBox(height: 1),
                          Text(
                            b.sub,
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.inkSoft,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
            ],
            const SizedBox(height: 10),
            InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => _showComingSoon(context),
              child: Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFB020),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Column(
                  children: [
                    Text(
                      'Nâng cấp hàng tháng',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      '79.000đ / tháng',
                      style: TextStyle(fontSize: 11.5, color: Colors.white70),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => _showComingSoon(context),
              child: Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.accent, Color(0xFFFFB020)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Column(
                  children: [
                    Text(
                      'Nâng cấp hàng năm',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      '569.000đ / năm · Tiết kiệm 40%',
                      style: TextStyle(fontSize: 11.5, color: Colors.white70),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'Huỷ bất cứ lúc nào · Thanh toán qua App Store',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11, color: AppColors.inkFaint),
            ),
          ],
        ),
      ),
    );
  }
}
