import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/ai_exception.dart';
import '../../../core/theme/app_theme.dart';
import '../providers/ai_insights_providers.dart';
import '../providers/study_report_service.dart';
import '../widgets/profile_section_label.dart';
import '../widgets/weak_area_suggestion_card.dart';

const _sourceTypeLabels = {
  'vocab': 'Từ vựng',
  'kanji': 'Kanji',
  'grammar': 'Ngữ pháp',
};

/// Nhóm "AI" — gồm 2 phần: (1) gợi ý rule-based dựa 100% trên dữ liệu thật
/// đã có (ease factor SM-2 + Mistake Notebook), KHÔNG gọi LLM — giống cách
/// "Smart Review" ở tab Ôn tập đã làm; (2) AI Study Report — gọi Edge
/// Function `ai-study-report` (Gemini/Claude, tái dùng hạ tầng quota của
/// AI Review Coach) để sinh 1 bản nhận xét văn xuôi dựa trên số liệu thật
/// (streak/XP/số mục đã thuộc/điểm yếu), theo yêu cầu người dùng bấm nút
/// (2026-08-07) — không tự động gọi vì tốn quota.
class AiInsightsScreen extends ConsumerWidget {
  const AiInsightsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final weak = ref.watch(weakAreaCountsProvider);
    final topMistakes = ref.watch(topMistakesProvider);

    final hasData = weak.total > 0 || topMistakes.isNotEmpty;

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        backgroundColor: AppColors.canvas,
        title: const Text('AI Insights'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        children: [
          const _StudyReportSection(),
          const SizedBox(height: 22),
          if (!hasData)
            const _EmptyState()
          else ...[
                if (weak.total > 0) ...[
                  WeakAreaSuggestionCard(weak: weak),
                  const SizedBox(height: 22),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const ProfileSectionLabel('Điểm yếu theo kỹ năng'),
                      InkWell(
                        onTap: () => context.push('/review/weak-points'),
                        child: const Padding(
                          padding: EdgeInsets.symmetric(vertical: 2),
                          child: Text(
                            'Xem chi tiết',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppColors.accentStrong,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      _WeakTile(
                        value: weak.vocab,
                        label: 'Từ vựng',
                        color: AppColors.moss,
                      ),
                      const SizedBox(width: 8),
                      _WeakTile(
                        value: weak.kanji,
                        label: 'Kanji',
                        color: AppColors.indigo,
                      ),
                      const SizedBox(width: 8),
                      _WeakTile(
                        value: weak.grammar,
                        label: 'Ngữ pháp',
                        color: AppColors.plum,
                      ),
                    ],
                  ),
                ],
                if (topMistakes.isNotEmpty) ...[
                  const SizedBox(height: 22),
                  const ProfileSectionLabel('Lỗi lặp lại nhiều nhất'),
                  const SizedBox(height: 10),
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius: BorderRadius.circular(16),
                      border:
                          Border.all(color: AppColors.border, width: 1.0),
                    ),
                    child: Column(
                      children: [
                        for (var i = 0; i < topMistakes.length; i++) ...[
                          if (i > 0)
                            const Divider(
                              height: 1,
                              color: AppColors.border,
                            ),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        topMistakes[i].correctAnswer,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w800,
                                          fontSize: 13.5,
                                          color: AppColors.ink,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        _sourceTypeLabels[
                                                topMistakes[i].sourceType] ??
                                            topMistakes[i].sourceType,
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: AppColors.inkSoft,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  '${topMistakes[i].occurrenceCount} lần',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 12,
                                    color: AppColors.danger,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  InkWell(
                    onTap: () => context.push('/review/mistakes'),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        'Xem Sổ tay lỗi đầy đủ',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.accentStrong,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
        ],
      ),
    );
  }
}

/// Nút "Tạo báo cáo" gọi Edge Function `ai-study-report` theo yêu cầu người
/// dùng bấm — không tự động gọi vì mỗi lần gọi tốn quota AI (2/phút, 5/ngày).
/// State chỉ tồn tại trong phiên xem màn hình, không lưu lại report cũ.
class _StudyReportSection extends ConsumerStatefulWidget {
  const _StudyReportSection();

  @override
  ConsumerState<_StudyReportSection> createState() =>
      _StudyReportSectionState();
}

class _StudyReportSectionState extends ConsumerState<_StudyReportSection> {
  String? _report;
  String? _error;
  bool _loading = false;

  Future<void> _generate() async {
    final service = ref.read(studyReportServiceProvider);
    if (service == null) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final stats = ref.read(studyReportStatsProvider);
      final mistakes = ref.read(topMistakesProvider);
      final report = await service.generate(
        stats: stats,
        topMistakes: mistakes,
      );
      if (!mounted) return;
      setState(() {
        _report = report;
        _loading = false;
      });
    } on AiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Lỗi gọi AI, vui lòng thử lại.';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const ProfileSectionLabel('Báo cáo học tập AI'),
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border, width: 1.0),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_report == null && _error == null)
                const Text(
                  'AI tổng hợp streak, XP, số mục đã thuộc và điểm yếu của '
                  'bạn thành một bản nhận xét ngắn.',
                  style: TextStyle(
                    fontSize: 12.5,
                    color: AppColors.inkSoft,
                    height: 1.4,
                  ),
                ),
              if (_report != null)
                Text(
                  _report!,
                  style: const TextStyle(
                    fontSize: 13,
                    height: 1.5,
                    color: AppColors.ink,
                  ),
                ),
              if (_error != null)
                Text(
                  _error!,
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: AppColors.danger,
                  ),
                ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _loading ? null : _generate,
                  icon: _loading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.auto_awesome_rounded, size: 18),
                  label: Text(_report == null ? 'Tạo báo cáo' : 'Tạo lại'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _WeakTile extends StatelessWidget {
  const _WeakTile({
    required this.value,
    required this.label,
    required this.color,
  });

  final int value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border, width: 1.0),
        ),
        child: Column(
          children: [
            Text(
              '$value',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 17,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                color: AppColors.inkSoft,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(20),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.auto_awesome_rounded,
              size: 40,
              color: AppColors.indigo,
            ),
            SizedBox(height: 12),
            Text(
              'Chưa đủ dữ liệu để phân tích',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 15,
                color: AppColors.ink,
              ),
            ),
            SizedBox(height: 6),
            Text(
              'Ôn tập vài buổi để AI Insights bắt đầu\nnhận ra điểm mạnh/yếu của bạn.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12.5, color: AppColors.inkSoft),
            ),
          ],
        ),
      ),
    );
  }
}
