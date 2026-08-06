import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../domain/entities/review_mistake.dart';
import '../grammar/providers/grammar_progress_providers.dart';
import '../home/providers/profile_providers.dart';
import '../kanji/providers/kanji_progress_providers.dart';
import '../vocabulary/providers/vocab_progress_providers.dart';
import 'jlpt_exam/mini_test/models/mini_test_variant.dart';
import 'jlpt_exam/providers/jlpt_exam_session_providers.dart';
import 'providers/review_mistakes_providers.dart';

const _hiddenAxis = AxisTitles(sideTitles: SideTitles(showTitles: false));

/// Review Statistics — tầng tổng hợp phía trên (`docs/REVIEW_DESIGN.md`
/// §15.12), không tách riêng theo module như `kanji/statistics` đang làm.
/// Toàn bộ số liệu/biểu đồ đều tính từ dữ liệu thật đã có sẵn (progress 3
/// module + `review_mistakes`) — không có snapshot/log riêng theo ngày nên
/// KHÔNG hiển thị Retention Rate/Study Time/JLPT theo cấp (chưa có dữ liệu
/// nguồn thật cho các mục này, xem §16 "Cần xác nhận").
class ReviewStatisticsScreen extends ConsumerWidget {
  const ReviewStatisticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vocabAsync = ref.watch(vocabProgressProvider);
    final kanjiAsync = ref.watch(kanjiProgressProvider);
    final grammarAsync = ref.watch(grammarProgressProvider);
    final mistakesAsync = ref.watch(reviewMistakesProvider);
    final profile = ref.watch(profileProvider).valueOrNull;
    final miniTestStats = ref.watch(miniTestStatsProvider).valueOrNull;

    final loading = vocabAsync.isLoading ||
        kanjiAsync.isLoading ||
        grammarAsync.isLoading ||
        mistakesAsync.isLoading;
    if (loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final vocab = vocabAsync.valueOrNull ?? const {};
    final kanji = kanjiAsync.valueOrNull ?? const {};
    final grammar = grammarAsync.valueOrNull ?? const {};
    final mistakes = mistakesAsync.valueOrNull ?? const <ReviewMistake>[];

    final touchedTotal = vocab.length + kanji.length + grammar.length;
    final knownTotal = vocab.values.where((p) => p.isKnown == true).length +
        kanji.values.where((p) => p.isKnown == true).length +
        grammar.values.where((p) => p.isKnown == true).length;
    final reviewTotal = vocab.values.fold(0, (s, p) => s + p.reviewCount) +
        kanji.values.fold(0, (s, p) => s + p.reviewCount) +
        grammar.values.fold(0, (s, p) => s + p.reviewCount);

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(title: const Text('Thống kê ôn tập')),
      body: ListView(
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
                value: '$knownTotal/$touchedTotal',
                sub: 'mục',
                color: AppColors.moss,
              ),
              _StatCard(
                label: 'Tổng lượt ôn',
                value: '$reviewTotal',
                sub: 'lượt',
                color: AppColors.indigo,
              ),
              _StatCard(
                label: 'Chuỗi ngày',
                value: '${profile?.streakCount ?? 0}',
                sub: 'ngày',
                color: AppColors.accent,
              ),
              _StatCard(
                label: 'Lỗi đã ghi nhận',
                value: '${mistakes.length}',
                sub: 'lỗi',
                color: AppColors.danger,
              ),
            ],
          ),
          const SizedBox(height: 24),
          const _SectionLabel('Độ thành thục theo module (SRS)'),
          const SizedBox(height: 10),
          if (touchedTotal == 0)
            const _EmptyChartCard(text: 'Ôn thử vài mục để thấy biểu đồ này.')
          else
            _MasteryChart(
              vocab: vocab.values,
              kanji: kanji.values,
              grammar: grammar.values,
            ),
          const SizedBox(height: 24),
          const _SectionLabel('Lỗi theo module'),
          const SizedBox(height: 10),
          if (mistakes.isEmpty)
            const _EmptyChartCard(text: 'Chưa có lỗi nào được ghi nhận.')
          else
            _MistakesBySourceChart(mistakes: mistakes),
          const SizedBox(height: 24),
          const _SectionLabel('Lỗi ghi nhận theo ngày (14 ngày qua)'),
          const SizedBox(height: 10),
          if (mistakes.isEmpty)
            const _EmptyChartCard(text: 'Chưa có lỗi nào được ghi nhận.')
          else
            _MistakesByDayChart(mistakes: mistakes),
          const SizedBox(height: 24),
          const _SectionLabel('Mini Test JLPT'),
          const SizedBox(height: 10),
          if (miniTestStats == null || miniTestStats.totalCount == 0)
            const _EmptyChartCard(
              text: 'Làm thử 1 Mini Test JLPT để thấy số liệu ở đây.',
            )
          else
            _MiniTestStatsCard(stats: miniTestStats),
        ],
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

/// Lát cắt Mini Test trong Thống kê ôn tập (docs/JLPT_MINI_TEST_DESIGN.md
/// §10, Task 10) — tile số liệu cơ bản (MVP), KHÔNG làm Heatmap Calendar
/// (mở rộng, phụ thuộc gap `fl_chart` đã ghi ở §10/§21). Streak dùng chung
/// `profiles.streak_count` đã hiện ở đầu màn, không lặp lại ở đây.
class _MiniTestStatsCard extends StatelessWidget {
  const _MiniTestStatsCard({required this.stats});

  final MiniTestStats stats;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _MiniStatTile(label: 'Tổng lượt', value: '${stats.totalCount}'),
              ),
              Expanded(
                child: _MiniStatTile(label: 'Tuần này', value: '${stats.weeklyCount}'),
              ),
              Expanded(
                child: _MiniStatTile(
                  label: 'Trung bình',
                  value: '${(stats.avgAccuracy * 100).round()}%',
                ),
              ),
              Expanded(
                child: _MiniStatTile(
                  label: 'Tốt nhất',
                  value: '${(stats.bestAccuracy * 100).round()}%',
                ),
              ),
            ],
          ),
          if (stats.byVariant.isNotEmpty) ...[
            const SizedBox(height: 14),
            const Divider(height: 1, color: AppColors.border),
            const SizedBox(height: 10),
            for (final variant in MiniTestVariant.values)
              if (stats.byVariant[variant.name] case final v?)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          variant.label,
                          style: const TextStyle(fontSize: 12.5, color: AppColors.ink),
                        ),
                      ),
                      Text(
                        '${v.count} lượt · TB ${(v.avgAccuracy * 100).round()}%',
                        style: const TextStyle(fontSize: 11.5, color: AppColors.inkSoft),
                      ),
                    ],
                  ),
                ),
          ],
        ],
      ),
    );
  }
}

class _MiniStatTile extends StatelessWidget {
  const _MiniStatTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: AppColors.accentStrong,
          ),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 10.5, color: AppColors.inkFaint),
        ),
      ],
    );
  }
}

class _EmptyChartCard extends StatelessWidget {
  const _EmptyChartCard({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 12.5, color: AppColors.inkSoft),
      ),
    );
  }
}

/// Chia mỗi mục đã ôn vào 1 trong 4 mức thành thục theo `intervalDays` thật
/// do SRS tính ra — cùng ngưỡng với `KanjiStatisticsScreen` để nhất quán.
int _masteryBucket(double intervalDays) {
  if (intervalDays < 1) return 0; // Mới
  if (intervalDays < 7) return 1; // Đang học
  if (intervalDays < 30) return 2; // Quen
  return 3; // Vững
}

const _masteryColors = [
  AppColors.inkFaint,
  AppColors.danger,
  AppColors.accent,
  AppColors.moss,
];
const _masteryLabels = ['Mới', 'Đang học', 'Quen', 'Vững'];

class _MasteryChart extends StatelessWidget {
  const _MasteryChart({
    required this.vocab,
    required this.kanji,
    required this.grammar,
  });

  final Iterable<dynamic> vocab;
  final Iterable<dynamic> kanji;
  final Iterable<dynamic> grammar;

  List<int> _buckets(Iterable<dynamic> items) {
    final counts = [0, 0, 0, 0];
    for (final p in items) {
      counts[_masteryBucket((p.intervalDays as double?) ?? 0)]++;
    }
    return counts;
  }

  BarChartGroupData _group(int x, List<int> counts, double maxY) {
    var from = 0.0;
    final items = <BarChartRodStackItem>[];
    for (var i = 0; i < counts.length; i++) {
      final to = from + counts[i];
      if (counts[i] > 0) {
        items.add(BarChartRodStackItem(from, to, _masteryColors[i]));
      }
      from = to;
    }
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: from == 0 ? 0.2 : from,
          width: 40,
          borderRadius: BorderRadius.circular(6),
          rodStackItems: items,
          color: AppColors.chip,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final vocabCounts = _buckets(vocab);
    final kanjiCounts = _buckets(kanji);
    final grammarCounts = _buckets(grammar);
    final maxY = [vocabCounts, kanjiCounts, grammarCounts]
        .map((c) => c.fold(0, (s, v) => s + v))
        .fold(1, (a, b) => a > b ? a : b)
        .toDouble();

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 16, 12, 4),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          AspectRatio(
            aspectRatio: 1.5,
            child: BarChart(
              BarChartData(
                maxY: maxY * 1.2,
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                barTouchData: BarTouchData(enabled: false),
                titlesData: FlTitlesData(
                  leftTitles: _hiddenAxis,
                  rightTitles: _hiddenAxis,
                  topTitles: _hiddenAxis,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        const labels = ['Từ vựng', 'Kanji', 'Ngữ pháp'];
                        final i = value.toInt();
                        if (i < 0 || i >= labels.length) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            labels[i],
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.inkSoft,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                barGroups: [
                  _group(0, vocabCounts, maxY),
                  _group(1, kanjiCounts, maxY),
                  _group(2, grammarCounts, maxY),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 12,
            children: [
              for (var i = 0; i < _masteryLabels.length; i++)
                _LegendDot(color: _masteryColors[i], label: _masteryLabels[i]),
            ],
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 10.5, color: AppColors.inkSoft),
        ),
      ],
    );
  }
}

class _MistakesBySourceChart extends StatelessWidget {
  const _MistakesBySourceChart({required this.mistakes});

  final List<ReviewMistake> mistakes;

  @override
  Widget build(BuildContext context) {
    final counts = {'vocab': 0, 'kanji': 0, 'grammar': 0};
    for (final m in mistakes) {
      counts[m.sourceType] = (counts[m.sourceType] ?? 0) + 1;
    }
    const colors = {
      'vocab': AppColors.moss,
      'kanji': AppColors.indigo,
      'grammar': AppColors.plum,
    };
    const labels = {
      'vocab': 'Từ vựng',
      'kanji': 'Kanji',
      'grammar': 'Ngữ pháp',
    };
    final keys = ['vocab', 'kanji', 'grammar'];
    final maxY = counts.values.fold(1, (a, b) => a > b ? a : b).toDouble();

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 16, 12, 8),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: AspectRatio(
        aspectRatio: 1.6,
        child: BarChart(
          BarChartData(
            maxY: maxY * 1.2,
            gridData: const FlGridData(show: false),
            borderData: FlBorderData(show: false),
            barTouchData: BarTouchData(enabled: false),
            titlesData: FlTitlesData(
              leftTitles: _hiddenAxis,
              rightTitles: _hiddenAxis,
              topTitles: _hiddenAxis,
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (value, meta) {
                    final i = value.toInt();
                    if (i < 0 || i >= keys.length) {
                      return const SizedBox.shrink();
                    }
                    return Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        labels[keys[i]]!,
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.inkSoft,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            barGroups: [
              for (var i = 0; i < keys.length; i++)
                BarChartGroupData(
                  x: i,
                  barRods: [
                    BarChartRodData(
                      toY: counts[keys[i]]!.toDouble(),
                      width: 40,
                      borderRadius: BorderRadius.circular(6),
                      color: colors[keys[i]],
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MistakesByDayChart extends StatelessWidget {
  const _MistakesByDayChart({required this.mistakes});

  final List<ReviewMistake> mistakes;

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    final counts = List<int>.filled(14, 0);
    for (final m in mistakes) {
      final d = DateTime(m.updatedAt.year, m.updatedAt.month, m.updatedAt.day);
      final diff = todayDate.difference(d).inDays;
      if (diff >= 0 && diff < 14) counts[13 - diff]++;
    }
    final maxY = counts.fold(1, (a, b) => a > b ? a : b).toDouble();

    return Container(
      padding: const EdgeInsets.fromLTRB(8, 16, 8, 8),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: AspectRatio(
        aspectRatio: 1.7,
        child: BarChart(
          BarChartData(
            maxY: maxY * 1.2,
            gridData: const FlGridData(show: false),
            borderData: FlBorderData(show: false),
            barTouchData: BarTouchData(enabled: false),
            titlesData: FlTitlesData(
              leftTitles: _hiddenAxis,
              rightTitles: _hiddenAxis,
              topTitles: _hiddenAxis,
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  interval: 3,
                  getTitlesWidget: (value, meta) {
                    final i = value.toInt();
                    if (i < 0 || i > 13) return const SizedBox.shrink();
                    final d = todayDate.subtract(Duration(days: 13 - i));
                    return Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        '${d.day}/${d.month}',
                        style: const TextStyle(
                          fontSize: 9.5,
                          color: AppColors.inkSoft,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            barGroups: [
              for (var i = 0; i < 14; i++)
                BarChartGroupData(
                  x: i,
                  barRods: [
                    BarChartRodData(
                      toY: counts[i].toDouble(),
                      width: 14,
                      borderRadius: BorderRadius.circular(4),
                      color: AppColors.accentStrong,
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
