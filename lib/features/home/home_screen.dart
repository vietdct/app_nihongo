import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/network/supabase_providers.dart';
import '../../core/theme/app_motion.dart';
import '../../core/theme/app_theme.dart';
import '../../domain/entities/vocabulary.dart';
import '../../domain/services/word_of_the_day.dart';
import '../../shared/level_badge.dart';
import '../../shared/motion/animated_count.dart';
import '../../shared/motion/animated_progress_bar.dart';
import '../../shared/motion/press_scale.dart';
import '../../shared/skeleton.dart';
import '../../shared/skeleton_layouts.dart';
import '../auth/auth_controller.dart';
import '../grammar/providers/grammar_progress_providers.dart';
import '../kanji/providers/kanji_progress_providers.dart';
import '../lesson/providers/content_providers.dart';
import '../lesson/providers/level_providers.dart';
import '../profile/providers/achievements_providers.dart';
import '../profile/providers/ai_insights_providers.dart';
import '../profile/providers/study_heatmap_providers.dart';
import '../profile/widgets/weak_area_suggestion_card.dart';
import '../vocabulary/providers/vocab_progress_providers.dart';
import 'providers/continue_learning_providers.dart';
import 'providers/mission_providers.dart';
import 'providers/profile_providers.dart';
import 'widgets/daily_goal_card.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour < 11) return 'Chào buổi sáng';
    if (hour < 14) return 'Chào buổi trưa';
    if (hour < 18) return 'Chào buổi chiều';
    return 'Chào buổi tối';
  }

  static ({int known, int total})? _knownStats<T>(
    List<T>? items,
    Map<String, dynamic>? progress,
    String Function(T) idOf,
  ) {
    if (items == null || progress == null || items.isEmpty) return null;
    final known = items.where((e) {
      final p = progress[idOf(e)];
      if (p == null) return false;
      final dynamic isKnown = (p as dynamic).isKnown;
      return isKnown == true;
    }).length;
    return (known: known, total: items.length);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    // Nghe huy hiệu vừa mở khóa (trong bộ nhớ, không ghi dữ liệu): giữ bộ theo
    // dõi sống từ khi vào Home và báo nhẹ bằng SnackBar; hiệu ứng nằm ở màn
    // Thành tích (đánh dấu "đã xem" ở đó).
    ref.listen<Set<String>>(achievementUnlockTrackerProvider, (prev, next) {
      final fresh = next.difference(prev ?? const {});
      if (fresh.isEmpty) return;
      final defs = ref.read(loadedAchievementsProvider) ?? const [];
      final names = [
        for (final a in defs)
          if (fresh.contains(a.id)) '${a.sub} ${a.label}',
      ];
      if (names.isEmpty) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text('🏅 Mở khóa huy hiệu: ${names.join(', ')}'),
            action: SnackBarAction(
              label: 'Xem',
              onPressed: () => context.push('/profile/achievements'),
            ),
          ),
        );
    });
    final profileAsync = ref.watch(profileProvider);
    final currentLessonAsync = ref.watch(currentLessonProvider);
    final selectedLevel = ref.watch(selectedLevelCodeProvider);

    final email = user?.email ?? '';
    final initial = email.isNotEmpty ? email[0].toUpperCase() : '?';
    final profile = profileAsync.valueOrNull;
    final displayName = profile?.displayName ?? email;

    final vocabListAsync = ref.watch(vocabularyListProvider);
    final kanjiListAsync = ref.watch(kanjiListProvider);
    final grammarListAsync = ref.watch(grammarListProvider);
    final vocabProgressAsync = ref.watch(vocabProgressProvider);
    final kanjiProgressAsync = ref.watch(kanjiProgressProvider);
    final grammarProgressAsync = ref.watch(grammarProgressProvider);
    final vocabList = vocabListAsync.valueOrNull;
    final kanjiList = kanjiListAsync.valueOrNull;
    final grammarList = grammarListAsync.valueOrNull;
    final vocabProgress = vocabProgressAsync.valueOrNull;
    final kanjiProgress = kanjiProgressAsync.valueOrNull;
    final grammarProgress = grammarProgressAsync.valueOrNull;
    // Chỉ coi là "đang tải lần đầu" khi chưa có dữ liệu nào (đang làm mới mà đã
    // có dữ liệu cũ thì không phủ skeleton lên nội dung đang hiển thị).
    bool firstLoad(AsyncValue<Object?> a) => a.isLoading && !a.hasValue;

    final progressGauges = <_ProgressGaugeData>[
      if (_knownStats(vocabList, vocabProgress, (v) => v.id) case final s?)
        _ProgressGaugeData(
          label: 'Từ vựng',
          color: AppColors.moss,
          known: s.known,
          total: s.total,
          route: '/vocabulary',
        ),
      if (_knownStats(kanjiList, kanjiProgress, (k) => k.id) case final s?)
        _ProgressGaugeData(
          label: 'Kanji',
          color: AppColors.indigo,
          known: s.known,
          total: s.total,
          route: '/kanji',
        ),
      if (_knownStats(grammarList, grammarProgress, (g) => g.id) case final s?)
        _ProgressGaugeData(
          label: 'Ngữ pháp',
          color: AppColors.plum,
          known: s.known,
          total: s.total,
          route: '/grammar',
        ),
    ];

    final wordOfDay = vocabList == null
        ? null
        : pickWordOfTheDay(pool: vocabList, levelId: selectedLevel);

    final weak = ref.watch(weakAreaCountsProvider);

    final studyDays = ref.watch(studyDaysProvider).valueOrNull;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final monday = today.subtract(Duration(days: today.weekday - 1));
    final weekStudied = studyDays == null
        ? null
        : List.generate(7, (i) => monday.add(Duration(days: i)))
            .where(studyDays.contains)
            .length;

    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: Stack(
        children: [
          Positioned(
            top: 390,
            right: -72,
            child: _BackgroundOrb(
              size: 190,
              color: AppColors.plum.withValues(alpha: 0.07),
            ),
          ),
          Positioned(
            top: 820,
            left: -90,
            child: _BackgroundOrb(
              size: 220,
              color: AppColors.indigo.withValues(alpha: 0.06),
            ),
          ),
          Builder(
            builder: (context) {
              final sections = <Widget>[
                _HeroHeader(
                  greeting: _greeting,
                  initial: initial,
                  displayName: displayName,
                  avatarUrl: profile?.avatarUrl,
                  streakCount: profile?.streakCount,
                  xp: profile?.xp,
                  weekStudied: weekStudied,
                  onLogout: () =>
                      ref.read(authControllerProvider.notifier).signOut(),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
                  child: DailyGoalCard(studyDays: studyDays),
                ),
                currentLessonAsync.maybeWhen(
                  data: (current) => current == null
                      ? const SizedBox.shrink()
                      : Padding(
                          padding: const EdgeInsets.fromLTRB(20, 22, 20, 0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const _SectionLabel('Continue learning'),
                              const SizedBox(height: 10),
                              _ContinueLessonCard(
                                title: current.lesson.title,
                                lessonId: current.lesson.id,
                                ratio: current.progress?.ratio,
                                isCompleted:
                                    current.progress?.isCompleted ?? false,
                              ),
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton(
                                  onPressed: () => context.push('/lessons'),
                                  child: Text(selectedLevel == 'IT'
                                      ? 'Xem lộ trình khóa học'
                                      : 'Xem danh sách bài'),
                                ),
                              ),
                            ],
                          ),
                        ),
                  loading: () => currentLessonAsync.hasValue
                      ? const SizedBox.shrink()
                      : const _SectionSkeleton(top: 22, cardHeight: 96),
                  orElse: () => const SizedBox.shrink(),
                ),
                const Padding(
                  padding: EdgeInsets.fromLTRB(20, 26, 20, 0),
                  child: _TodayMissionSection(),
                ),
                if (weak.total > 0)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 26, 20, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const _SectionLabel('Gợi ý cho bạn'),
                        const SizedBox(height: 10),
                        WeakAreaSuggestionCard(weak: weak),
                      ],
                    ),
                  ),
                if (progressGauges.isEmpty &&
                    [
                      vocabListAsync,
                      kanjiListAsync,
                      grammarListAsync,
                      vocabProgressAsync,
                      kanjiProgressAsync,
                      grammarProgressAsync,
                    ].any(firstLoad))
                  const _GaugesSkeleton(),
                if (progressGauges.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 26, 20, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const _SectionLabel('Tiến độ học tập'),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            for (var i = 0; i < progressGauges.length; i++) ...[
                              if (i > 0) const SizedBox(width: 10),
                              Expanded(
                                child: _ProgressGaugeCard(
                                  data: progressGauges[i],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                if (wordOfDay == null && firstLoad(vocabListAsync))
                  const _SectionSkeleton(top: 26, cardHeight: 90),
                if (wordOfDay != null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 26, 20, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const _SectionLabel('Từ vựng hôm nay'),
                        const SizedBox(height: 10),
                        _WordOfDayCard(vocab: wordOfDay),
                      ],
                    ),
                  ),
                const SizedBox(height: 28),
              ];
              return ListView(
                padding: EdgeInsets.zero,
                children: [
                  for (var i = 0; i < sections.length; i++)
                    _StaggerIn(index: i, child: sections[i]),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

/// Header gradient hero, theo bản redesign mới (Claude Design "Home
/// Prototype") — lời chào + tên thật, LevelBadge + nút đăng xuất, và hàng 3
/// thẻ thống kê thật (streak/XP/số ngày học trong tuần), không còn bong bóng
/// chào hay mascot minh hoạ như bản cũ.
class _HeroHeader extends StatelessWidget {
  const _HeroHeader({
    required this.greeting,
    required this.initial,
    required this.displayName,
    required this.avatarUrl,
    required this.streakCount,
    required this.xp,
    required this.weekStudied,
    required this.onLogout,
  });

  final String greeting;
  final String initial;
  final String displayName;
  final String? avatarUrl;
  final int? streakCount;
  final int? xp;
  final int? weekStudied;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.heroGradientStart,
                  Color.lerp(
                    AppColors.heroGradientStart,
                    AppColors.heroGradientEnd,
                    0.5,
                  )!,
                  AppColors.heroGradientEnd,
                ],
                stops: const [0, 0.35, 1],
                begin: const Alignment(-0.3, -1),
                end: const Alignment(0.3, 1),
              ),
            ),
          ),
        ),
        Positioned(
          top: -40,
          right: -30,
          child: _BackgroundOrb(
            size: 160,
            color: Colors.white.withValues(alpha: 0.08),
          ),
        ),
        Positioned(
          top: 30,
          right: 40,
          child: _BackgroundOrb(
            size: 80,
            color: Colors.white.withValues(alpha: 0.06),
          ),
        ),
        Positioned(
          bottom: -20,
          left: 20,
          child: _BackgroundOrb(
            size: 100,
            color: Colors.white.withValues(alpha: 0.05),
          ),
        ),
        SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 22),
            child: Column(
              children: [
                Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.4),
                            width: 2,
                          ),
                          image: avatarUrl != null
                              ? DecorationImage(
                                  image: NetworkImage(avatarUrl!),
                                  fit: BoxFit.cover,
                                )
                              : null,
                        ),
                        alignment: Alignment.center,
                        child: avatarUrl == null
                            ? Text(
                                initial,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 20,
                                ),
                              )
                            : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            greeting,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.white.withValues(alpha: 0.85),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            displayName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              letterSpacing: -0.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const LevelBadge(onGradient: true),
                    const SizedBox(width: 2),
                    IconButton(
                      tooltip: 'Đăng xuất',
                      icon: const Icon(
                        Icons.logout,
                        color: Colors.white,
                        size: 20,
                      ),
                      onPressed: onLogout,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _HeroStat(
                        value: streakCount == null ? '–' : '$streakCount',
                        count: streakCount,
                        counted: true,
                        label: '🔥 Streak',
                        pulse: (streakCount ?? 0) > 0,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _HeroStat(
                        value: xp == null ? '–' : '$xp',
                        count: xp,
                        counted: true,
                        label: '⚡ XP',
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _HeroStat(
                        value: weekStudied == null ? '–' : '$weekStudied',
                        suffix: '/7',
                        label: '📅 Tuần',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _BackgroundOrb extends StatelessWidget {
  const _BackgroundOrb({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(shape: BoxShape.circle, color: color),
      ),
    );
  }
}

/// 1 thẻ thống kê trong header (Streak/XP/Tuần) — số streak nhấp nháy nhẹ
/// (pulse) khi > 0, mô phỏng `@keyframes pulse-flame` của bản thiết kế gốc.
class _HeroStat extends StatefulWidget {
  const _HeroStat({
    required this.value,
    required this.label,
    this.suffix,
    this.pulse = false,
    this.count,
    this.counted = false,
  });

  final String value;

  /// [counted] = true: số hiển thị bằng `AnimatedCount` theo [count] (null =
  /// đang tải → '–'). Chỉ đếm khi giá trị thật đổi lúc widget còn sống.
  final int? count;
  final bool counted;
  final String? suffix;
  final String label;
  final bool pulse;

  @override
  State<_HeroStat> createState() => _HeroStatState();
}

class _HeroStatState extends State<_HeroStat>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    // Tạo ngay (không lười) để dispose() không phải tạo controller khi widget
    // đã bị huỷ — việc đó gây "Looking up a deactivated widget's ancestor".
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 750),
    );
    _scale = Tween(begin: 1.0, end: 1.18)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
    _syncPulse();
  }

  // `pulse` đổi theo streak tải bất đồng bộ (false → true) nên phải theo dõi.
  @override
  void didUpdateWidget(covariant _HeroStat oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.pulse != widget.pulse) _syncPulse();
  }

  // Bật/tắt "Giảm chuyển động" giữa chừng cũng phải dừng/chạy lại nhịp pulse.
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncPulse();
  }

  void _syncPulse() {
    if (widget.pulse && !AppMotion.reduced(context)) {
      _controller.repeat(reverse: true);
    } else {
      _controller
        ..stop()
        ..value = 0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const numberStyle = TextStyle(
      fontSize: 22,
      fontWeight: FontWeight.w700,
      color: Colors.white,
      height: 1,
    );
    final number = widget.counted
        ? AnimatedCount(value: widget.count, style: numberStyle)
        : Text.rich(
            TextSpan(
              text: widget.value,
              style: numberStyle,
              children: [
                if (widget.suffix != null)
                  TextSpan(
                    text: widget.suffix,
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w600),
                  ),
              ],
            ),
          );
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF0E1214).withValues(alpha: 0.4)
            : Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          widget.pulse ? ScaleTransition(scale: _scale, child: number) : number,
          const SizedBox(height: 2),
          Text(
            widget.label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: Colors.white.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }
}

/// Thẻ "vào học ngay" — trỏ tới bài học thật đang dở (theo
/// `currentLessonProvider`: bài đầu tiên theo orderIndex chưa có
/// completed_at trong `user_lesson_progress`). [ratio] null nghĩa là chưa
/// từng mở bài này (hiện "Bắt đầu"), khác 0% đã mở nhưng chưa qua bước nào.
class _ContinueLessonCard extends StatefulWidget {
  const _ContinueLessonCard({
    required this.title,
    required this.lessonId,
    required this.ratio,
    required this.isCompleted,
  });

  final String title;
  final String lessonId;
  final double? ratio;
  final bool isCompleted;

  @override
  State<_ContinueLessonCard> createState() => _ContinueLessonCardState();
}

class _ContinueLessonCardState extends State<_ContinueLessonCard> {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final title = widget.title;
    final lessonId = widget.lessonId;
    final ratio = widget.ratio;
    final isCompleted = widget.isCompleted;
    final label = isCompleted
        ? 'Đã hoàn thành, ôn lại'
        : ratio == null
            ? 'Bắt đầu bài học'
            : 'Tiếp tục học';

    return PressScale(
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => context.push('/lessons/$lessonId/run'),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? const [Color(0xFF1A8A7A), Color(0xFF127068)]
                  : const [AppColors.accent, AppColors.accentStrong],
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: AppColors.accent.withValues(alpha: 0.3),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Stack(
            children: [
              Positioned(
                right: -34,
                top: -52,
                child: Container(
                  width: 130,
                  height: 130,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.09),
                  ),
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label.toUpperCase(),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withValues(alpha: 0.8),
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                            if (ratio != null && !isCompleted) ...[
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Expanded(
                                    child: AnimatedProgressBar(
                                      value: ratio.clamp(0, 1),
                                      minHeight: 6,
                                      backgroundColor:
                                          Colors.white.withValues(alpha: 0.25),
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '${(ratio * 100).round()}%',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(width: 14),
                      const _GlowPulseCircle(
                        child: Icon(
                          Icons.play_arrow_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ],
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

/// Vòng tròn nút play toả sáng nhấp nháy nhẹ (glow-pulse) quanh viền — mô
/// phỏng `@keyframes glow-pulse` của bản thiết kế gốc.
class _GlowPulseCircle extends StatefulWidget {
  const _GlowPulseCircle({required this.child});

  final Widget child;

  @override
  State<_GlowPulseCircle> createState() => _GlowPulseCircleState();
}

class _GlowPulseCircleState extends State<_GlowPulseCircle>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 2),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final t = (1 - (0.5 - _controller.value).abs() * 2).clamp(0.0, 1.0);
        return Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.25),
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.4),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.accent.withValues(alpha: 0.3 * (1 - t)),
                blurRadius: 1,
                spreadRadius: 8 * t,
              ),
            ],
          ),
          alignment: Alignment.center,
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

/// "Today's Mission" — icon số thứ tự mỗi mục đổi trạng thái theo tiến độ
/// thật: đã xong (check xanh), đang làm — mục chưa xong đầu tiên (cam đậm),
/// hoặc chưa tới lượt (xám nhạt). Nối dữ liệu thật qua
/// `dailyMissionStatusProvider` (xem `mission_providers.dart`) — không còn
/// tick tay, mỗi mục tự bật khi đạt ngưỡng hoạt động thật hôm nay.
enum _MissionState { done, current, locked }

class _MissionData {
  const _MissionData({
    required this.label,
    required this.xp,
    required this.done,
  });

  final String label;
  final int xp;
  final bool done;
}

class _TodayMissionSection extends ConsumerWidget {
  const _TodayMissionSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statusAsync = ref.watch(dailyMissionStatusProvider);
    final status = statusAsync.valueOrNull;
    final statusLoading = statusAsync.isLoading && !statusAsync.hasValue;
    final missions = [
      _MissionData(
        label: 'Học 10 từ vựng mới',
        xp: 10,
        done: status?.vocabDone ?? false,
      ),
      _MissionData(
        label: 'Ôn tập 5 chữ Kanji',
        xp: 10,
        done: status?.kanjiDone ?? false,
      ),
      _MissionData(
        label: 'Hoàn thành 1 bài Quiz',
        xp: 15,
        done: status?.quizDone ?? false,
      ),
      _MissionData(
        label: 'Trò chuyện cùng AI Kaiwa',
        xp: 15,
        done: status?.kaiwaDone ?? false,
      ),
    ];
    final doneCount = missions.where((m) => m.done).length;
    final firstPendingIdx = missions.indexWhere((m) => !m.done);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const _SectionLabel("Today's Mission"),
            // Đang tải trạng thái lần đầu: không hiện "0/4" như thể chưa làm gì.
            if (statusLoading)
              const SkeletonScope(
                child: SkeletonBox(width: 34, height: 20, radius: 100),
              )
            else
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppColors.accent, AppColors.accentStrong],
                  ),
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Text(
                  '$doneCount/${missions.length}',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.border, width: 1.0),
          ),
          child: Column(
            children: [
              for (var i = 0; i < missions.length; i++) ...[
                if (i > 0) const Divider(height: 1, color: AppColors.canvas),
                _MissionRow(
                  mission: missions[i],
                  index: i,
                  state: missions[i].done
                      ? _MissionState.done
                      : i == firstPendingIdx
                          ? _MissionState.current
                          : _MissionState.locked,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _MissionRow extends StatelessWidget {
  const _MissionRow({
    required this.mission,
    required this.index,
    required this.state,
  });

  final _MissionData mission;
  final int index;
  final _MissionState state;

  @override
  Widget build(BuildContext context) {
    final done = state == _MissionState.done;
    final current = state == _MissionState.current;
    final iconBg = done
        ? AppColors.moss
        : current
            ? AppColors.accent
            : AppColors.chip;
    final textColor = done
        ? AppColors.moss
        : state == _MissionState.locked
            ? AppColors.inkSoft
            : AppColors.ink;
    final badgeColor = done
        ? AppColors.moss
        : current
            ? AppColors.accent
            : AppColors.inkSoft;
    final badgeBg = done
        ? AppColors.mossSoft
        : current
            ? AppColors.accentSoft
            : AppColors.chip;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      child: Row(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOut,
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: iconBg,
              shape: BoxShape.circle,
              boxShadow: done || current
                  ? [
                      BoxShadow(
                        color: (done ? AppColors.moss : AppColors.accent)
                            .withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            alignment: Alignment.center,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              transitionBuilder: (child, anim) =>
                  ScaleTransition(scale: anim, child: child),
              child: done
                  ? const Icon(
                      Icons.check_rounded,
                      key: ValueKey('check'),
                      size: 15,
                      color: Colors.white,
                    )
                  : Text(
                      '${index + 1}',
                      key: const ValueKey('num'),
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: current ? Colors.white : AppColors.inkSoft,
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 250),
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 13,
                color: textColor,
                decoration:
                    done ? TextDecoration.lineThrough : TextDecoration.none,
              ),
              child: Text(mission.label),
            ),
          ),
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
            decoration: BoxDecoration(
              color: badgeBg,
              borderRadius: BorderRadius.circular(100),
            ),
            child: Text(
              '+${mission.xp} XP',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: badgeColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 1 vòng tròn tiến độ trong "Tiến độ học tập" — [known]/[total] tính thật
/// từ progress provider tương ứng (đồng bộ cách tính với banner "x/y đã
/// thuộc" ở các màn danh sách), không có kỹ năng nào bị bịa số.
class _ProgressGaugeData {
  const _ProgressGaugeData({
    required this.label,
    required this.color,
    required this.known,
    required this.total,
    required this.route,
  });

  final String label;
  final Color color;
  final int known;
  final int total;
  final String route;

  int get pct => total == 0 ? 0 : ((known / total) * 100).round();
}

class _ProgressGaugeCard extends StatelessWidget {
  const _ProgressGaugeCard({required this.data});

  final _ProgressGaugeData data;

  @override
  Widget build(BuildContext context) {
    return PressScale(
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => context.push(data.route),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.border, width: 1.0),
          ),
          child: Column(
            children: [
              SizedBox(
                width: 60,
                height: 60,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    const SizedBox.expand(
                      child: CircularProgressIndicator(
                        value: 1,
                        strokeWidth: 5,
                        color: AppColors.chip,
                      ),
                    ),
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: data.pct / 100),
                      duration: const Duration(milliseconds: 800),
                      curve: Curves.easeOutCubic,
                      builder: (context, value, _) => SizedBox.expand(
                        child: CircularProgressIndicator(
                          value: value,
                          strokeWidth: 5,
                          strokeCap: StrokeCap.round,
                          color: data.color,
                        ),
                      ),
                    ),
                    Text(
                      '${data.pct}%',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: data.color,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                data.label,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '${data.known}/${data.total}',
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: AppColors.inkSoft,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Từ vựng ngẫu nhiên-theo-ngày (chỉ số quyết định bằng số ngày trong năm,
/// không phải bịa) — luôn cùng 1 từ trong suốt 1 ngày, đổi từ khi sang ngày
/// mới. Bấm vào mở danh sách từ vựng.
class _WordOfDayCard extends StatelessWidget {
  const _WordOfDayCard({required this.vocab});

  final Vocabulary vocab;

  @override
  Widget build(BuildContext context) {
    final meaning = vocab.meanings.isEmpty ? null : vocab.meanings.first;
    final meaningVi = vocab.primaryMeaning.isEmpty
        ? 'Đang cập nhật nghĩa…'
        : vocab.primaryMeaning;
    return PressScale(
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => context.push('/vocabulary'),
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
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppColors.mossSoft, AppColors.tealSoft],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                alignment: Alignment.center,
                child: Text(
                  vocab.word.isEmpty ? '' : vocab.word[0],
                  style: AppFonts.zenMaruGothic(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    color: AppColors.moss,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          vocab.word,
                          style: AppFonts.zenMaruGothic(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: AppColors.ink,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            vocab.reading,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppFonts.zenMaruGothic(
                              fontSize: 10.5,
                              color: AppColors.inkSoft,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      meaningVi,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.inkSoft,
                      ),
                    ),
                    if (meaning?.exampleJp != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        meaning!.exampleJp!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 10.5,
                          color: AppColors.inkSoft,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
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
        color: AppColors.inkSoft,
        letterSpacing: 0.6,
      ),
    );
  }
}

/// Hiệu ứng vào màn hình so le (fade + trượt nhẹ từ dưới lên) cho từng
/// section — chỉ chạy 1 lần khi mục đó lần đầu build, độ trễ tăng dần theo
/// [index] để tạo cảm giác "premium" khi mở Home.
class _StaggerIn extends StatefulWidget {
  const _StaggerIn({required this.index, required this.child});

  final int index;
  final Widget child;

  @override
  State<_StaggerIn> createState() => _StaggerInState();
}

class _StaggerInState extends State<_StaggerIn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 420),
  );
  late final Animation<double> _fade = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeOut,
  );
  late final Animation<Offset> _slide = Tween<Offset>(
    begin: const Offset(0, 0.06),
    end: Offset.zero,
  ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

  @override
  void initState() {
    super.initState();
    final delay = Duration(milliseconds: (widget.index * 55).clamp(0, 380));
    Future.delayed(delay, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(position: _slide, child: widget.child),
    );
  }
}

/// Khung giữ chỗ cho 1 khu vực Home (nhãn + 1 thẻ) khi dữ liệu của khu vực đó
/// đang tải lần đầu — chiều cao gần thẻ thật để không nhảy bố cục.
class _SectionSkeleton extends StatelessWidget {
  const _SectionSkeleton({required this.top, required this.cardHeight});

  final double top;
  final double cardHeight;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(20, top, 20, 0),
      child: SkeletonScope(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SkeletonBox(width: 110, height: 12),
            const SizedBox(height: 10),
            SkeletonCard(
              radius: 18,
              child: SizedBox(
                height: cardHeight - 28,
                child: const Row(
                  children: [
                    SkeletonBox(width: 56, height: 56, radius: 16),
                    SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SkeletonBox(width: 130, height: 16),
                          SizedBox(height: 9),
                          SkeletonBox(height: 12),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Khung giữ chỗ cho hàng 3 vòng "Tiến độ học tập" khi chưa có dữ liệu nào.
class _GaugesSkeleton extends StatelessWidget {
  const _GaugesSkeleton();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 26, 20, 0),
      child: SkeletonScope(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SkeletonBox(width: 110, height: 12),
            const SizedBox(height: 12),
            Row(
              children: [
                for (var i = 0; i < 3; i++) ...[
                  if (i > 0) const SizedBox(width: 10),
                  const Expanded(
                    child: SkeletonCard(
                      padding:
                          EdgeInsets.symmetric(vertical: 16, horizontal: 10),
                      radius: 18,
                      child: Column(
                        children: [
                          SkeletonBox(width: 60, height: 60, circle: true),
                          SizedBox(height: 10),
                          SkeletonBox(width: 50, height: 12),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
