import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../domain/services/jlpt_scoring.dart';
import 'models/exam_review_answer.dart';

/// Điểm thô 1 section (đúng/tổng) — chưa quy đổi theo thang điểm JLPT thật.
class ExamSectionScore {
  const ExamSectionScore({required this.correct, required this.total});

  final int correct;
  final int total;
}

/// Gói dữ liệu truyền qua route `/review/jlpt-exam/result` — cần thêm
/// [levelCode] (khác [ExamRunnerScreen] chỉ có `levelId`) để tra đúng rule
/// trong `jlptScoringRules` (Task 7), và [reviewSections] để hiện lại từng
/// câu đã làm (Task 7.6 — Xem lại bài làm).
class ExamResultArgs {
  const ExamResultArgs({
    required this.score,
    required this.levelCode,
    required this.reviewSections,
  });

  final Map<String, ExamSectionScore> score;
  final String levelCode;
  final List<ExamReviewSection> reviewSections;
}

/// Màn kết quả sau khi nộp bài — hiện điểm thô từng section (chi tiết) +
/// điểm mô phỏng theo thang JLPT thật + Pass/Fail Prediction (Task 7, xem
/// `jlpt_scoring.dart`). Khi [ExamResultArgs.levelCode] chưa có rule công
/// khai (`predictJlptResult` trả null), CHỈ hiện điểm thô — không tự bịa
/// ngưỡng đỗ cho level chưa tra được số liệu.
class ExamResultScreen extends StatelessWidget {
  const ExamResultScreen({required this.args, super.key});

  final ExamResultArgs args;

  static const _sectionLabels = {
    'vocabulary': 'Từ vựng',
    'grammar': 'Ngữ pháp',
    'kanji': 'Kanji',
    'reading': 'Đọc hiểu',
    'listening': 'Nghe hiểu',
  };

  @override
  Widget build(BuildContext context) {
    final score = args.score;
    final totalCorrect = score.values.fold(0, (sum, s) => sum + s.correct);
    final totalQuestions = score.values.fold(0, (sum, s) => sum + s.total);
    final prediction = predictJlptResult(
      levelCode: args.levelCode,
      rawScores: {
        for (final e in score.entries)
          e.key: (correct: e.value.correct, total: e.value.total),
      },
    );

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(title: const Text('Kết quả')),
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
                  '$totalCorrect/$totalQuestions',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 32,
                    color: AppColors.indigo,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Câu trả lời đúng (điểm thô)',
                  style: TextStyle(color: AppColors.inkSoft, fontSize: 13),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (prediction != null) ...[
            _PassFailBadge(prediction: prediction, levelCode: args.levelCode),
            const SizedBox(height: 16),
            Text(
              'Điểm mô phỏng theo thang JLPT (${args.levelCode})',
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
            ),
            const SizedBox(height: 10),
            for (final c in prediction.categoryResults) ...[
              _ScaledScoreRow(result: c),
              const SizedBox(height: 10),
            ],
            const SizedBox(height: 10),
          ] else ...[
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.chip,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    size: 18,
                    color: AppColors.inkSoft,
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Cấp độ này chưa có ngưỡng điểm đỗ công khai trong app, '
                      'nên chỉ hiện điểm thô — chưa có dự đoán đỗ/trượt.',
                      style: TextStyle(fontSize: 12, color: AppColors.inkSoft),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
          const Text(
            'Chi tiết theo phần thi',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
          ),
          const SizedBox(height: 10),
          for (final entry in score.entries) ...[
            _SectionScoreRow(
              label: _sectionLabels[entry.key] ?? entry.key,
              correct: entry.value.correct,
              total: entry.value.total,
            ),
            const SizedBox(height: 10),
          ],
          if (args.reviewSections.isNotEmpty) ...[
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: () => context.push(
                '/review/jlpt-exam/result/review',
                extra: args.reviewSections,
              ),
              icon: const Icon(Icons.fact_check_outlined),
              label: const Text('Xem lại bài làm'),
            ),
          ],
          const SizedBox(height: 10),
          FilledButton(
            onPressed: () => context.go('/'),
            child: const Text('Về trang Ôn tập'),
          ),
        ],
      ),
    );
  }
}

/// Badge Pass/Fail Prediction — LUÔN kèm disclaimer bắt buộc (quyết định
/// docs/JLPT_MOCK_EXAM_DESIGN.md §1, §20 mục 1): đây là ước lượng dựa trên
/// điểm mô phỏng tuyến tính, không phải kết quả thi thật vì JEES không công
/// khai công thức quy đổi thang điểm nội bộ (IRT).
class _PassFailBadge extends StatelessWidget {
  const _PassFailBadge({required this.prediction, required this.levelCode});

  final JlptExamPrediction prediction;
  final String levelCode;

  @override
  Widget build(BuildContext context) {
    final passed = prediction.passed;
    final color = passed ? AppColors.moss : AppColors.danger;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                passed
                    ? Icons.check_circle_rounded
                    : Icons.cancel_rounded,
                color: color,
              ),
              const SizedBox(width: 8),
              Text(
                passed
                    ? 'Có khả năng ĐỖ $levelCode'
                    : 'Có khả năng TRƯỢT $levelCode',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                  color: color,
                ),
              ),
              const Spacer(),
              Text(
                '${prediction.totalScaledScore}/${prediction.totalMaxScore}',
                style: TextStyle(fontWeight: FontWeight.w800, color: color),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Ước lượng dựa trên điểm mô phỏng (quy đổi tuyến tính từ điểm '
            'thô) so với ngưỡng điểm đỗ công khai của JLPT — KHÔNG phải kết '
            'quả thi thật, vì JEES không công khai công thức quy đổi thang '
            'điểm chính xác.',
            style: TextStyle(fontSize: 12, color: color.withValues(alpha: 0.9)),
          ),
        ],
      ),
    );
  }
}

class _ScaledScoreRow extends StatelessWidget {
  const _ScaledScoreRow({required this.result});

  final JlptCategoryResult result;

  @override
  Widget build(BuildContext context) {
    final category = result.category;
    final ratio = category.maxScore == 0
        ? 0.0
        : result.scaledScore / category.maxScore;
    final color = result.passed ? AppColors.indigo : AppColors.danger;
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            category.label,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
          ),
          const SizedBox(height: 4),
          Text(
            '${result.scaledScore}/${category.maxScore}'
            '${result.passed ? '' : ' (dưới điểm liệt ${category.minPassScore})'}',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 13,
              color: color,
            ),
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: ratio.clamp(0.0, 1.0),
              minHeight: 6,
              backgroundColor: AppColors.chip,
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionScoreRow extends StatelessWidget {
  const _SectionScoreRow({
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
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
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
                style:
                    const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
              ),
              Text(
                '$correct/$total',
                style:
                    const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
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
