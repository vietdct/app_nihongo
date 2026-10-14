import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import 'skeleton.dart';

/// Thẻ có viền như thẻ nội dung thật (nền card + viền + bo góc) chứa [child] —
/// các skeleton dưới đây dựng từ khối này để kích thước sát layout thật.
class SkeletonCard extends StatelessWidget {
  const SkeletonCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(14),
    this.radius = 16,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: AppColors.border, width: 0.6),
      ),
      child: child,
    );
  }
}

/// Danh sách bài học: mỗi dòng gồm ô biểu tượng 44px + tiêu đề + mô tả, đúng
/// bố cục thẻ bài học thật ([LessonListScreen]). Chỉ [count] dòng đủ phủ màn
/// đầu — không dựng danh sách dài.
class LessonListSkeleton extends StatelessWidget {
  const LessonListSkeleton({super.key, this.count = 7});

  final int count;

  @override
  Widget build(BuildContext context) {
    return SkeletonScope(
      child: ListView.separated(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        itemCount: count,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (_, __) => const SkeletonCard(
          child: Row(
            children: [
              SkeletonBox(width: 44, height: 44, radius: 12),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SkeletonBox(width: 150, height: 14),
                    SizedBox(height: 8),
                    SkeletonBox(height: 11),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Danh sách dạng hộp bo góc có đường kẻ giữa các dòng (Từ vựng/Ngữ pháp):
/// mỗi dòng 2 dòng chữ (tiêu đề + nghĩa/giải thích), tuỳ chọn nhãn pill bên
/// phải ([trailingPill], dành cho từ loại của từ vựng).
class ListCardSkeleton extends StatelessWidget {
  const ListCardSkeleton({
    super.key,
    this.count = 8,
    this.trailingPill = false,
  });

  final int count;
  final bool trailingPill;

  @override
  Widget build(BuildContext context) {
    return SkeletonScope(
      child: Container(
        margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.border, width: 1),
        ),
        clipBehavior: Clip.antiAlias,
        child: ListView.separated(
          physics: const NeverScrollableScrollPhysics(),
          itemCount: count,
          separatorBuilder: (_, __) =>
              const Divider(height: 1, color: AppColors.border),
          itemBuilder: (_, i) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Độ dài so le chỉ để khối trông tự nhiên, không đại diện
                      // cho nội dung nào.
                      SkeletonBox(width: 110.0 + (i % 3) * 30, height: 15),
                      const SizedBox(height: 7),
                      SkeletonBox(width: 150.0 + (i % 2) * 40, height: 12),
                    ],
                  ),
                ),
                if (trailingPill)
                  const SkeletonBox(width: 38, height: 20, radius: 100),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Lưới Kanji 4 cột đúng tỉ lệ ô thật (0,9) — chỉ ô trống, không có chữ Kanji
/// giả.
class KanjiGridSkeleton extends StatelessWidget {
  const KanjiGridSkeleton({super.key, this.count = 20});

  final int count;

  @override
  Widget build(BuildContext context) {
    return SkeletonScope(
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 0.9,
        ),
        itemCount: count,
        itemBuilder: (_, __) => const SkeletonCard(
          padding: EdgeInsets.all(10),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SkeletonBox(width: 34, height: 34, radius: 10),
              SizedBox(height: 8),
              SkeletonBox(width: 36, height: 10),
            ],
          ),
        ),
      ),
    );
  }
}

/// Khung chung cho 3 màn "trang chủ" Từ vựng/Kanji/Ngữ pháp và Lộ trình IT:
/// thanh tra cứu + vài mục (nhãn + thẻ) xếp dọc. Chiều cao thẻ gần với thẻ
/// thật để không nhảy bố cục khi dữ liệu về.
class SectionedHomeSkeleton extends StatelessWidget {
  const SectionedHomeSkeleton({
    super.key,
    this.cardHeights = const [92, 110, 84],
    this.showSearchBar = true,
  });

  final List<double> cardHeights;
  final bool showSearchBar;

  @override
  Widget build(BuildContext context) {
    return SkeletonScope(
      child: ListView(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
        children: [
          if (showSearchBar)
            const SkeletonCard(
              padding: EdgeInsets.symmetric(horizontal: 14, vertical: 13),
              radius: 14,
              child: Row(
                children: [
                  SkeletonBox(width: 20, height: 20, circle: true),
                  SizedBox(width: 10),
                  SkeletonBox(width: 190, height: 14),
                ],
              ),
            ),
          for (var i = 0; i < cardHeights.length; i++) ...[
            if (showSearchBar || i > 0) const SizedBox(height: 24),
            const SkeletonBox(width: 90, height: 12),
            const SizedBox(height: 10),
            SkeletonCard(
              radius: 18,
              child: SizedBox(
                height: cardHeights[i] - 28,
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SkeletonBox(width: 140, height: 16),
                    SizedBox(height: 8),
                    SkeletonBox(height: 12),
                    SizedBox(height: 6),
                    SkeletonBox(width: 200, height: 12),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
