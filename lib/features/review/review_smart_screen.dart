import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../grammar/providers/grammar_progress_providers.dart';
import '../kanji/providers/kanji_progress_providers.dart';
import '../vocabulary/providers/vocab_progress_providers.dart';
import '../vocabulary/providers/vocab_review_providers.dart' show isSmartPick;

/// Smart Review — khác Today's Review (chỉ "đến hạn theo lịch"): gộp thêm
/// mục đang yếu (`easeFactor` thấp) dù chưa tới hạn, để AI "chọn thay bạn"
/// đúng như `docs/REVIEW_DESIGN.md` §14. Không tạo session runner đa nguồn
/// mới. Kanji dẫn tới đúng bộ thẻ vuốt (`KanjiDetailScreen`) giới hạn đúng
/// tập ID đã chọn — không dùng màn chấm điểm SRS cũ (`/kanji/review`) nữa
/// (theo yêu cầu người dùng). Ngữ pháp giữ nguyên `/grammar/review` vì
/// không nằm trong phạm vi yêu cầu đó. Từ vựng (2026-08-06): không tự tính
/// `filterIds` nữa — `VocabularyFlashcardScreen` giờ tự tính tập AI gợi ý
/// bằng cùng `isSmartPick`, ở đây chỉ đếm để hiện số + báo màn mở sẵn ở chế
/// độ AI gợi ý (`extra: true`), gộp chung với "Flashcard Từ vựng" cũ (đã bỏ
/// khỏi `review_screen.dart` vì trùng đích đến).
class ReviewSmartScreen extends ConsumerWidget {
  const ReviewSmartScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vocabProgress =
        ref.watch(vocabProgressProvider).valueOrNull ?? const {};
    final kanjiProgress =
        ref.watch(kanjiProgressProvider).valueOrNull ?? const {};
    final grammarProgress =
        ref.watch(grammarProgressProvider).valueOrNull ?? const {};

    final smartVocab = vocabProgress.values
        .where((p) => isSmartPick(p.reviewCount, p.easeFactor, p.isDueNow))
        .length;
    final smartKanjiIds = {
      for (final e in kanjiProgress.entries)
        if (isSmartPick(
          e.value.reviewCount,
          e.value.easeFactor,
          e.value.isDueNow,
        ))
          e.key,
    };
    final smartKanji = smartKanjiIds.length;
    final smartGrammar = grammarProgress.values
        .where((p) => isSmartPick(p.reviewCount, p.easeFactor, p.isDueNow))
        .length;
    final total = smartVocab + smartKanji + smartGrammar;

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(title: const Text('Smart Review')),
      body: total == 0
          ? const _EmptySmartState()
          : ListView(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
              children: [
                const Text(
                  'AI chọn sẵn mục đến hạn và mục bạn hay quên nhất — không cần tự chọn.',
                  style: TextStyle(fontSize: 13, color: AppColors.inkSoft),
                ),
                const SizedBox(height: 14),
                if (smartVocab > 0)
                  _SmartSourceRow(
                    icon: Icons.style_outlined,
                    iconBg: AppColors.mossSoft,
                    iconColor: AppColors.moss,
                    title: 'Từ vựng',
                    count: smartVocab,
                    onTap: () => context.push(
                      '/vocabulary/flashcards',
                      extra: true,
                    ),
                  ),
                if (smartVocab > 0) const SizedBox(height: 10),
                if (smartKanji > 0)
                  _SmartSourceRow(
                    icon: Icons.brush_outlined,
                    iconBg: AppColors.indigoSoft,
                    iconColor: AppColors.indigo,
                    title: 'Kanji',
                    count: smartKanji,
                    onTap: () => context.push(
                      '/kanji/${smartKanjiIds.first}',
                      extra: smartKanjiIds,
                    ),
                  ),
                if (smartKanji > 0) const SizedBox(height: 10),
                if (smartGrammar > 0)
                  _SmartSourceRow(
                    icon: Icons.menu_book_outlined,
                    iconBg: AppColors.plumSoft,
                    iconColor: AppColors.plum,
                    title: 'Ngữ pháp',
                    count: smartGrammar,
                    onTap: () => context.push('/grammar/review'),
                  ),
              ],
            ),
    );
  }
}

class _EmptySmartState extends StatelessWidget {
  const _EmptySmartState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.auto_awesome_outlined,
              size: 48,
              color: AppColors.accent,
            ),
            SizedBox(height: 12),
            Text(
              'Chưa có gợi ý nào',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 16,
                color: AppColors.ink,
              ),
            ),
            SizedBox(height: 6),
            Text(
              'Không có mục nào đến hạn hoặc đang yếu lúc này.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: AppColors.inkSoft),
            ),
          ],
        ),
      ),
    );
  }
}

class _SmartSourceRow extends StatelessWidget {
  const _SmartSourceRow({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.title,
    required this.count,
    required this.onTap,
  });

  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String title;
  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.border, width: 1.0),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(14),
              ),
              alignment: Alignment.center,
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                      color: AppColors.ink,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$count mục · đến hạn hoặc dễ quên',
                    style:
                        const TextStyle(fontSize: 11, color: AppColors.inkSoft),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: AppColors.inkFaint),
          ],
        ),
      ),
    );
  }
}
