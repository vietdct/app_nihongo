import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../../domain/entities/grammar_point.dart';
import '../../domain/entities/grammar_progress.dart';
import '../../shared/level_badge.dart';
import '../../shared/motion/animated_progress_bar.dart';
import '../../shared/motion/press_scale.dart';
import '../../shared/skeleton_layouts.dart';
import '../lesson/providers/content_providers.dart';
import '../lesson/providers/level_providers.dart';
import 'providers/grammar_progress_providers.dart';

/// Dashboard ngữ pháp — màn mặc định của tab Grammar. Toàn bộ số liệu là
/// thật (đọc từ `grammarListProvider`/`grammarProgressProvider`, lọc theo
/// cấp độ JLPT đang chọn) — không có mục nào ở đây được bịa: không có
/// "Category" (chưa có cột category), không có "AI Recommendation" thật
/// (chưa có AI Grammar Tutor). Mỗi khối tự ẩn khi không có dữ liệu.
class GrammarHomeScreen extends ConsumerWidget {
  const GrammarHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final grammarAsync = ref.watch(grammarListProvider);
    final progressAsync = ref.watch(grammarProgressProvider);
    final selectedLevel = ref.watch(selectedLevelCodeProvider);

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        title: const Text('Ngữ pháp'),
        actions: const [LevelBadge(), SizedBox(width: 12)],
      ),
      body: grammarAsync.when(
        loading: () => const SectionedHomeSkeleton(),
        error: (e, _) => Center(child: Text('Lỗi: $e')),
        data: (all) {
          if (all.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Chưa có ngữ pháp nào cho $selectedLevel.\nNội dung đang được bổ sung dần.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.inkSoft),
                ),
              ),
            );
          }

          final progress =
              progressAsync.valueOrNull ?? const <String, GrammarProgress>{};

          GrammarPoint? continueItem;
          for (final g in all) {
            if (progress[g.id]?.isKnown == null) {
              continueItem = g;
              break;
            }
          }

          final dayIndex =
              DateTime.now().difference(DateTime(DateTime.now().year)).inDays;
          final dailyItem = all[dayIndex % all.length];

          var knownCount = 0;
          var dueCount = 0;
          final starredItems = <GrammarPoint>[];
          final recentEntries = <MapEntry<GrammarPoint, DateTime>>[];
          for (final g in all) {
            final p = progress[g.id];
            if (p?.isKnown == true) knownCount++;
            if (p == null || p.isDueNow) dueCount++;
            if (p?.starred == true) starredItems.add(g);
            if (p?.updatedAt != null) {
              recentEntries.add(MapEntry(g, p!.updatedAt!));
            }
          }
          recentEntries.sort((a, b) => b.value.compareTo(a.value));
          final recentItems = recentEntries.take(5).map((e) => e.key).toList();
          final knownPct = ((knownCount / all.length) * 100).round();

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
            children: [
              InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () => context.push('/grammar'),
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
                        'Tra tiêu đề hoặc giải thích ngữ pháp...',
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
                _ContinueGrammarCard(
                  grammar: continueItem,
                  levelLabel: selectedLevel,
                ),
              ],
              const SizedBox(height: 24),
              const _SectionLabel('Ngữ pháp hôm nay'),
              const SizedBox(height: 10),
              _DailyGrammarCard(grammar: dailyItem),
              const SizedBox(height: 24),
              const _SectionLabel('Tiến độ'),
              const SizedBox(height: 10),
              _GrammarProgressCard(
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
                      onTap: () => context.push('/grammar'),
                      child: const Text(
                        'Xem tất cả',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.plum,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                _GrammarMiniList(items: starredItems.take(3).toList()),
              ],
              if (recentItems.isNotEmpty) ...[
                const SizedBox(height: 24),
                const _SectionLabel('Gần đây'),
                const SizedBox(height: 10),
                _GrammarMiniList(items: recentItems),
              ],
              const SizedBox(height: 28),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => context.push('/grammar'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.plum,
                        side: const BorderSide(color: AppColors.plum),
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                      ),
                      child: const Text(
                        'Xem tất cả',
                        style: TextStyle(fontSize: 12.5),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: PressScale(
                      child: FilledButton(
                        onPressed: () => context.push('/grammar/practice'),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.plum,
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                        ),
                        child: const Text(
                          'Luyện tập',
                          style: TextStyle(fontSize: 12.5),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: PressScale(
                      child: FilledButton(
                        onPressed: () => context.push('/grammar/flashcards'),
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF8A3B70),
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                        ),
                        child: const Text(
                          'Flashcard',
                          style: TextStyle(fontSize: 12.5),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
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

class _ContinueGrammarCard extends StatelessWidget {
  const _ContinueGrammarCard({required this.grammar, required this.levelLabel});

  final GrammarPoint grammar;
  final String levelLabel;

  @override
  Widget build(BuildContext context) {
    return PressScale(
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => context.push('/grammar/${grammar.id}'),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.plum, Color(0xFF8A3B70)],
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: AppColors.plum.withValues(alpha: 0.3),
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
                child: const Icon(
                  Icons.description_rounded,
                  color: Colors.white,
                  size: 24,
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
                      grammar.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppFonts.zenMaruGothic(
                        fontSize: 16,
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

class _DailyGrammarCard extends StatelessWidget {
  const _DailyGrammarCard({required this.grammar});

  final GrammarPoint grammar;

  @override
  Widget build(BuildContext context) {
    return PressScale(
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => context.push('/grammar/${grammar.id}'),
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
                  color: AppColors.plumSoft,
                  borderRadius: BorderRadius.circular(14),
                ),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.auto_stories_rounded,
                  color: AppColors.plum,
                  size: 20,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      grammar.title,
                      style: AppFonts.zenMaruGothic(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      grammar.explanation,
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

class _GrammarProgressCard extends StatelessWidget {
  const _GrammarProgressCard({
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
                '$knownCount/$total điểm đã thuộc',
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
                  color: AppColors.plum,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          AnimatedProgressBar(
            value: pct / 100,
            minHeight: 8,
            backgroundColor: AppColors.chip,
            color: AppColors.plum,
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
        onTap: () => context.push('/grammar/review'),
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
                  '$dueCount mẫu ngữ pháp cần ôn hôm nay — ôn ngay',
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

class _GrammarMiniList extends StatelessWidget {
  const _GrammarMiniList({required this.items});

  final List<GrammarPoint> items;

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
              onTap: () => context.push('/grammar/${items[i].id}'),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            items[i].title,
                            style: AppFonts.zenMaruGothic(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w700,
                              color: AppColors.ink,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            items[i].explanation,
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
