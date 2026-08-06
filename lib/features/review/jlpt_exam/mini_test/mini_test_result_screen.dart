import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../domain/entities/lesson.dart';
import '../../../home/providers/profile_providers.dart';
import '../models/exam_review_answer.dart';
import 'mini_test_xp_controller.dart';
import 'models/mini_test_blueprint.dart';
import 'models/mini_test_variant.dart';

/// Gói dữ liệu truyền qua route kết quả Mini Test — khác `ExamResultArgs`
/// (Full Exam): KHÔNG có PassFail/scaledScore (docs/JLPT_MINI_TEST_DESIGN.md
/// §1, §9) vì 5-20 câu không đủ đại diện 1 đề JLPT thật.
class MiniTestResultArgs {
  const MiniTestResultArgs({
    required this.levelId,
    required this.variant,
    required this.questionCount,
    required this.sources,
    required this.reviewSections,
  });

  final String levelId;
  final MiniTestVariant variant;
  final int questionCount;
  final List<String> sources;
  final List<ExamReviewSection> reviewSections;
}

/// Result Screen rút gọn cho Mini Test (docs §9, §14) — chỉ Accuracy %,
/// đúng/tổng, breakdown theo dimension (Từ vựng/Ngữ pháp/Kanji), XP/Streak
/// thật (ghi qua [MiniTestXpController], docs §21 Task 5), nút "Làm lại"
/// (sinh đề MỚI, không lặp lại đúng bộ câu vừa làm — đúng nguyên tắc §1
/// "mỗi đề luôn khác nhau").
class MiniTestResultScreen extends ConsumerStatefulWidget {
  const MiniTestResultScreen({required this.args, super.key});

  final MiniTestResultArgs args;

  @override
  ConsumerState<MiniTestResultScreen> createState() =>
      _MiniTestResultScreenState();
}

class _MiniTestResultScreenState extends ConsumerState<MiniTestResultScreen> {
  bool _retrying = false;
  bool _awarding = true;
  int _xpEarned = 0;
  int _streakCount = 0;

  static const _xpPerCorrect = 10;

  static const _dimensionLabels = {
    LessonItemType.vocabulary: 'Từ vựng',
    LessonItemType.grammar: 'Ngữ pháp',
    LessonItemType.kanji: 'Kanji',
  };

  @override
  void initState() {
    super.initState();
    unawaited(_awardXpAndStreak());
  }

  Future<void> _awardXpAndStreak() async {
    final controller = ref.read(miniTestXpControllerProvider);
    if (controller == null) {
      setState(() => _awarding = false);
      return;
    }
    final answers = [
      for (final s in widget.args.reviewSections) ...s.answers,
    ];
    final correctCount = answers.where((a) => a.isCorrect).length;
    final correctXp = correctCount * _xpPerCorrect;
    if (correctXp > 0) await controller.addXp(correctXp);
    final completion = await controller.completeMiniTestToday();
    if (!mounted) return;
    ref.invalidate(profileProvider);
    setState(() {
      _xpEarned =
          correctXp + (completion.dailyBonusAwarded ? MiniTestXpController.dailyBonusXp : 0);
      _streakCount = completion.streakCount;
      _awarding = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final answers = [
      for (final s in widget.args.reviewSections) ...s.answers,
    ];
    final total = answers.length;
    final correct = answers.where((a) => a.isCorrect).length;
    final accuracyPct = total == 0 ? 0 : (correct / total * 100).round();

    final byDimension = <String, ({int correct, int total})>{};
    for (final a in answers) {
      final label = _dimensionLabels[a.question.sourceType] ?? 'Khác';
      final cur = byDimension[label] ?? (correct: 0, total: 0);
      byDimension[label] = (
        correct: cur.correct + (a.isCorrect ? 1 : 0),
        total: cur.total + 1,
      );
    }

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(title: Text('Hoàn thành ${widget.args.variant.label}')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.indigoSoft,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              children: [
                Text(
                  '$correct/$total',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 32,
                    color: AppColors.indigo,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$accuracyPct% chính xác',
                  style: const TextStyle(color: AppColors.inkSoft, fontSize: 13),
                ),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _MiniStat(
                      label: 'XP',
                      value: _awarding ? '…' : '+$_xpEarned',
                    ),
                    const SizedBox(width: 28),
                    _MiniStat(
                      label: 'Streak',
                      value: _awarding ? '…' : '$_streakCount ngày',
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (byDimension.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Text(
              'Theo từng phần',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
            ),
            const SizedBox(height: 10),
            for (final e in byDimension.entries) ...[
              _DimensionRow(label: e.key, correct: e.value.correct, total: e.value.total),
              const SizedBox(height: 10),
            ],
          ],
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => context.pop(),
                  child: const Text('Về Mini Test'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: _retrying ? null : _retry,
                  child: _retrying
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Làm lại'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _retry() async {
    setState(() => _retrying = true);
    final blueprint = MiniTestBlueprint(
      levelId: widget.args.levelId,
      variant: widget.args.variant,
      questionCount: widget.args.questionCount,
      sources: widget.args.sources,
    );
    final sections = await buildMiniTestRunSections(ref, blueprint);
    if (!mounted) return;
    if (sections.isEmpty) {
      setState(() => _retrying = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Chưa đủ nội dung để tạo đề mới.')),
      );
      return;
    }
    context.pushReplacement(
      '/review/jlpt-exam/${widget.args.levelId}/session/${blueprint.sessionMode}',
      extra: sections,
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 16,
            color: AppColors.indigo,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(color: AppColors.inkSoft, fontSize: 11),
        ),
      ],
    );
  }
}

class _DimensionRow extends StatelessWidget {
  const _DimensionRow({
    required this.label,
    required this.correct,
    required this.total,
  });

  final String label;
  final int correct;
  final int total;

  @override
  Widget build(BuildContext context) {
    final ratio = total == 0 ? 0.0 : correct / total;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
              ),
              Text(
                '$correct/$total',
                style: const TextStyle(color: AppColors.inkSoft, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: ratio,
              minHeight: 6,
              backgroundColor: AppColors.chip,
              valueColor: const AlwaysStoppedAnimation(AppColors.indigo),
            ),
          ),
        ],
      ),
    );
  }
}
