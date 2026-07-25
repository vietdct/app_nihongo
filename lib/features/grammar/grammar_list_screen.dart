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
import '../lesson/providers/content_providers.dart';
import '../lesson/providers/level_providers.dart';
import 'providers/grammar_progress_providers.dart';

final _grammarSearchQueryProvider = StateProvider<String>((ref) => '');
final _showStarredOnlyProvider = StateProvider<bool>((ref) => false);
final _selectedLessonFilterProvider = StateProvider<String?>((ref) => null);

class GrammarListScreen extends ConsumerWidget {
  const GrammarListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final grammarAsync = ref.watch(grammarListProvider);
    final query = ref.watch(_grammarSearchQueryProvider).trim().toLowerCase();
    final selectedLevel = ref.watch(selectedLevelCodeProvider);
    final showStarredOnly = ref.watch(_showStarredOnlyProvider);
    final progressMap = ref.watch(grammarProgressProvider).valueOrNull ??
        const <String, GrammarProgress>{};
    final lessons = ref.watch(lessonsProvider).valueOrNull ?? const [];
    final assignments =
        ref.watch(grammarLessonAssignmentsProvider).valueOrNull ??
            const <String, LessonAssignment>{};
    final rawSelectedLesson = ref.watch(_selectedLessonFilterProvider);
    final selectedLesson = rawSelectedLesson == null ||
            rawSelectedLesson == unassignedLessonFilter ||
            lessons.any((l) => l.id == rawSelectedLesson)
        ? rawSelectedLesson
        : null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ngữ pháp'),
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
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Lỗi: $e')),
              data: (all) {
                if (all.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        'Chưa có ngữ pháp nào cho $selectedLevel.\nNội dung đang được bổ sung dần.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: AppColors.inkSoft),
                      ),
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
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        showStarredOnly
                            ? 'Chưa có ngữ pháp nào được lưu.\nMở Flashcard và chạm ngôi sao để lưu lại.'
                            : 'Không tìm thấy ngữ pháp nào.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: AppColors.inkSoft),
                      ),
                    ),
                  );
                }
                return Container(
                  margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppColors.border, width: 0.6),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: ListView.separated(
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) =>
                        const Divider(height: 1, color: AppColors.border),
                    itemBuilder: (context, i) => _GrammarTile(
                      grammar: filtered[i],
                      starred: progressMap[filtered[i].id]?.starred == true,
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
      onTap: () => showModalBottomSheet(
        context: context,
        showDragHandle: true,
        backgroundColor: AppColors.card,
        isScrollControlled: true,
        builder: (_) => _GrammarDetailSheet(grammar: grammar),
      ),
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

class _GrammarDetailSheet extends StatelessWidget {
  const _GrammarDetailSheet({required this.grammar});

  final GrammarPoint grammar;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 30),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                grammar.title,
                style: AppFonts.zenMaruGothic(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                grammar.explanation,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                  color: AppColors.ink,
                  height: 1.5,
                ),
              ),
              if (grammar.exampleJp != null) ...[
                const SizedBox(height: 14),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.chip,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        grammar.exampleJp!,
                        style: AppFonts.zenMaruGothic(
                          fontSize: 15,
                          fontWeight: FontWeight.w400,
                          color: AppColors.ink,
                        ),
                      ),
                      if (grammar.exampleVi != null) ...[
                        const SizedBox(height: 6),
                        Text(
                          grammar.exampleVi!,
                          style: const TextStyle(
                            fontSize: 12.5,
                            color: AppColors.inkSoft,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
              if (grammar.commonMistake != null)
                _InfoBlock(
                  icon: Icons.error_outline_rounded,
                  color: AppColors.accentStrong,
                  label: 'Lỗi thường gặp',
                  content: grammar.commonMistake!,
                ),
              if (grammar.memoryTip != null)
                _InfoBlock(
                  icon: Icons.lightbulb_outline_rounded,
                  color: AppColors.moss,
                  label: 'Mẹo ghi nhớ',
                  content: grammar.memoryTip!,
                ),
              if (grammar.comparisonNote != null)
                _InfoBlock(
                  icon: Icons.compare_arrows_rounded,
                  color: AppColors.indigo,
                  label: 'So sánh',
                  content: grammar.comparisonNote!,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoBlock extends StatelessWidget {
  const _InfoBlock({
    required this.icon,
    required this.color,
    required this.label,
    required this.content,
  });

  final IconData icon;
  final Color color;
  final String label;
  final String content;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 15, color: color),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            content,
            style: const TextStyle(
              fontSize: 13.5,
              color: AppColors.ink,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}
