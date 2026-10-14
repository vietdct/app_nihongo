import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../../domain/entities/kanji_progress.dart';
import '../../domain/entities/lesson.dart';
import '../../shared/debounced_search_field.dart';
import '../../shared/lesson_filter_dropdown.dart';
import '../../shared/level_badge.dart';
import '../../shared/skeleton_layouts.dart';
import '../../shared/state_views.dart';
import '../lesson/providers/content_providers.dart';
import '../lesson/providers/content_state.dart';
import '../lesson/providers/level_providers.dart';
import 'providers/kanji_progress_providers.dart';

final _kanjiSearchQueryProvider = StateProvider<String>((ref) => '');
final _showStarredOnlyProvider = StateProvider<bool>((ref) => false);
final _selectedLessonFilterProvider = StateProvider<String?>((ref) => null);

class KanjiListScreen extends ConsumerWidget {
  const KanjiListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final kanjiAsync = resolveContentList(ref, ref.watch(kanjiListProvider));
    final query = ref.watch(_kanjiSearchQueryProvider).trim();
    final selectedLevel = ref.watch(selectedLevelCodeProvider);
    final showStarredOnly = ref.watch(_showStarredOnlyProvider);
    final progressMap = ref.watch(kanjiProgressProvider).valueOrNull ??
        const <String, KanjiProgress>{};
    final assignments = ref.watch(kanjiLessonAssignmentsProvider).valueOrNull ??
        const <String, LessonAssignment>{};
    final kanjiLessonIds = assignments.values.map((a) => a.lessonId).toSet();
    final lessons = (ref.watch(lessonsProvider).valueOrNull ?? const [])
        .where((l) => kanjiLessonIds.contains(l.id))
        .toList();
    final rawSelectedLesson = ref.watch(_selectedLessonFilterProvider);
    final selectedLesson = rawSelectedLesson == null ||
            rawSelectedLesson == unassignedLessonFilter ||
            lessons.any((l) => l.id == rawSelectedLesson)
        ? rawSelectedLesson
        : null;

    return Scaffold(
      appBar: AppBar(
        title: Text(selectedLevel == 'IT' ? 'Kanji trong từ vựng IT' : 'Kanji'),
        actions: [
          IconButton(
            tooltip: 'Vẽ để tìm kanji',
            icon: const Icon(Icons.draw_outlined),
            onPressed: () => context.push('/kanji/draw'),
          ),
          IconButton(
            tooltip: showStarredOnly ? 'Xem tất cả' : 'Chỉ xem chữ đã lưu',
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
          if (selectedLevel == 'IT')
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
              child: Text(
                kanjiAsync.valueOrNull == null
                    ? 'Kanji được tổng hợp từ các từ vựng của khóa Tiếng Nhật IT.'
                    : '${kanjiAsync.valueOrNull!.length} chữ Kanji được tổng hợp từ các từ vựng của khóa Tiếng Nhật IT.',
                style:
                    const TextStyle(fontSize: 12.5, color: AppColors.inkSoft),
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
            child: DebouncedSearchField(
              hintText: 'Tra kanji hoặc nghĩa...',
              onChanged: (v) =>
                  ref.read(_kanjiSearchQueryProvider.notifier).state = v,
            ),
          ),
          kanjiAsync.maybeWhen(
            data: (all) => all.isEmpty
                ? const SizedBox.shrink()
                : Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                    child: LessonFilterDropdown(
                      lessons: lessons,
                      selected: selectedLesson,
                      hasUnassigned:
                          all.any((k) => !assignments.containsKey(k.id)),
                      onSelected: (id) => ref
                          .read(_selectedLessonFilterProvider.notifier)
                          .state = id,
                      accentColor: AppColors.indigo,
                    ),
                  ),
            orElse: () => const SizedBox.shrink(),
          ),
          kanjiAsync.maybeWhen(
            data: (all) => all.isEmpty
                ? const SizedBox.shrink()
                : _KnownCountBanner(
                    knownCount: all
                        .where((k) => progressMap[k.id]?.isKnown == true)
                        .length,
                    total: all.length,
                  ),
            orElse: () => const SizedBox.shrink(),
          ),
          Expanded(
            child: kanjiAsync.when(
              loading: () => const KanjiGridSkeleton(),
              error: (e, _) => ErrorState(
                error: e,
                onRetry: () =>
                    retryContentSync(ref, streamProvider: kanjiListProvider),
              ),
              data: (all) {
                if (all.isEmpty) {
                  return RefreshIndicator(
                    onRefresh: () => pullToRefreshContent(context, ref),
                    child: EmptyState(
                      icon: Icons.edit_outlined,
                      title: 'Chưa có kanji nào cho $selectedLevel',
                      message:
                          'Nội dung đang được bổ sung dần. Kéo xuống để làm mới.',
                    ),
                  );
                }

                var filtered = all;
                if (selectedLesson == unassignedLessonFilter) {
                  filtered = filtered
                      .where((k) => !assignments.containsKey(k.id))
                      .toList();
                } else if (selectedLesson != null) {
                  filtered = filtered
                      .where(
                        (k) => assignments[k.id]?.lessonId == selectedLesson,
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
                        (k) =>
                            k.character.contains(query) ||
                            k.meaningVi.any(
                              (m) =>
                                  m.toLowerCase().contains(query.toLowerCase()),
                            ),
                      )
                      .toList();
                }
                if (showStarredOnly) {
                  filtered = filtered
                      .where((k) => progressMap[k.id]?.starred == true)
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
                          ? 'Chưa có chữ nào được lưu'
                          : 'Không tìm thấy kanji nào',
                      message: showStarredOnly
                          ? 'Mở flashcard và chạm ngôi sao để lưu chữ lại.'
                          : 'Thử đổi từ khoá hoặc bộ lọc bài học.',
                    ),
                  );
                }
                return RefreshIndicator(
                  onRefresh: () => pullToRefreshContent(context, ref),
                  child: GridView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 4,
                      mainAxisSpacing: 10,
                      crossAxisSpacing: 10,
                      childAspectRatio: 0.9,
                    ),
                    itemCount: filtered.length,
                    itemBuilder: (context, i) {
                      final k = filtered[i];
                      final starred = progressMap[k.id]?.starred == true;
                      return InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () => context.push('/kanji/${k.id}'),
                        child: Container(
                          decoration: BoxDecoration(
                            color: AppColors.card,
                            borderRadius: BorderRadius.circular(16),
                            border:
                                Border.all(color: AppColors.border, width: 1.0),
                          ),
                          child: Stack(
                            children: [
                              Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      k.character,
                                      style: AppFonts.zenMaruGothic(
                                        fontSize: 26,
                                        color: AppColors.ink,
                                      ),
                                    ),
                                    const SizedBox(height: 5),
                                    Text(
                                      k.meaningVi.join(', '),
                                      style: const TextStyle(
                                        fontSize: 10.5,
                                        color: AppColors.inkSoft,
                                      ),
                                      textAlign: TextAlign.center,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              if (starred)
                                const Positioned(
                                  top: 5,
                                  right: 5,
                                  child: Icon(
                                    Icons.star_rounded,
                                    size: 14,
                                    color: AppColors.accent,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
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
          color: AppColors.indigoSoft,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.check_circle_rounded,
              size: 17,
              color: AppColors.indigo,
            ),
            const SizedBox(width: 8),
            Text(
              '$knownCount/$total chữ đã thuộc',
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: AppColors.indigo,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
