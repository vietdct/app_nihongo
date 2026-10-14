import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../../domain/entities/kanji.dart';
import '../../domain/entities/kanji_progress.dart';
import '../../shared/level_badge.dart';
import '../../shared/motion/animated_progress_bar.dart';
import '../../shared/motion/press_scale.dart';
import '../../shared/skeleton_layouts.dart';
import '../../shared/state_views.dart';
import '../lesson/providers/content_providers.dart';
import '../lesson/providers/content_state.dart';
import '../lesson/providers/level_providers.dart';
import 'providers/kanji_progress_providers.dart';

/// Dashboard Kanji — màn mặc định của tab Kanji. Toàn bộ số liệu là thật
/// (đọc từ `kanjiListProvider`/`kanjiProgressProvider`, lọc theo cấp độ
/// JLPT đang chọn) — không có "Category theo bộ thủ" (chưa có dữ liệu),
/// không có "AI Recommendation" thật (chưa có AI Kanji Tutor). Mỗi khối tự
/// ẩn khi không có dữ liệu.
class KanjiHomeScreen extends ConsumerWidget {
  const KanjiHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final kanjiAsync = resolveContentList(ref, ref.watch(kanjiListProvider));
    final progressAsync = ref.watch(kanjiProgressProvider);
    final selectedLevel = ref.watch(selectedLevelCodeProvider);

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        title: const Text('Kanji'),
        actions: const [LevelBadge(), SizedBox(width: 12)],
      ),
      body: kanjiAsync.when(
        loading: () => const SectionedHomeSkeleton(),
        error: (e, _) => ErrorState(
          error: e,
          onRetry: () =>
              retryContentSync(ref, streamProvider: kanjiListProvider),
        ),
        data: (all) {
          if (all.isEmpty) {
            return RefreshIndicator(
              onRefresh: () => pullToRefreshContent(context, ref),
              child: EmptyState(
                icon: Icons.edit_outlined,
                title: 'Chưa có Kanji nào cho $selectedLevel',
                message:
                    'Nội dung đang được bổ sung dần. Kéo xuống để làm mới.',
              ),
            );
          }

          final progress =
              progressAsync.valueOrNull ?? const <String, KanjiProgress>{};

          Kanji? continueItem;
          for (final k in all) {
            if (progress[k.id]?.isKnown == null) {
              continueItem = k;
              break;
            }
          }

          final dayIndex =
              DateTime.now().difference(DateTime(DateTime.now().year)).inDays;
          final dailyItem = all[dayIndex % all.length];

          var knownCount = 0;
          var dueCount = 0;
          final starredItems = <Kanji>[];
          final recentEntries = <MapEntry<Kanji, DateTime>>[];
          for (final k in all) {
            final p = progress[k.id];
            if (p?.isKnown == true) knownCount++;
            if (p == null || p.isDueNow) dueCount++;
            if (p?.starred == true) starredItems.add(k);
            if (p?.updatedAt != null) {
              recentEntries.add(MapEntry(k, p!.updatedAt!));
            }
          }
          recentEntries.sort((a, b) => b.value.compareTo(a.value));
          final recentItems = recentEntries.take(5).map((e) => e.key).toList();
          final knownPct = ((knownCount / all.length) * 100).round();

          return RefreshIndicator(
            onRefresh: () => pullToRefreshContent(context, ref),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
              children: [
                InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () => context.push('/kanji'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 13,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: const Row(
                      children: [
                        Icon(
                          Icons.search_rounded,
                          color: AppColors.inkFaint,
                          size: 20,
                        ),
                        SizedBox(width: 10),
                        Text(
                          'Tra chữ Hán, Hán Việt hoặc nghĩa...',
                          style: TextStyle(
                            fontSize: 13.5,
                            color: AppColors.inkFaint,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (continueItem != null) ...[
                  const SizedBox(height: 24),
                  const _SectionLabel('Tiếp tục học'),
                  const SizedBox(height: 10),
                  _ContinueKanjiCard(
                    kanji: continueItem,
                    levelLabel: selectedLevel,
                  ),
                ],
                const SizedBox(height: 24),
                const _SectionLabel('Kanji hôm nay'),
                const SizedBox(height: 10),
                _DailyKanjiCard(kanji: dailyItem),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const _SectionLabel('Tiến độ'),
                    InkWell(
                      onTap: () => context.push('/kanji/statistics'),
                      child: const Text(
                        'Xem thống kê →',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.indigo,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                _KanjiProgressCard(
                  knownCount: knownCount,
                  total: all.length,
                  pct: knownPct,
                ),
                if (dueCount > 0) ...[
                  const SizedBox(height: 24),
                  const _SectionLabel('Cần ôn tập'),
                  const SizedBox(height: 10),
                  _ReviewReminderCard(dueCount: dueCount),
                ],
                if (starredItems.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const _SectionLabel('Đã lưu'),
                      InkWell(
                        onTap: () => context.push('/kanji'),
                        child: const Text(
                          'Xem tất cả',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.indigo,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  _KanjiMiniList(items: starredItems.take(3).toList()),
                ],
                if (recentItems.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  const _SectionLabel('Gần đây'),
                  const SizedBox(height: 10),
                  _KanjiMiniList(items: recentItems),
                ],
                const SizedBox(height: 28),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => context.push('/kanji'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.indigo,
                          side: const BorderSide(color: AppColors.indigo),
                        ),
                        child: const Text('Xem tất cả Kanji'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: FilledButton(
                        onPressed: () => context.push('/kanji/draw'),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.indigo,
                        ),
                        child: const Text('Vẽ tìm Kanji'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: AppColors.inkFaint,
        letterSpacing: 0.6,
      ),
    );
  }
}

class _ContinueKanjiCard extends StatelessWidget {
  const _ContinueKanjiCard({required this.kanji, required this.levelLabel});

  final Kanji kanji;
  final String levelLabel;

  @override
  Widget build(BuildContext context) {
    return PressScale(
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        // extra khác null = mở bộ thẻ vuốt (học tiếp), không phải xem 1 chữ.
        onTap: () => context.push('/kanji/${kanji.id}', extra: 'deck'),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.indigo, Color(0xFF7B61FF)],
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: AppColors.indigo.withValues(alpha: 0.3),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.22),
                  borderRadius: BorderRadius.circular(15),
                ),
                alignment: Alignment.center,
                child: Text(
                  kanji.character,
                  style: AppFonts.zenMaruGothic(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$levelLabel — Vào học ngay',
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      kanji.hanViet.isNotEmpty
                          ? kanji.hanViet.join(' · ')
                          : kanji.primaryMeaning,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.25),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.chevron_right_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DailyKanjiCard extends StatelessWidget {
  const _DailyKanjiCard({required this.kanji});

  final Kanji kanji;

  @override
  Widget build(BuildContext context) {
    return PressScale(
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => context.push('/kanji/${kanji.id}'),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.border, width: 1.0),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.indigoSoft,
                  borderRadius: BorderRadius.circular(14),
                ),
                alignment: Alignment.center,
                child: Text(
                  kanji.character,
                  style: AppFonts.zenMaruGothic(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppColors.indigo,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      kanji.hanViet.isNotEmpty
                          ? kanji.hanViet.join(' · ').toUpperCase()
                          : kanji.character,
                      style: AppFonts.zenMaruGothic(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      kanji.meaningVi.join(', '),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: AppColors.inkSoft,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.inkFaint,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _KanjiProgressCard extends StatelessWidget {
  const _KanjiProgressCard({
    required this.knownCount,
    required this.total,
    required this.pct,
  });

  final int knownCount;
  final int total;
  final int pct;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border, width: 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$knownCount/$total chữ đã thuộc',
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 12.5,
                  color: AppColors.ink,
                ),
              ),
              Text(
                '$pct%',
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 11,
                  color: AppColors.indigo,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          AnimatedProgressBar(
            value: pct / 100,
            minHeight: 8,
            backgroundColor: AppColors.chip,
            color: AppColors.indigo,
          ),
        ],
      ),
    );
  }
}

class _ReviewReminderCard extends StatelessWidget {
  const _ReviewReminderCard({required this.dueCount});

  final int dueCount;

  @override
  Widget build(BuildContext context) {
    return PressScale(
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => context.push('/kanji/review'),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: AppColors.dangerSoft,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.refresh_rounded,
                color: AppColors.danger,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  '$dueCount chữ Kanji cần ôn hôm nay — ôn ngay',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: AppColors.danger,
                  ),
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.danger,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _KanjiMiniList extends StatelessWidget {
  const _KanjiMiniList({required this.items});

  final List<Kanji> items;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border, width: 1.0),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (var i = 0; i < items.length; i++) ...[
            if (i > 0) const Divider(height: 1, color: AppColors.border),
            InkWell(
              onTap: () => context.push('/kanji/${items[i].id}'),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
                child: Row(
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AppColors.indigoSoft,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        items[i].character,
                        style: AppFonts.zenMaruGothic(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppColors.indigo,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            items[i].hanViet.isNotEmpty
                                ? items[i].hanViet.join(' · ')
                                : items[i].character,
                            style: AppFonts.zenMaruGothic(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w700,
                              color: AppColors.ink,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            items[i].meaningVi.join(', '),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.inkSoft,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: AppColors.inkFaint,
                      size: 18,
                    ),
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
