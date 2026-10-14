import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/network/supabase_providers.dart';
import '../../core/theme/app_theme.dart';
import '../../domain/entities/lesson.dart';
import '../../domain/entities/lesson_progress.dart';
import '../../shared/level_badge.dart';
import '../../shared/motion/animated_progress_bar.dart';
import '../../shared/motion/fade_switcher.dart';
import '../../shared/motion/press_scale.dart';
import 'providers/content_providers.dart';

/// Tiến độ đã lưu của mọi bài trong cấp độ đang chọn, 1 query duy nhất —
/// nguồn thật là `user_lesson_progress` (chỉ có bước dừng + completed_at).
final lessonProgressMapProvider =
    FutureProvider.autoDispose<Map<String, LessonProgress>>((ref) async {
  final lessons = await ref.watch(lessonsProvider.future);
  final userId = ref.watch(currentUserProvider)?.id;
  if (userId == null || lessons.isEmpty) return const {};
  final rows = await ref
      .watch(supabaseProvider)
      .from('user_lesson_progress')
      .select('lesson_id, last_step_index, total_steps, completed_at')
      .eq('user_id', userId)
      .inFilter('lesson_id', [for (final l in lessons) l.id]);
  return {
    for (final r in rows)
      r['lesson_id'] as String: LessonProgress(
        lastStepIndex: r['last_step_index'] as int,
        totalSteps: r['total_steps'] as int,
        completedAt: r['completed_at'] == null
            ? null
            : DateTime.parse(r['completed_at'] as String),
      ),
  };
});

enum _LessonStatus { completed, inProgress, notStarted }

_LessonStatus _statusOf(LessonProgress? p) {
  if (p == null) return _LessonStatus.notStarted;
  if (p.isCompleted) return _LessonStatus.completed;
  return p.lastStepIndex > 0
      ? _LessonStatus.inProgress
      : _LessonStatus.notStarted;
}

final _lessonNoPrefix = RegExp(r'^(第\s*\d+\s*課)\s*');

/// Tách "第8課 タイトル" thành nhãn bài + tiêu đề; bài không có tiền tố thì
/// dùng thứ tự.
({String badge, String title}) _splitTitle(Lesson l) {
  final m = _lessonNoPrefix.firstMatch(l.title);
  if (m == null) return (badge: '第${l.orderIndex}課', title: l.title);
  return (
    badge: m.group(1)!.replaceAll(' ', ''),
    title: l.title.substring(m.end)
  );
}

/// Màn "Learning Hub" riêng cho khóa Tiếng Nhật IT — dùng chung provider/
/// route với N5–N1, chỉ khác cách trình bày (tiến độ khóa, Tiếp tục học,
/// Lộ trình, lối vào nhanh). Hiển thị khi `selectedLevelCode == 'IT'`.
class ItLearningHub extends ConsumerWidget {
  const ItLearningHub({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lessonsAsync = ref.watch(lessonsProvider);
    final progressAsync = ref.watch(lessonProgressMapProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tiếng Nhật IT'),
        actions: const [LevelBadge(), SizedBox(width: 12)],
      ),
      body: FadeSwitcher(
        child: lessonsAsync.when(
        loading: () => const Center(
            key: ValueKey('loading'), child: CircularProgressIndicator()),
        error: (_, __) => _ErrorState(
            key: const ValueKey('error'),
            onRetry: () => ref.invalidate(lessonsProvider)),
        data: (lessons) {
          if (lessons.isEmpty) {
            return const Center(
              key: ValueKey('empty'),
              child: Text('Chưa có nội dung bài học.',
                  style: TextStyle(color: AppColors.inkSoft)),
            );
          }
          final sorted = [...lessons]
            ..sort((a, b) => a.orderIndex.compareTo(b.orderIndex));
          final progress =
              progressAsync.valueOrNull ?? const <String, LessonProgress>{};
          final vocabCount = _countByLesson(
              ref.watch(vocabularyLessonAssignmentsProvider).valueOrNull);
          final grammarCount = _countByLesson(
              ref.watch(grammarLessonAssignmentsProvider).valueOrNull);
          return _HubBody(
            key: const ValueKey('data'),
            lessons: sorted,
            progress: progress,
            vocabCount: vocabCount,
            grammarCount: grammarCount,
          );
        },
        ),
      ),
    );
  }

  static Map<String, int> _countByLesson(Map<String, LessonAssignment>? m) {
    final out = <String, int>{};
    if (m == null) return out;
    for (final a in m.values) {
      out[a.lessonId] = (out[a.lessonId] ?? 0) + 1;
    }
    return out;
  }
}

class _HubBody extends StatelessWidget {
  const _HubBody({
    super.key,
    required this.lessons,
    required this.progress,
    required this.vocabCount,
    required this.grammarCount,
  });

  final List<Lesson> lessons;
  final Map<String, LessonProgress> progress;
  final Map<String, int> vocabCount;
  final Map<String, int> grammarCount;

  @override
  Widget build(BuildContext context) {
    final done =
        lessons.where((l) => progress[l.id]?.isCompleted ?? false).length;
    final current = lessons.firstWhere(
      (l) => !(progress[l.id]?.isCompleted ?? false),
      orElse: () => lessons.last,
    );

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
      children: [
        _CourseProgress(done: done, total: lessons.length),
        const SizedBox(height: 16),
        _ContinueCard(lesson: current, progress: progress[current.id]),
        const SizedBox(height: 16),
        const _QuickAccess(),
        const SizedBox(height: 24),
        const Text('Lộ trình',
            style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 16,
                color: AppColors.ink)),
        const SizedBox(height: 10),
        for (final l in lessons) ...[
          _RoadmapTile(
            lesson: l,
            progress: progress[l.id],
            isCurrent: l.id == current.id && done < lessons.length,
            vocab: vocabCount[l.id],
            grammar: grammarCount[l.id],
          ),
          const SizedBox(height: 10),
        ],
      ],
    );
  }
}

class _CourseProgress extends StatelessWidget {
  const _CourseProgress({required this.done, required this.total});

  final int done;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text('Hành trình học',
                    style: TextStyle(
                        fontWeight: FontWeight.w700, color: AppColors.inkSoft)),
              ),
              Text('$done / $total bài',
                  style: const TextStyle(
                      fontWeight: FontWeight.w800, color: AppColors.ink)),
            ],
          ),
          const SizedBox(height: 10),
          _Bar(value: total == 0 ? 0 : done / total, color: AppColors.accent),
        ],
      ),
    );
  }
}

class _ContinueCard extends StatelessWidget {
  const _ContinueCard({required this.lesson, required this.progress});

  final Lesson lesson;
  final LessonProgress? progress;

  @override
  Widget build(BuildContext context) {
    final t = _splitTitle(lesson);
    final status = _statusOf(progress);
    final label = switch (status) {
      _LessonStatus.completed => 'Ôn lại bài',
      _LessonStatus.inProgress => 'Tiếp tục học',
      _LessonStatus.notStarted => 'Bắt đầu bài học',
    };
    final ratio = progress?.ratio;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.accentSoft,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: AppColors.accent.withValues(alpha: 0.5), width: 0.6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(t.badge,
              style: AppFonts.zenMaruGothic(
                  fontSize: 15, color: AppColors.accentStrong)),
          const SizedBox(height: 4),
          Text(t.title,
              style: AppFonts.zenMaruGothic(fontSize: 17, color: AppColors.ink)
                  .copyWith(height: 1.4)),
          if (lesson.description != null) ...[
            const SizedBox(height: 2),
            Text(lesson.description!,
                style:
                    const TextStyle(fontSize: 12.5, color: AppColors.inkSoft)),
          ],
          if (status == _LessonStatus.inProgress && ratio != null) ...[
            const SizedBox(height: 12),
            _Bar(value: ratio, color: AppColors.accent),
            const SizedBox(height: 4),
            Text('Bước ${progress!.lastStepIndex} / ${progress!.totalSteps}',
                style: const TextStyle(fontSize: 12, color: AppColors.inkSoft)),
          ],
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: FilledButton.icon(
              onPressed: () => context.push('/lessons/${lesson.id}/run'),
              icon: const Icon(Icons.play_arrow_rounded),
              label: Text(label),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickAccess extends StatelessWidget {
  const _QuickAccess();

  @override
  Widget build(BuildContext context) {
    const items = [
      (
        label: 'Từ vựng',
        route: '/vocabulary',
        icon: Icons.translate_rounded,
        color: AppColors.moss
      ),
      (
        label: 'Kanji',
        route: '/kanji',
        icon: Icons.edit_outlined,
        color: AppColors.indigo
      ),
      (
        label: 'Ngữ pháp',
        route: '/grammar',
        icon: Icons.description_outlined,
        color: AppColors.plum
      ),
      (
        label: 'Ôn tập',
        route: '/review/today',
        icon: Icons.refresh_rounded,
        color: AppColors.teal
      ),
    ];
    return Row(
      children: [
        for (var i = 0; i < items.length; i++) ...[
          Expanded(
            child: PressScale(
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () => context.push(items[i].route),
                child: Container(
                  constraints: const BoxConstraints(minHeight: 72),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: _cardDecoration(),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(items[i].icon, color: items[i].color),
                      const SizedBox(height: 4),
                      Text(items[i].label,
                          style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.ink)),
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (i != items.length - 1) const SizedBox(width: 8),
        ],
      ],
    );
  }
}

class _RoadmapTile extends StatelessWidget {
  const _RoadmapTile({
    required this.lesson,
    required this.progress,
    required this.isCurrent,
    required this.vocab,
    required this.grammar,
  });

  final Lesson lesson;
  final LessonProgress? progress;
  final bool isCurrent;
  final int? vocab;
  final int? grammar;

  @override
  Widget build(BuildContext context) {
    final t = _splitTitle(lesson);
    final status = _statusOf(progress);
    final (icon, text, color) = switch (status) {
      _LessonStatus.completed => (
          Icons.check_circle_rounded,
          'Hoàn thành',
          AppColors.moss
        ),
      _LessonStatus.inProgress => (
          Icons.timelapse_rounded,
          'Đang học',
          AppColors.accentStrong
        ),
      _LessonStatus.notStarted => (
          Icons.radio_button_unchecked,
          'Chưa học',
          AppColors.inkFaint
        ),
    };
    final meta = [
      if (vocab != null) '$vocab từ',
      if (grammar != null) '$grammar mẫu câu',
    ].join(' · ');
    final ratio = status == _LessonStatus.inProgress ? progress?.ratio : null;

    return PressScale(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => context.push('/lessons/${lesson.id}/run'),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: _cardDecoration(highlight: isCurrent),
          child: Row(
            children: [
              Icon(icon, color: color),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(t.badge,
                        style: AppFonts.zenMaruGothic(
                            fontSize: 13, color: AppColors.inkSoft)),
                    const SizedBox(height: 2),
                    Text(t.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppFonts.zenMaruGothic(
                                fontSize: 14.5, color: AppColors.ink)
                            .copyWith(height: 1.35)),
                    if (lesson.description != null) ...[
                      const SizedBox(height: 2),
                      Text(lesson.description!,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 12, color: AppColors.inkSoft)),
                    ],
                    const SizedBox(height: 6),
                    Text(meta.isEmpty ? text : '$text · $meta',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: color)),
                    if (ratio != null) ...[
                      const SizedBox(height: 6),
                      _Bar(value: ratio, color: AppColors.accent),
                    ],
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.inkFaint),
            ],
          ),
        ),
      ),
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({required this.value, required this.color});

  final double value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return AnimatedProgressBar(
      value: value.clamp(0.0, 1.0),
      minHeight: 6,
      backgroundColor: AppColors.chip,
      color: color,
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({super.key, required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Không thể tải nội dung.',
              style: TextStyle(color: AppColors.inkSoft)),
          const SizedBox(height: 12),
          OutlinedButton(onPressed: onRetry, child: const Text('Thử lại')),
        ],
      ),
    );
  }
}

BoxDecoration _cardDecoration({bool highlight = false}) => BoxDecoration(
      color: AppColors.card,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(
        color: highlight ? AppColors.accent : AppColors.border,
        width: highlight ? 1.2 : 0.6,
      ),
    );
