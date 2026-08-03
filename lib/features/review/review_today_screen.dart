import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../grammar/providers/grammar_progress_providers.dart';
import '../kanji/providers/kanji_progress_providers.dart';
import '../vocabulary/providers/vocab_progress_providers.dart';

/// Ước tính rất thô: ~15 giây cho mỗi thẻ/mẫu — chỉ để người học hình dung độ
/// dài phiên ôn, không phải số liệu đo thật (chưa có dữ liệu response time).
int _estimateMinutes(int dueCount) =>
    dueCount == 0 ? 0 : ((dueCount * 15) / 60).ceil();

/// "Hôm nay ôn gì" — liệt kê riêng từng nguồn đã đến hạn (Từ vựng/Kanji/Ngữ
/// pháp), mỗi nguồn dẫn thẳng tới màn Review SRS đã có sẵn của module đó
/// (`/vocabulary/review`, `/kanji/review`, `/grammar/review`). Chưa gộp
/// thành 1 phiên ôn đa nguồn (Mixed Review) — đó là quyết định kiến trúc
/// riêng, chưa được duyệt (xem `docs/REVIEW_DESIGN.md` §7, §15.2).
class ReviewTodayScreen extends ConsumerWidget {
  const ReviewTodayScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vocabProgress =
        ref.watch(vocabProgressProvider).valueOrNull ?? const {};
    final kanjiProgress =
        ref.watch(kanjiProgressProvider).valueOrNull ?? const {};
    final grammarProgress =
        ref.watch(grammarProgressProvider).valueOrNull ?? const {};

    final dueVocab = vocabProgress.values
        .where((p) => p.reviewCount > 0 && p.isDueNow)
        .length;
    final dueKanji = kanjiProgress.values
        .where((p) => p.reviewCount > 0 && p.isDueNow)
        .length;
    final dueGrammar = grammarProgress.values
        .where((p) => p.reviewCount > 0 && p.isDueNow)
        .length;
    final totalDue = dueVocab + dueKanji + dueGrammar;

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(title: const Text('Hôm nay ôn gì')),
      body: totalDue == 0
          ? const _EmptyTodayState()
          : ListView(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
              children: [
                Text(
                  'Tổng cộng $totalDue mục đến hạn · ước tính ${_estimateMinutes(totalDue)} phút',
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.inkSoft,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 14),
                if (dueVocab > 0) ...[
                  _TodaySourceRow(
                    icon: Icons.style_outlined,
                    iconBg: AppColors.mossSoft,
                    iconColor: AppColors.moss,
                    title: 'Từ vựng',
                    dueCount: dueVocab,
                    onTap: () => context.push('/vocabulary/review'),
                  ),
                  const SizedBox(height: 10),
                ],
                if (dueKanji > 0) ...[
                  _TodaySourceRow(
                    icon: Icons.brush_outlined,
                    iconBg: AppColors.indigoSoft,
                    iconColor: AppColors.indigo,
                    title: 'Kanji',
                    dueCount: dueKanji,
                    onTap: () => context.push('/kanji/review'),
                  ),
                  const SizedBox(height: 10),
                ],
                if (dueGrammar > 0) ...[
                  _TodaySourceRow(
                    icon: Icons.menu_book_outlined,
                    iconBg: AppColors.plumSoft,
                    iconColor: AppColors.plum,
                    title: 'Ngữ pháp',
                    dueCount: dueGrammar,
                    onTap: () => context.push('/grammar/review'),
                  ),
                  const SizedBox(height: 10),
                ],
                const SizedBox(height: 4),
                const _TodaySourceRow(
                  icon: Icons.headphones_outlined,
                  iconBg: AppColors.chip,
                  iconColor: AppColors.inkFaint,
                  title: 'Nghe',
                  dueCount: null,
                  onTap: null,
                ),
                const SizedBox(height: 10),
                const _TodaySourceRow(
                  icon: Icons.mic_none_outlined,
                  iconBg: AppColors.chip,
                  iconColor: AppColors.inkFaint,
                  title: 'Nói',
                  dueCount: null,
                  onTap: null,
                ),
              ],
            ),
    );
  }
}

class _EmptyTodayState extends StatelessWidget {
  const _EmptyTodayState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.celebration_outlined,
              size: 48,
              color: AppColors.accent,
            ),
            SizedBox(height: 12),
            Text(
              'Không có gì đến hạn hôm nay',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 16,
                color: AppColors.ink,
              ),
            ),
            SizedBox(height: 6),
            Text(
              'Quay lại sau, hoặc học thêm nội dung mới từ tab Bài học.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: AppColors.inkSoft),
            ),
          ],
        ),
      ),
    );
  }
}

class _TodaySourceRow extends StatelessWidget {
  const _TodaySourceRow({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.title,
    required this.dueCount,
    required this.onTap,
  });

  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String title;

  /// null = nguồn chưa sẵn sàng ("Sắp ra mắt"), khác với 0 (không có gì due).
  final int? dueCount;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final disabled = onTap == null;
    final subtitle = disabled
        ? 'Sắp ra mắt'
        : '$dueCount mục đến hạn · ước tính ${_estimateMinutes(dueCount!)} phút';
    return Opacity(
      opacity: disabled ? 0.55 : 1,
      child: InkWell(
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
                      subtitle,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.inkSoft,
                      ),
                    ),
                  ],
                ),
              ),
              if (!disabled)
                const Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.inkFaint,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
