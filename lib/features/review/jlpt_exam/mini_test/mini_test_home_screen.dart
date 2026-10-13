import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../home/providers/profile_providers.dart';
import '../../../lesson/providers/level_providers.dart';
import '../providers/jlpt_exam_session_providers.dart';
import 'mini_test_settings_sheet.dart';
import 'models/mini_test_blueprint.dart';
import 'models/mini_test_variant.dart';

/// Home Screen của Mini Test — mở từ nút "Mini Test" ở `JlptExamModeScreen`.
/// Quick 5 chạy full luồng thật không qua Settings sheet (docs §2). Daily/
/// Weak Point Mini Test (Task 6-8) đều mở `MiniTestSettingsSheet` trước khi
/// build đề. AI Mini Test đã bỏ khỏi phạm vi theo yêu cầu người dùng
/// (2026-08-06) — dừng ở 3 biến thể.
class MiniTestHomeScreen extends ConsumerStatefulWidget {
  const MiniTestHomeScreen({required this.levelId, super.key});

  final String levelId;

  @override
  ConsumerState<MiniTestHomeScreen> createState() => _MiniTestHomeScreenState();
}

class _MiniTestHomeScreenState extends ConsumerState<MiniTestHomeScreen> {
  bool _startingQuick5 = false;
  bool _startingDaily = false;
  bool _startingWeakPoint = false;

  Future<void> _startQuick5() async {
    if (_startingQuick5) return;
    setState(() => _startingQuick5 = true);

    final blueprint = MiniTestBlueprint(
      levelId: widget.levelId,
      variant: MiniTestVariant.quick5,
      questionCount: 5,
      sources: const ['vocabulary', 'grammar'],
    );
    final sections = await buildMiniTestRunSections(ref, blueprint);

    if (!mounted) return;
    setState(() => _startingQuick5 = false);

    if (sections.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Chưa đủ nội dung Từ vựng/Ngữ pháp để tạo Quick 5 cho cấp độ này.'),
        ),
      );
      return;
    }

    context.push(
      '/review/jlpt-exam/${widget.levelId}/session/${blueprint.sessionMode}',
      extra: sections,
    );
  }

  Future<void> _startDaily() async {
    if (_startingDaily) return;
    final settings = await showModalBottomSheet<MiniTestSettings>(
      context: context,
      backgroundColor: AppColors.card,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => const MiniTestSettingsSheet(variant: MiniTestVariant.daily),
    );
    if (settings == null || !mounted) return;

    setState(() => _startingDaily = true);
    final blueprint = MiniTestBlueprint(
      levelId: widget.levelId,
      variant: MiniTestVariant.daily,
      questionCount: settings.questionCount,
      sources: settings.sources,
      timerMode: settings.timerMode,
    );
    final sections = await buildMiniTestRunSections(ref, blueprint);

    if (!mounted) return;
    setState(() => _startingDaily = false);

    if (sections.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Chưa đủ nội dung cho các nguồn câu đã chọn.'),
        ),
      );
      return;
    }

    context.push(
      '/review/jlpt-exam/${widget.levelId}/session/${blueprint.sessionMode}',
      extra: sections,
    );
  }

  Future<void> _startWeakPoint() async {
    if (_startingWeakPoint) return;
    final settings = await showModalBottomSheet<MiniTestSettings>(
      context: context,
      backgroundColor: AppColors.card,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => const MiniTestSettingsSheet(variant: MiniTestVariant.weakPoint),
    );
    if (settings == null || !mounted) return;

    setState(() => _startingWeakPoint = true);
    final blueprint = MiniTestBlueprint(
      levelId: widget.levelId,
      variant: MiniTestVariant.weakPoint,
      questionCount: settings.questionCount,
      sources: settings.sources,
      timerMode: settings.timerMode,
    );
    final result = await buildWeakPointMiniTestRunSections(ref, blueprint);

    if (!mounted) return;
    setState(() => _startingWeakPoint = false);

    if (result.sections.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Chưa đủ nội dung cho các nguồn câu đã chọn.'),
        ),
      );
      return;
    }

    if (result.usedFallback) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Chưa đủ $weakPointMiniTestThreshold mục điểm yếu, đã chuyển sang đề ngẫu nhiên.',
          ),
        ),
      );
    }

    context.push(
      '/review/jlpt-exam/${widget.levelId}/session/${blueprint.sessionMode}',
      extra: result.sections,
    );
  }

  @override
  Widget build(BuildContext context) {
    final levels = ref.watch(jlptLevelsProvider).valueOrNull;
    var levelCode = '';
    if (levels != null) {
      for (final level in levels) {
        if (level.id == widget.levelId) {
          levelCode = level.code;
          break;
        }
      }
    }

    final profile = ref.watch(profileProvider).valueOrNull;
    final lastScore =
        ref.watch(lastMiniTestScoreProvider(widget.levelId)).valueOrNull;
    final streakText = profile == null ? '—' : '${profile.streakCount} ngày';
    final accuracyText = lastScore == null || lastScore.total == 0
        ? '—'
        : '${(lastScore.correct / lastScore.total * 100).round()}%';

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        title: Text(levelCode.isEmpty ? 'Mini Test' : 'Mini Test — $levelCode'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _MiniTestHeroCard(
            streakText: streakText,
            accuracyText: accuracyText,
            onQuickStart: _startingQuick5 ? null : _startQuick5,
          ),
          const SizedBox(height: 20),
          _MiniTestVariantRow(
            icon: Icons.bolt_rounded,
            iconColor: AppColors.accent,
            iconBg: AppColors.accentSoft,
            title: '⚡ Quick 5',
            subtitle: '2-3 phút · 5 câu ngẫu nhiên để khởi động',
            onTap: _startingQuick5 ? null : _startQuick5,
            loading: _startingQuick5,
          ),
          const SizedBox(height: 10),
          _MiniTestVariantRow(
            icon: Icons.menu_book_rounded,
            iconColor: AppColors.indigo,
            iconBg: AppColors.indigoSoft,
            title: '📚 Daily Mini Test',
            subtitle: '5-10 phút · Đề luyện hằng ngày theo lộ trình',
            onTap: _startingDaily ? null : _startDaily,
            loading: _startingDaily,
          ),
          const SizedBox(height: 10),
          _MiniTestVariantRow(
            icon: Icons.gps_fixed_rounded,
            iconColor: AppColors.plum,
            iconBg: AppColors.plumSoft,
            title: '🎯 Weak Point Mini',
            subtitle: '5-10 phút · Ưu tiên câu thuộc điểm yếu của bạn',
            onTap: _startingWeakPoint ? null : _startWeakPoint,
            loading: _startingWeakPoint,
          ),
          const SizedBox(height: 20),
          OutlinedButton(
            onPressed: () => context.push('/review/statistics'),
            child: const Text('Xem lịch sử'),
          ),
        ],
      ),
    );
  }
}

class _MiniTestHeroCard extends StatelessWidget {
  const _MiniTestHeroCard({
    required this.streakText,
    required this.accuracyText,
    required this.onQuickStart,
  });

  final String streakText;
  final String accuracyText;
  final VoidCallback? onQuickStart;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.heroGradientStart, AppColors.heroGradientEnd],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Đề hôm nay',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Bắt đầu luyện vài phút mỗi ngày',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(child: _HeroStatTile(label: 'Streak', value: streakText)),
              const SizedBox(width: 10),
              Expanded(
                child: _HeroStatTile(label: 'Accuracy', value: accuracyText),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: onQuickStart,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.card,
                foregroundColor: AppColors.accentStrong,
              ),
              child: onQuickStart == null
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.accentStrong,
                      ),
                    )
                  : const Text('Bắt đầu ngay'),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroStatTile extends StatelessWidget {
  const _HeroStatTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 16,
            ),
          ),
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 11),
          ),
        ],
      ),
    );
  }
}

class _MiniTestVariantRow extends StatelessWidget {
  const _MiniTestVariantRow({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.loading = false,
  });

  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final bool loading;

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
                    subtitle,
                    style: const TextStyle(fontSize: 11, color: AppColors.inkSoft),
                  ),
                ],
              ),
            ),
            if (loading)
              const SizedBox(
                height: 18,
                width: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else
              const Icon(Icons.chevron_right_rounded, color: AppColors.inkFaint),
          ],
        ),
      ),
    );
  }
}
