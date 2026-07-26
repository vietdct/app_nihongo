import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import 'providers/quiz_providers.dart';

/// Màn chọn loại quiz — thay cho quiz gộp chung Từ vựng+Kanji+Ngữ pháp cũ.
/// Mỗi mục chỉ sinh câu hỏi từ đúng 1 mảng nội dung (xem
/// `levelCategoryQuizQuestionsProvider`); Nghe hiểu dùng lại màn `/listening`
/// đã tách riêng từ trước.
class QuizCategoryScreen extends StatelessWidget {
  const QuizCategoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(title: const Text('Chọn loại quiz')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _QuizCategoryCard(
            glyph: '語',
            label: 'Từ vựng',
            color: AppColors.moss,
            bg: AppColors.mossSoft,
            onTap: () =>
                context.push('/quiz/${QuizCategory.vocabulary.routeSegment}'),
          ),
          const SizedBox(height: 12),
          _QuizCategoryCard(
            glyph: '文',
            label: 'Ngữ pháp',
            color: AppColors.plum,
            bg: AppColors.plumSoft,
            onTap: () =>
                context.push('/quiz/${QuizCategory.grammar.routeSegment}'),
          ),
          const SizedBox(height: 12),
          _QuizCategoryCard(
            glyph: '字',
            label: 'Kanji',
            color: AppColors.indigo,
            bg: AppColors.indigoSoft,
            onTap: () =>
                context.push('/quiz/${QuizCategory.kanji.routeSegment}'),
          ),
          const SizedBox(height: 12),
          _QuizCategoryCard(
            glyph: '聴',
            label: 'Nghe hiểu',
            color: AppColors.accent,
            bg: AppColors.accentSoft,
            onTap: () => context.push('/listening'),
          ),
        ],
      ),
    );
  }
}

class _QuizCategoryCard extends StatelessWidget {
  const _QuizCategoryCard({
    required this.glyph,
    required this.label,
    required this.color,
    required this.bg,
    required this.onTap,
  });

  final String glyph;
  final String label;
  final Color color;
  final Color bg;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.border, width: 0.6),
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
              alignment: Alignment.center,
              child: Text(glyph,
                  style: AppFonts.zenMaruGothic(fontSize: 22, color: color),),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(label,
                  style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.ink,),),
            ),
            const Icon(Icons.chevron_right_rounded,
                color: AppColors.inkFaint,),
          ],
        ),
      ),
    );
  }
}
