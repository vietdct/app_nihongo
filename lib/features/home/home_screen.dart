import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/network/supabase_providers.dart';
import '../../core/theme/app_theme.dart';
import '../../domain/entities/vocabulary.dart';
import '../../domain/services/word_of_the_day.dart';
import '../../shared/level_badge.dart';
import '../auth/auth_controller.dart';
import '../grammar/providers/grammar_progress_providers.dart';
import '../kanji/providers/kanji_progress_providers.dart';
import '../lesson/providers/content_providers.dart';
import '../lesson/providers/level_providers.dart';
import '../vocabulary/providers/vocab_progress_providers.dart';
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

  static int? _pctKnown<T>(
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
    return ((known / items.length) * 100).round();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final profileAsync = ref.watch(profileProvider);
    final lessons = ref.watch(lessonsProvider);
    final selectedLevel = ref.watch(selectedLevelCodeProvider);

    final email = user?.email ?? '';
    final initial = email.isNotEmpty ? email[0].toUpperCase() : '?';
    final profile = profileAsync.valueOrNull;
    final displayName = profile?.displayName ?? email;

    final vocabList = ref.watch(vocabularyListProvider).valueOrNull;
    final kanjiList = ref.watch(kanjiListProvider).valueOrNull;
    final grammarList = ref.watch(grammarListProvider).valueOrNull;
    final vocabProgress = ref.watch(vocabProgressProvider).valueOrNull;
    final kanjiProgress = ref.watch(kanjiProgressProvider).valueOrNull;
    final grammarProgress = ref.watch(grammarProgressProvider).valueOrNull;

    final progressBars = <_ProgressBarData>[
      if (_pctKnown(vocabList, vocabProgress, (v) => v.id) case final pct?)
        _ProgressBarData(label: 'Từ vựng', color: AppColors.moss, pct: pct),
      if (_pctKnown(kanjiList, kanjiProgress, (k) => k.id) case final pct?)
        _ProgressBarData(label: 'Kanji', color: AppColors.indigo, pct: pct),
      if (_pctKnown(grammarList, grammarProgress, (g) => g.id) case final pct?)
        _ProgressBarData(label: 'Ngữ pháp', color: AppColors.plum, pct: pct),
    ];

    final wordOfDay = vocabList == null
        ? null
        : pickWordOfTheDay(pool: vocabList, levelId: selectedLevel);

    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          _HeroHeader(
            greeting: _greeting,
            initial: initial,
            displayName: displayName,
            streakCount: profile?.streakCount,
            xp: profile?.xp,
            onLogout: () => ref.read(authControllerProvider.notifier).signOut(),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
            child: DailyGoalCard(lastStudyDate: profile?.lastStudyDate),
          ),
          lessons.maybeWhen(
            data: (items) => items.isEmpty
                ? const SizedBox.shrink()
                : Padding(
                    padding: const EdgeInsets.fromLTRB(20, 22, 20, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const _SectionLabel('Continue learning'),
                        const SizedBox(height: 10),
                        _ContinueLessonCard(
                          title: items.first.title,
                          lessonId: items.first.id,
                          levelLabel: selectedLevel,
                        ),
                      ],
                    ),
                  ),
            orElse: () => const SizedBox.shrink(),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 26, 20, 0),
            child: _TodayMissionSection(),
          ),
          if (progressBars.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 26, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _SectionLabel('Tiến độ'),
                  const SizedBox(height: 12),
                  _ProgressCard(bars: progressBars),
                ],
              ),
            ),
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
        ],
      ),
    );
  }
}

/// Header gradient hero — thay cho AppBar + thẻ streak riêng cũ. Chứa lời
/// chào + tên thật, pill streak/XP thật (không có pill xu — app chưa có khái
/// niệm xu), LevelBadge + nút đăng xuất, và hàng "mascot" + bong bóng chào.
/// Mascot dùng tạm avatar chữ cái đầu — chờ user cung cấp ảnh linh vật thật.
class _HeroHeader extends StatelessWidget {
  const _HeroHeader({
    required this.greeting,
    required this.initial,
    required this.displayName,
    required this.streakCount,
    required this.xp,
    required this.onLogout,
  });

  final String greeting;
  final String initial;
  final String displayName;
  final int? streakCount;
  final int? xp;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.heroGradientStart, AppColors.heroGradientEnd],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 22),
          child: Column(
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 19,
                    backgroundColor: Colors.white.withValues(alpha: 0.28),
                    child: Text(initial,
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 14,),),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(greeting,
                            style: const TextStyle(
                                fontSize: 10.5,
                                color: Colors.white70,
                                fontWeight: FontWeight.w600,),),
                        Text(
                          displayName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,),
                        ),
                      ],
                    ),
                  ),
                  if (streakCount != null)
                    _HeaderPill(
                        icon: Icons.local_fire_department_rounded,
                        text: '$streakCount',),
                  const SizedBox(width: 6),
                  if (xp != null) _HeaderPill(text: '$xp XP'),
                  const SizedBox(width: 6),
                  const LevelBadge(onGradient: true),
                  const SizedBox(width: 4),
                  IconButton(
                    tooltip: 'Đăng xuất',
                    icon:
                        const Icon(Icons.logout, color: Colors.white, size: 20),
                    onPressed: onLogout,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  CircleAvatar(
                    radius: 32,
                    backgroundColor: Colors.white.withValues(alpha: 0.28),
                    child: Text(initial,
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 22,),),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 13, vertical: 11,),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(16),
                          topRight: Radius.circular(16),
                          bottomRight: Radius.circular(16),
                          bottomLeft: Radius.circular(4),
                        ),
                        boxShadow: [
                          BoxShadow(
                              color: Colors.black.withValues(alpha: 0.12),
                              blurRadius: 18,
                              offset: const Offset(0, 8),),
                        ],
                      ),
                      child: Text(
                        streakCount != null && streakCount! > 0
                            ? 'Giữ chuỗi $streakCount ngày nhé!'
                            : 'Bắt đầu chuỗi học đầu tiên hôm nay!',
                        style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 13,
                            color: AppColors.ink,),
                      ),
                    ),
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

class _HeaderPill extends StatelessWidget {
  const _HeaderPill({this.icon, required this.text});

  final IconData? icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.22),
          borderRadius: BorderRadius.circular(100),),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: Colors.white),
            const SizedBox(width: 4),
          ],
          Text(text,
              style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  fontSize: 11.5,),),
        ],
      ),
    );
  }
}

/// Thẻ "vào học ngay" nổi bật dưới thẻ mục tiêu — trỏ tới bài học đầu tiên
/// trong danh sách thật (app chưa lưu "đang học dở bài nào" nên không dùng
/// chữ "Tiếp tục" ngụ ý đã học dở, chỉ mời vào học bài đầu của cấp độ hiện tại).
class _ContinueLessonCard extends StatelessWidget {
  const _ContinueLessonCard(
      {required this.title, required this.lessonId, required this.levelLabel,});

  final String title;
  final String lessonId;
  final String levelLabel;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () => context.push('/lessons/$lessonId/run'),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.accent, AppColors.accentStrong],
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
              child: const Icon(Icons.menu_book_rounded,
                  color: Colors.white, size: 24,),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('$levelLabel — Vào học ngay',
                      style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                          color: Colors.white,),),
                  const SizedBox(height: 2),
                  Text(title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,),),
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
              child: const Icon(Icons.play_arrow_rounded,
                  color: Colors.white, size: 20,),
            ),
          ],
        ),
      ),
    );
  }
}

/// "Today's Mission" — checklist + badge XP mỗi mục + đếm x/y đã xong, nối
/// dữ liệu thật qua `dailyMissionStatusProvider` (xem `mission_providers.dart`):
/// không còn tick tay, mỗi mục tự bật khi đạt ngưỡng hoạt động thật hôm nay
/// và tự cộng XP đúng 1 lần/ngày.
class _MissionData {
  const _MissionData({required this.label, required this.xp, required this.done});

  final String label;
  final int xp;
  final bool done;
}

class _TodayMissionSection extends ConsumerWidget {
  const _TodayMissionSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(dailyMissionStatusProvider).valueOrNull;
    final missions = [
      _MissionData(label: 'Học 10 từ vựng mới', xp: 10, done: status?.vocabDone ?? false),
      _MissionData(label: 'Ôn tập 5 chữ Kanji', xp: 10, done: status?.kanjiDone ?? false),
      _MissionData(label: 'Hoàn thành 1 bài Quiz', xp: 15, done: status?.quizDone ?? false),
      _MissionData(label: 'Trò chuyện cùng AI Kaiwa', xp: 15, done: status?.kaiwaDone ?? false),
    ];
    final doneCount = missions.where((m) => m.done).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const _SectionLabel("Today's Mission"),
            Text(
              '$doneCount/${missions.length}',
              style: const TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                color: AppColors.accent,
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
                if (i > 0)
                  const Divider(height: 1, color: AppColors.canvas),
                _MissionRow(mission: missions[i]),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _MissionRow extends StatelessWidget {
  const _MissionRow({required this.mission});

  final _MissionData mission;

  @override
  Widget build(BuildContext context) {
    final done = mission.done;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: done ? AppColors.moss : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: done ? AppColors.moss : AppColors.border,
                width: 2,
              ),
            ),
            alignment: Alignment.center,
            child: done
                ? const Icon(Icons.check_rounded,
                    size: 14, color: Colors.white,)
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              mission.label,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 13,
                color: done ? AppColors.inkFaint : AppColors.ink,
                decoration:
                    done ? TextDecoration.lineThrough : TextDecoration.none,
              ),
            ),
          ),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
            decoration: BoxDecoration(
              color: done ? AppColors.mossSoft : AppColors.chip,
              borderRadius: BorderRadius.circular(100),
            ),
            child: Text(
              '+${mission.xp} XP',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: done ? AppColors.moss : AppColors.inkFaint,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 1 thanh phần trăm trong thẻ "Tiến độ" — [pct] tính thật từ
/// known-count/total của progress provider tương ứng (đồng bộ cách tính với
/// banner "x/y đã thuộc" ở các màn danh sách), không có kỹ năng nào bị bịa số.
class _ProgressBarData {
  const _ProgressBarData(
      {required this.label, required this.color, required this.pct,});

  final String label;
  final Color color;
  final int pct;
}

class _ProgressCard extends StatelessWidget {
  const _ProgressCard({required this.bars});

  final List<_ProgressBarData> bars;

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
        children: [
          for (var i = 0; i < bars.length; i++) ...[
            if (i > 0) const SizedBox(height: 14),
            _ProgressBarRow(bar: bars[i]),
          ],
        ],
      ),
    );
  }
}

class _ProgressBarRow extends StatelessWidget {
  const _ProgressBarRow({required this.bar});

  final _ProgressBarData bar;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration:
                      BoxDecoration(color: bar.color, shape: BoxShape.circle),
                ),
                const SizedBox(width: 8),
                Text(bar.label,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 12.5,
                        color: AppColors.ink,),),
              ],
            ),
            Text('${bar.pct}%',
                style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 11,
                    color: bar.color,),),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(100),
          child: LinearProgressIndicator(
            value: bar.pct / 100,
            minHeight: 8,
            backgroundColor: AppColors.chip,
            valueColor: AlwaysStoppedAnimation(bar.color),
          ),
        ),
      ],
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
    return InkWell(
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
                    color: AppColors.moss,),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(vocab.word,
                          style: AppFonts.zenMaruGothic(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: AppColors.ink,),),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(vocab.reading,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppFonts.zenMaruGothic(
                                fontSize: 10.5, color: AppColors.inkSoft,),),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(meaningVi,
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.inkSoft,),),
                  if (meaning?.exampleJp != null) ...[
                    const SizedBox(height: 4),
                    Text(meaning!.exampleJp!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 10.5,
                            color: AppColors.inkFaint,
                            fontStyle: FontStyle.italic,),),
                  ],
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded,
                color: AppColors.inkFaint, size: 20,),
          ],
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
        color: AppColors.inkFaint,
        letterSpacing: 0.6,
      ),
    );
  }
}
