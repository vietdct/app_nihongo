import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../../domain/entities/grammar_point.dart';
import '../../domain/entities/grammar_progress.dart';
import '../../domain/entities/lesson.dart';
import '../../shared/debounced_search_field.dart';
import '../../shared/lesson_filter_dropdown.dart';
import '../../shared/level_badge.dart';
import '../../shared/skeleton_layouts.dart';
import '../../shared/state_views.dart';
import '../lesson/providers/content_providers.dart';
import '../lesson/providers/content_state.dart';
import '../lesson/providers/level_providers.dart';
import 'providers/grammar_progress_providers.dart';

final _grammarSearchQueryProvider = StateProvider<String>((ref) => '');
final _showStarredOnlyProvider = StateProvider<bool>((ref) => false);
final _selectedLessonFilterProvider = StateProvider<String?>((ref) => null);

class GrammarListScreen extends ConsumerWidget {
  const GrammarListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final grammarAsync =
        resolveContentList(ref, ref.watch(grammarListProvider));
    final query = ref.watch(_grammarSearchQueryProvider).trim().toLowerCase();
    final selectedLevel = ref.watch(selectedLevelCodeProvider);
    final showStarredOnly = ref.watch(_showStarredOnlyProvider);
    final progressMap = ref.watch(grammarProgressProvider).valueOrNull ??
        const <String, GrammarProgress>{};
    final assignments =
        ref.watch(grammarLessonAssignmentsProvider).valueOrNull ??
            const <String, LessonAssignment>{};
    final grammarLessonIds = assignments.values.map((a) => a.lessonId).toSet();
    final lessons = (ref.watch(lessonsProvider).valueOrNull ?? const [])
        .where((l) => grammarLessonIds.contains(l.id))
        .toList();
    final rawSelectedLesson = ref.watch(_selectedLessonFilterProvider);
    final selectedLesson = rawSelectedLesson == null ||
            rawSelectedLesson == unassignedLessonFilter ||
            lessons.any((l) => l.id == rawSelectedLesson)
        ? rawSelectedLesson
        : null;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          selectedLevel == 'IT'
              ? 'Ngữ pháp IT${grammarAsync.valueOrNull == null ? '' : ' · ${grammarAsync.valueOrNull!.length} mẫu câu'}'
              : 'Ngữ pháp',
        ),
        actions: [
          IconButton(
            tooltip: 'Học bằng flashcard',
            icon: const Icon(Icons.style_outlined),
            onPressed: () => context.push('/grammar/flashcards'),
          ),
          IconButton(
            tooltip: showStarredOnly ? 'Xem tất cả' : 'Chỉ xem đã lưu',
            icon: Icon(
              showStarredOnly ? Icons.star_rounded : Icons.star_border_rounded,
              color: showStarredOnly ? AppColors.accent : null,
            ),
            onPressed: () => ref.read(_showStarredOnlyProvider.notifier).state =
                !showStarredOnly,
          ),
          const LevelBadge(),
          const SizedBox(width: 12),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
            child: DebouncedSearchField(
              hintText: 'Tra tiêu đề hoặc giải thích ngữ pháp...',
              onChanged: (v) =>
                  ref.read(_grammarSearchQueryProvider.notifier).state = v,
            ),
          ),
          grammarAsync.maybeWhen(
            data: (all) => all.isEmpty
                ? const SizedBox.shrink()
                : Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                    child: LessonFilterDropdown(
                      lessons: lessons,
                      selected: selectedLesson,
                      hasUnassigned:
                          all.any((g) => !assignments.containsKey(g.id)),
                      onSelected: (id) => ref
                          .read(_selectedLessonFilterProvider.notifier)
                          .state = id,
                      accentColor: AppColors.plum,
                    ),
                  ),
            orElse: () => const SizedBox.shrink(),
          ),
          grammarAsync.maybeWhen(
            data: (all) => all.isEmpty
                ? const SizedBox.shrink()
                : _KnownCountBanner(
                    knownCount: all
                        .where((g) => progressMap[g.id]?.isKnown == true)
                        .length,
                    total: all.length,
                  ),
            orElse: () => const SizedBox.shrink(),
          ),
          Expanded(
            child: grammarAsync.when(
              loading: () => const ListCardSkeleton(),
              error: (e, _) => ErrorState(
                error: e,
                onRetry: () => retryContentSync(
                  ref,
                  streamProvider: grammarListProvider,
                ),
              ),
              data: (all) {
                if (all.isEmpty) {
                  return RefreshIndicator(
                    onRefresh: () => pullToRefreshContent(context, ref),
                    child: EmptyState(
                      icon: Icons.description_outlined,
                      title: 'Chưa có ngữ pháp nào cho $selectedLevel',
                      message:
                          'Nội dung đang được bổ sung dần. Kéo xuống để làm mới.',
                    ),
                  );
                }

                var filtered = all;
                if (selectedLesson == unassignedLessonFilter) {
                  filtered = filtered
                      .where((g) => !assignments.containsKey(g.id))
                      .toList();
                } else if (selectedLesson != null) {
                  filtered = filtered
                      .where(
                        (g) => assignments[g.id]?.lessonId == selectedLesson,
                      )
                      .toList()
                    ..sort(
                      (a, b) => (assignments[a.id]?.orderIndex ?? 0)
                          .compareTo(assignments[b.id]?.orderIndex ?? 0),
                    );
                }
                if (query.isNotEmpty) {
                  filtered = filtered
                      .where(
                        (g) =>
                            g.title.toLowerCase().contains(query) ||
                            g.explanation.toLowerCase().contains(query),
                      )
                      .toList();
                }
                if (showStarredOnly) {
                  filtered = filtered
                      .where((g) => progressMap[g.id]?.starred == true)
                      .toList();
                }

                if (filtered.isEmpty) {
                  return RefreshIndicator(
                    onRefresh: () => pullToRefreshContent(context, ref),
                    child: EmptyState(
                      icon: showStarredOnly
                          ? Icons.star_outline_rounded
                          : Icons.search_off_rounded,
                      title: showStarredOnly
                          ? 'Chưa có ngữ pháp nào được lưu'
                          : 'Không tìm thấy ngữ pháp nào',
                      message: showStarredOnly
                          ? 'Mở Flashcard và chạm ngôi sao để lưu lại.'
                          : 'Thử đổi từ khoá hoặc bộ lọc bài học.',
                    ),
                  );
                }
                return RefreshIndicator(
                  onRefresh: () => pullToRefreshContent(context, ref),
                  child: Container(
                    margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: AppColors.border, width: 1.0),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: ListView.separated(
                      physics: const AlwaysScrollableScrollPhysics(),
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) =>
                          const Divider(height: 1, color: AppColors.border),
                      itemBuilder: (context, i) => _GrammarTile(
                        grammar: filtered[i],
                        starred: progressMap[filtered[i].id]?.starred == true,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _KnownCountBanner extends StatelessWidget {
  const _KnownCountBanner({required this.knownCount, required this.total});

  final int knownCount;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.plumSoft,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.check_circle_rounded,
              size: 17,
              color: AppColors.plum,
            ),
            const SizedBox(width: 8),
            Text(
              '$knownCount/$total điểm ngữ pháp đã thuộc',
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: AppColors.plum,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GrammarTile extends StatelessWidget {
  const _GrammarTile({required this.grammar, required this.starred});

  final GrammarPoint grammar;
  final bool starred;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => context.push('/grammar/${grammar.id}'),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    grammar.title,
                    style: AppFonts.zenMaruGothic(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.ink,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    grammar.explanation,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: AppColors.inkSoft,
                    ),
                  ),
                ],
              ),
            ),
            if (starred)
              const Padding(
                padding: EdgeInsets.only(left: 6, top: 1),
                child:
                    Icon(Icons.star_rounded, size: 16, color: AppColors.accent),
              ),
          ],
        ),
      ),
    );
  }
}
