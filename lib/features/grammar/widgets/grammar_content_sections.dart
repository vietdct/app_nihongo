import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../domain/entities/grammar_meaning.dart';
import '../../../shared/jp_example_text.dart';

/// Tiêu đề 1 mục nội dung ngữ pháp — chấm màu + label in hoa nhỏ. Dùng
/// chung giữa thẻ flashcard (`grammar_flashcard_screen.dart`) và trang tra
/// cứu tĩnh (`grammar_detail_screen.dart`) để đồng bộ cách trình bày.
class GrammarSection extends StatelessWidget {
  const GrammarSection({
    super.key,
    required this.color,
    required this.label,
    required this.child,
  });

  final Color color;
  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: AppColors.ink,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        child,
      ],
    );
  }
}

class GrammarInfoBox extends StatelessWidget {
  const GrammarInfoBox({
    super.key,
    required this.child,
    this.background = AppColors.card,
  });

  final Widget child;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(16),
        border: background == AppColors.card
            ? Border.all(color: AppColors.border)
            : null,
      ),
      child: child,
    );
  }
}

/// 1 nghĩa riêng trong "Ý NGHĨA" (khi điểm ngữ pháp có nhiều nghĩa) — số thứ
/// tự + nội dung nghĩa, kèm ngay dưới tối đa 2 ví dụ minh hoạ của riêng
/// nghĩa đó, thay vì gộp chung 1 đoạn văn dài + 1 danh sách ví dụ dùng
/// chung như trước. Dùng chung giữa `grammar_detail_screen.dart` và
/// `grammar_flashcard_screen.dart`.
class GrammarMeaningCard extends StatelessWidget {
  const GrammarMeaningCard({
    super.key,
    required this.index,
    required this.meaning,
  });

  final int index;
  final GrammarMeaning meaning;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 20,
                height: 20,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: AppColors.plum,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '$index',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  meaning.meaningVi,
                  style: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
          if (meaning.examplesJp.isNotEmpty) ...[
            const SizedBox(height: 10),
            const Divider(height: 1, color: AppColors.canvas),
            const SizedBox(height: 10),
            for (final (i, jp) in meaning.examplesJp.indexed) ...[
              if (i > 0) const SizedBox(height: 8),
              JpExampleText(
                jp,
                style: AppFonts.zenMaruGothic(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: AppColors.ink,
                ),
              ),
              if (i < meaning.examplesVi.length) ...[
                const SizedBox(height: 4),
                Text(
                  meaning.examplesVi[i],
                  style: const TextStyle(
                    fontSize: 11.5,
                    color: AppColors.inkSoft,
                  ),
                ),
              ],
            ],
          ],
        ],
      ),
    );
  }
}
