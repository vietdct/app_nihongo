import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../../domain/entities/lesson.dart';
import '../../domain/entities/vocab_progress.dart';
import '../../domain/entities/vocabulary.dart';
import '../../domain/services/word_of_the_day.dart';
import '../../shared/jp_speak_button.dart';
import '../../shared/level_badge.dart';
import '../../shared/motion/press_scale.dart';
import '../../shared/skeleton_layouts.dart';
import '../../shared/state_views.dart';
import '../lesson/providers/content_providers.dart';
import '../lesson/providers/content_state.dart';
import '../lesson/providers/level_providers.dart';
import 'providers/vocab_progress_providers.dart';
import 'vocabulary_list_screen.dart' show showVocabDetailSheet;

const _masteredIntervalDays = 30.0;
const _minEase = 1.3;
const _maxEase = 3.0;

/// Dashboard Từ vựng — thay cho `VocabularyListScreen` phẳng cũ ở route gốc
/// `/vocabulary` (danh sách đầy đủ chuyển sang `/vocabulary/list`, xem
/// `app_router.dart`), theo đúng pattern `KanjiHomeScreen`/`GrammarHomeScreen`.
/// Toàn bộ số liệu là thật, tính từ `vocabularyListProvider`/
/// `vocabProgressProvider` đã có — "Độ chính xác" là ease factor thật (SM-2,
/// xem `srs_scheduler.dart`) chuẩn hoá về thang 0-100%, KHÔNG phải log
/// đúng/sai riêng (app chưa lưu lịch sử từng lượt trả lời).
class VocabularyHomeScreen extends ConsumerWidget {
  const VocabularyHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vocabAsync =
        resolveContentList(ref, ref.watch(vocabularyListProvider));
    final progressAsync = ref.watch(vocabProgressProvider);
    final selectedLevel = ref.watch(selectedLevelCodeProvider);
    final assignments =
        ref.watch(vocabularyLessonAssignmentsProvider).valueOrNull ??
            const <String, LessonAssignment>{};
    final lessons = (ref.watch(lessonsProvider).valueOrNull ?? const <Lesson>[])
        .toList()
      ..sort((a, b) => a.orderIndex.compareTo(b.orderIndex));

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        title: Text(
          selectedLevel == 'IT'
              ? 'Từ vựng IT${vocabAsync.valueOrNull == null ? '' : ' · ${vocabAsync.valueOrNull!.length} từ'}'
              : 'Từ vựng',
        ),
        actions: [
          IconButton(
            tooltip: 'Làm mới nội dung',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => _refreshVocabularyContent(context, ref),
          ),
          const LevelBadge(),
          const SizedBox(width: 12),
        ],
      ),
      body: vocabAsync.when(
        loading: () => const SectionedHomeSkeleton(),
        error: (e, _) => ErrorState(
          error: e,
          onRetry: () =>
              retryContentSync(ref, streamProvider: vocabularyListProvider),
        ),
        data: (all) {
          if (all.isEmpty) {
            return RefreshIndicator(
              onRefresh: () => pullToRefreshContent(context, ref),
              child: EmptyState(
                icon: Icons.translate_rounded,
                title: 'Chưa có từ vựng nào cho $selectedLevel',
                message:
                    'Nội dung đang được bổ sung dần. Kéo xuống để làm mới.',
              ),
            );
          }

          final progress =
              progressAsync.valueOrNull ?? const <String, VocabProgress>{};
          final wordOfDay = pickWordOfTheDay(pool: all, levelId: selectedLevel);

          var newCount = 0;
          var learnedCount = 0;
          var masteredCount = 0;
          var dueCount = 0;
          var easeSum = 0.0;
          var easeCount = 0;
          final starredItems = <Vocabulary>[];
          final recentEntries = <MapEntry<Vocabulary, VocabProgress>>[];
          for (final v in all) {
            final p = progress[v.id];
            final touched =
                p != null && (p.isKnown != null || p.reviewCount > 0);
            if (touched) {
              learnedCount++;
            } else {
              newCount++;
            }
            if ((p?.intervalDays ?? 0) >= _masteredIntervalDays) {
              masteredCount++;
            }
            if (p == null || p.isDueNow) dueCount++;
            if (p != null && p.reviewCount > 0) {
              easeSum += p.easeFactor;
              easeCount++;
            }
            if (p?.starred == true) starredItems.add(v);
            if (touched && p.updatedAt != null) {
              recentEntries.add(MapEntry(v, p));
            }
          }
          recentEntries.sort(
            (a, b) => b.value.updatedAt!.compareTo(a.value.updatedAt!),
          );
          final recentItems = recentEntries.take(8).toList();
          final learnedPct = (learnedCount / all.length * 100).round();
          final masteredPct = (masteredCount / all.length * 100).round();
          final accuracyPct = easeCount == 0
              ? 0
              : (((easeSum / easeCount) - _minEase) /
                      (_maxEase - _minEase) *
                      100)
                  .clamp(0, 100)
                  .round();

          return RefreshIndicator(
            onRefresh: () => pullToRefreshContent(context, ref),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
              children: [
                InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () => context.push('/vocabulary/list'),
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
                          'Tra từ vựng hoặc nghĩa...',
                          style: TextStyle(
                            fontSize: 13.5,
                            color: AppColors.inkFaint,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (wordOfDay != null) ...[
                  const SizedBox(height: 20),
                  const _SectionLabel('Từ vựng hôm nay'),
                  const SizedBox(height: 10),
                  _WordOfDayCard(vocab: wordOfDay),
                ],
                const SizedBox(height: 24),
                const _SectionLabel('Hôm nay'),
                const SizedBox(height: 10),
                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: _HeroCard(
                          icon: Icons.auto_awesome_rounded,
                          title: 'Từ vựng hôm nay',
                          value: '$newCount từ mới',
                          colors: const [AppColors.moss, AppColors.teal],
                          onTap: () => context.push('/vocabulary/flashcards'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _HeroCard(
                          icon: Icons.refresh_rounded,
                          title: 'Ôn tập SRS',
                          value: '$dueCount từ cần ôn',
                          colors: const [
                            AppColors.accent,
                            AppColors.accentStrong,
                          ],
                          onTap: () => context.push('/vocabulary/review'),
                        ),
                      ),
                    ],
                  ),
                ),
                ..._lessonDeckSection(
                  context,
                  lessons,
                  assignments,
                  isIt: selectedLevel == 'IT',
                ),
                const SizedBox(height: 24),
                const _SectionLabel('Tiến độ học tập'),
                const SizedBox(height: 10),
                Container(
                  padding:
                      const EdgeInsets.symmetric(vertical: 18, horizontal: 8),
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppColors.border, width: 1.0),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: _ProgressRing(
                          label: 'Đã học',
                          sublabel: '$learnedCount/${all.length} từ',
                          percent: learnedPct,
                          color: AppColors.moss,
                        ),
                      ),
                      Expanded(
                        child: _ProgressRing(
                          label: 'Đã thuộc',
                          sublabel: '$masteredCount/${all.length} từ',
                          percent: masteredPct,
                          color: AppColors.indigo,
                        ),
                      ),
                      Expanded(
                        child: _ProgressRing(
                          label: 'Độ chính xác',
                          sublabel: easeCount == 0
                              ? 'Chưa có dữ liệu'
                              : '$easeCount từ đã ôn',
                          percent: accuracyPct,
                          color: AppColors.accent,
                        ),
                      ),
                    ],
                  ),
                ),
                if (starredItems.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const _SectionLabel('Yêu thích'),
                      InkWell(
                        onTap: () => context.push('/vocabulary/list'),
                        child: const Text(
                          'Xem tất cả',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.moss,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 132,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: starredItems.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 10),
                      itemBuilder: (context, i) => _VocabMiniCard(
                        vocab: starredItems[i],
                        trailingIcon: Icons.star_rounded,
                        trailingColor: AppColors.accent,
                        onTap: () =>
                            showVocabDetailSheet(context, starredItems[i]),
                      ),
                    ),
                  ),
                ],
                if (recentItems.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  const _SectionLabel('Học gần đây'),
                  const SizedBox(height: 10),
                  SizedBox(
                    // Cao hơn thẻ "Yêu thích" (132) vì thẻ này còn có thêm
                    // badge trạng thái bên dưới — nếu chỉ 132, nghĩa dài 2
                    // dòng (vd それ "cái đó (gần người nghe)") + badge sẽ
                    // tràn ra ngoài Column (RenderFlex overflow).
                    height: 144,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: recentItems.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 10),
                      itemBuilder: (context, i) {
                        final vocab = recentItems[i].key;
                        final p = recentItems[i].value;
                        final String badge;
                        final Color badgeColor;
                        if (p.isKnown == true) {
                          badge = 'Đã thuộc';
                          badgeColor = AppColors.moss;
                        } else if (p.isKnown == false) {
                          badge = 'Đang học';
                          badgeColor = AppColors.accentStrong;
                        } else {
                          badge = 'Đang ôn';
                          badgeColor = AppColors.indigo;
                        }
                        return _VocabMiniCard(
                          vocab: vocab,
                          badge: badge,
                          badgeColor: badgeColor,
                          onTap: () => showVocabDetailSheet(context, vocab),
                        );
                      },
                    ),
                  ),
                ],
                const SizedBox(height: 28),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => context.push('/vocabulary/list'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.moss,
                          side: const BorderSide(color: AppColors.moss),
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
                      child: FilledButton(
                        onPressed: () => context.push('/vocabulary/review'),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.moss,
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                        ),
                        child: const Text(
                          'Ôn tập',
                          style: TextStyle(fontSize: 12.5),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: FilledButton(
                        onPressed: () => context.push('/vocabulary/flashcards'),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.teal,
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                        ),
                        child: const Text(
                          'Flashcard',
                          style: TextStyle(fontSize: 12.5),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  /// "Flashcard theo bài" — mỗi bài 1 bộ thẻ riêng, mở sẵn chế độ ngẫu nhiên.
  List<Widget> _lessonDeckSection(
    BuildContext context,
    List<Lesson> lessons,
    Map<String, LessonAssignment> assignments, {
    bool isIt = false,
  }) {
    final counts = <String, int>{};
    for (final a in assignments.values) {
      counts.update(a.lessonId, (n) => n + 1, ifAbsent: () => 1);
    }
    final decks = lessons.where((l) => (counts[l.id] ?? 0) > 0).toList();
    if (decks.isEmpty) return const [];
    return [
      const SizedBox(height: 24),
      _SectionLabel(
        isIt ? 'Học theo bài · Flashcard' : 'Flashcard theo bài',
      ),
      const SizedBox(height: 10),
      SizedBox(
        height: 112,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: decks.length,
          separatorBuilder: (_, __) => const SizedBox(width: 10),
          itemBuilder: (context, i) => _LessonDeckCard(
            lesson: decks[i],
            wordCount: counts[decks[i].id]!,
            onTap: () => context.push(
              '/vocabulary/flashcards?lesson=${decks[i].id}&shuffle=1',
            ),
          ),
        ),
      ),
    ];
  }

  Future<void> _refreshVocabularyContent(
    BuildContext context,
    WidgetRef ref,
  ) async {
    ref.invalidate(contentRefreshProvider);
    try {
      await ref.read(contentRefreshProvider.future);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã làm mới nội dung từ vựng.')),
      );
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Không thể làm mới nội dung. Hãy kiểm tra mạng.'),
        ),
      );
    }
  }
}

/// Thẻ "Từ vựng hôm nay" đầu Vocabulary Home — từ chọn deterministic bằng
/// [pickWordOfTheDay] (xem `word_of_the_day.dart`), có nút loa phát âm thật
/// (`JpSpeakButton`) và ví dụ thật lấy từ nghĩa đầu tiên, không bịa thêm câu
/// nào ngoài dữ liệu đã có. Nút "Dùng trong AI Kaiwa" mở luồng chọn tình
/// huống/nhân vật với gợi ý dùng từ này trong hội thoại (xem
/// `kaiwa_chat_service.dart` — seedWord truyền qua `extra` của go_router).
class _WordOfDayCard extends StatelessWidget {
  const _WordOfDayCard({required this.vocab});

  final Vocabulary vocab;

  @override
  Widget build(BuildContext context) {
    final meaning = vocab.meanings.isEmpty ? null : vocab.meanings.first;
    final meaningVi = vocab.primaryMeaning.isEmpty
        ? 'Đang cập nhật nghĩa…'
        : vocab.primaryMeaning;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.mossSoft, AppColors.tealSoft],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border, width: 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          vocab.word,
                          style: AppFonts.zenMaruGothic(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: AppColors.ink,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          vocab.reading,
                          style: AppFonts.zenMaruGothic(
                            fontSize: 13,
                            color: AppColors.inkSoft,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      meaningVi,
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.ink,
                      ),
                    ),
                  ],
                ),
              ),
              JpSpeakButton(text: vocab.word, color: AppColors.moss),
            ],
          ),
          if (meaning?.exampleJp != null) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    meaning!.exampleJp!,
                    style: AppFonts.zenMaruGothic(
                      fontSize: 13.5,
                      color: AppColors.ink,
                    ),
                  ),
                  if (meaning.exampleVi != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      meaning.exampleVi!,
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: AppColors.inkSoft,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => showVocabDetailSheet(context, vocab),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.moss,
                    side: const BorderSide(color: AppColors.moss),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  icon: const Icon(Icons.menu_book_rounded, size: 16),
                  label: const Text(
                    'Xem chi tiết',
                    style: TextStyle(fontSize: 12.5),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton.icon(
                  onPressed: () =>
                      context.push('/kaiwa/topics', extra: vocab.word),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.teal,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  icon: const Icon(Icons.forum_rounded, size: 16),
                  label: const Text(
                    'Dùng trong AI Kaiwa',
                    style: TextStyle(fontSize: 12.5),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Thẻ nhỏ cho danh sách ngang (Yêu thích / Học gần đây) — chạm để mở
/// [showVocabDetailSheet], cùng nội dung với `_VocabTile` ở danh sách phẳng.
class _VocabMiniCard extends StatelessWidget {
  const _VocabMiniCard({
    required this.vocab,
    required this.onTap,
    this.badge,
    this.badgeColor,
    this.trailingIcon,
    this.trailingColor,
  });

  final Vocabulary vocab;
  final VoidCallback onTap;
  final String? badge;
  final Color? badgeColor;
  final IconData? trailingIcon;
  final Color? trailingColor;

  @override
  Widget build(BuildContext context) {
    return PressScale(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          width: 148,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border, width: 1.0),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      vocab.word,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppFonts.zenMaruGothic(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppColors.ink,
                      ),
                    ),
                  ),
                  if (trailingIcon != null)
                    Icon(trailingIcon, size: 16, color: trailingColor),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                vocab.reading,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppFonts.zenMaruGothic(
                  fontSize: 11.5,
                  color: AppColors.inkSoft,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                vocab.primaryMeaning,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12, color: AppColors.inkSoft),
              ),
              if (badge != null) ...[
                const SizedBox(height: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: (badgeColor ?? AppColors.inkFaint)
                        .withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: Text(
                    badge!,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: badgeColor ?? AppColors.inkFaint,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Thẻ 1 bài trong "Flashcard theo bài" — chạm để ôn ngẫu nhiên riêng bài đó.
class _LessonDeckCard extends StatelessWidget {
  const _LessonDeckCard({
    required this.lesson,
    required this.wordCount,
    required this.onTap,
  });

  final Lesson lesson;
  final int wordCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return PressScale(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          width: 156,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border, width: 1.0),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 12,
                    backgroundColor: AppColors.mossSoft,
                    foregroundColor: AppColors.moss,
                    child: Text(
                      '${lesson.orderIndex}',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const Spacer(),
                  const Icon(
                    Icons.shuffle_rounded,
                    size: 16,
                    color: AppColors.teal,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Expanded(
                child: Text(
                  lesson.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppFonts.zenMaruGothic(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: AppColors.ink,
                  ),
                ),
              ),
              Text(
                '$wordCount từ',
                style:
                    const TextStyle(fontSize: 11.5, color: AppColors.inkSoft),
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
        color: AppColors.inkFaint,
        letterSpacing: 0.6,
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.colors,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String value;
  final List<Color> colors;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return PressScale(
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: colors,
            ),
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: colors.first.withValues(alpha: 0.3),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: Colors.white, size: 22),
              const SizedBox(height: 10),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 12.5,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProgressRing extends StatelessWidget {
  const _ProgressRing({
    required this.label,
    required this.sublabel,
    required this.percent,
    required this.color,
  });

  final String label;
  final String sublabel;
  final int percent;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 72,
          height: 72,
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: percent / 100),
            duration: const Duration(milliseconds: 800),
            curve: Curves.easeOutCubic,
            builder: (context, value, _) => Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: value,
                  strokeWidth: 7,
                  backgroundColor: AppColors.chip,
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                ),
                Text(
                  '${(value * 100).round()}%',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                    color: AppColors.ink,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 12,
            color: AppColors.ink,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          sublabel,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 10.5, color: AppColors.inkSoft),
        ),
      ],
    );
  }
}
