import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../domain/entities/kanji_progress.dart';
import '../lesson/providers/content_providers.dart';
import 'providers/kanji_progress_providers.dart';

/// Thống kê Kanji — số liệu thật tính từ `kanjiListProvider`/
/// `kanjiProgressProvider`, không có provider/bảng riêng nào mới. Phân bố
/// độ thành thục dùng đúng `intervalDays` thật do SRS tính ra (xem
/// `srs_scheduler.dart`), không phải số liệu tự chọn.
class KanjiStatisticsScreen extends ConsumerWidget {
  const KanjiStatisticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final kanjiAsync = ref.watch(kanjiListProvider);
    final progressAsync = ref.watch(kanjiProgressProvider);

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(title: const Text('Thống kê Kanji')),
      body: kanjiAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Lỗi: $e')),
        data: (all) {
          if (all.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Chưa có Kanji nào cho cấp độ này.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.inkSoft),
                ),
              ),
            );
          }

          final progress =
              progressAsync.valueOrNull ?? const <String, KanjiProgress>{};

          var knownCount = 0;
          var dueCount = 0;
          var starredCount = 0;
          var totalReviews = 0;
          var newCount = 0;
          var learningCount = 0;
          var familiarCount = 0;
          var masteredCount = 0;

          for (final k in all) {
            final p = progress[k.id];
            if (p?.isKnown == true) knownCount++;
            if (p?.starred == true) starredCount++;
            if (p == null || p.isDueNow) dueCount++;
            totalReviews += p?.reviewCount ?? 0;

            final interval = p?.intervalDays ?? 0;
            if (interval < 1) {
              newCount++;
            } else if (interval < 7) {
              learningCount++;
            } else if (interval < 30) {
              familiarCount++;
            } else {
              masteredCount++;
            }
          }

          final knownPct = ((knownCount / all.length) * 100).round();

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
            children: [
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.5,
                children: [
                  _StatCard(
                    label: 'Đã thuộc',
                    value: '$knownCount/${all.length}',
                    sub: '$knownPct%',
                    color: AppColors.indigo,
                  ),
                  _StatCard(
                    label: 'Cần ôn hôm nay',
                    value: '$dueCount',
                    sub: 'chữ',
                    color: AppColors.danger,
                  ),
                  _StatCard(
                    label: 'Đã lưu',
                    value: '$starredCount',
                    sub: 'chữ',
                    color: AppColors.accent,
                  ),
                  _StatCard(
                    label: 'Tổng lượt ôn',
                    value: '$totalReviews',
                    sub: 'lượt',
                    color: AppColors.moss,
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const _SectionLabel('Độ thành thục (theo SRS)'),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  children: [
                    _MasteryBar(
                      label: 'Mới',
                      count: newCount,
                      total: all.length,
                      color: AppColors.inkFaint,
                    ),
                    const SizedBox(height: 12),
                    _MasteryBar(
                      label: 'Đang học (< 7 ngày)',
                      count: learningCount,
                      total: all.length,
                      color: AppColors.danger,
                    ),
                    const SizedBox(height: 12),
                    _MasteryBar(
                      label: 'Quen (< 30 ngày)',
                      count: familiarCount,
                      total: all.length,
                      color: AppColors.accent,
                    ),
                    const SizedBox(height: 12),
                    _MasteryBar(
                      label: 'Vững (≥ 30 ngày)',
                      count: masteredCount,
                      total: all.length,
                      color: AppColors.moss,
                    ),
                  ],
                ),
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

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.sub,
    required this.color,
  });

  final String label;
  final String value;
  final String sub;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 11.5, color: AppColors.inkSoft),
          ),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: color,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                sub,
                style: const TextStyle(fontSize: 11, color: AppColors.inkFaint),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MasteryBar extends StatelessWidget {
  const _MasteryBar({
    required this.label,
    required this.count,
    required this.total,
    required this.color,
  });

  final String label;
  final int count;
  final int total;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final ratio = total == 0 ? 0.0 : count / total;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 12.5, color: AppColors.ink),
            ),
            Text(
              '$count',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 12.5,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(100),
          child: LinearProgressIndicator(
            value: ratio,
            minHeight: 7,
            backgroundColor: AppColors.chip,
            valueColor: AlwaysStoppedAnimation(color),
          ),
        ),
      ],
    );
  }
}
