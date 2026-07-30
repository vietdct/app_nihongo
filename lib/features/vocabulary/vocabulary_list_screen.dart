import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../../domain/entities/lesson.dart';
import '../../domain/entities/vocab_meaning.dart';
import '../../domain/entities/vocab_progress.dart';
import '../../domain/entities/vocabulary.dart';
import '../../shared/debounced_search_field.dart';
import '../../shared/lesson_filter_dropdown.dart';
import '../../shared/level_badge.dart';
import '../lesson/providers/content_providers.dart';
import '../lesson/providers/level_providers.dart';
import 'providers/vocab_progress_providers.dart';

final _vocabSearchQueryProvider = StateProvider<String>((ref) => '');
final _showStarredOnlyProvider = StateProvider<bool>((ref) => false);
final _selectedLessonFilterProvider = StateProvider<String?>((ref) => null);

class VocabularyListScreen extends ConsumerWidget {
  const VocabularyListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vocabAsync = ref.watch(vocabularyListProvider);
    final query = ref.watch(_vocabSearchQueryProvider).trim().toLowerCase();
    final selectedLevel = ref.watch(selectedLevelCodeProvider);
    final showStarredOnly = ref.watch(_showStarredOnlyProvider);
    final progressMap = ref.watch(vocabProgressProvider).valueOrNull ??
        const <String, VocabProgress>{};
    final lessons = ref.watch(lessonsProvider).valueOrNull ?? const [];
    final assignments =
        ref.watch(vocabularyLessonAssignmentsProvider).valueOrNull ??
            const <String, LessonAssignment>{};
    final rawSelectedLesson = ref.watch(_selectedLessonFilterProvider);
    final selectedLesson = rawSelectedLesson == null ||
            rawSelectedLesson == unassignedLessonFilter ||
            lessons.any((l) => l.id == rawSelectedLesson)
        ? rawSelectedLesson
        : null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Từ vựng'),
        actions: [
          IconButton(
            tooltip: showStarredOnly ? 'Xem tất cả' : 'Chỉ xem từ đã lưu',
            icon: Icon(
              showStarredOnly ? Icons.star_rounded : Icons.star_border_rounded,
              color: showStarredOnly ? AppColors.accent : null,
            ),
            onPressed: () => ref.read(_showStarredOnlyProvider.notifier).state =
                !showStarredOnly,
          ),
          IconButton(
            tooltip: 'Học bằng flashcard',
            icon: const Icon(Icons.style_outlined),
            onPressed: () => context.push('/vocabulary/flashcards'),
          ),
          IconButton(
            tooltip: 'Ôn tập theo lịch SRS',
            icon: const Icon(Icons.replay_circle_filled_outlined),
            onPressed: () => context.push('/vocabulary/review'),
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
              hintText: 'Tra từ (chữ Nhật hoặc cách đọc)...',
              onChanged: (v) =>
                  ref.read(_vocabSearchQueryProvider.notifier).state = v,
            ),
          ),
          vocabAsync.maybeWhen(
            data: (all) => all.isEmpty
                ? const SizedBox.shrink()
                : Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                    child: LessonFilterDropdown(
                      lessons: lessons,
                      selected: selectedLesson,
                      hasUnassigned:
                          all.any((v) => !assignments.containsKey(v.id)),
                      onSelected: (id) => ref
                          .read(_selectedLessonFilterProvider.notifier)
                          .state = id,
                      accentColor: AppColors.moss,
                    ),
                  ),
            orElse: () => const SizedBox.shrink(),
          ),
          vocabAsync.maybeWhen(
            data: (all) => all.isEmpty
                ? const SizedBox.shrink()
                : _KnownCountBanner(
                    knownCount: all
                        .where((v) => progressMap[v.id]?.isKnown == true)
                        .length,
                    total: all.length,
                  ),
            orElse: () => const SizedBox.shrink(),
          ),
          Expanded(
            child: vocabAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Lỗi: $e')),
              data: (all) {
                var filtered = all;
                if (selectedLesson == unassignedLessonFilter) {
                  filtered = filtered
                      .where((v) => !assignments.containsKey(v.id))
                      .toList();
                } else if (selectedLesson != null) {
                  filtered = filtered
                      .where(
                        (v) => assignments[v.id]?.lessonId == selectedLesson,
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
                        (v) =>
                            v.word.toLowerCase().contains(query) ||
                            v.reading.toLowerCase().contains(query) ||
                            v.meanings.any(
                              (m) => m.meaningVi.toLowerCase().contains(query),
                            ),
                      )
                      .toList();
                }
                if (showStarredOnly) {
                  filtered = filtered
                      .where((v) => progressMap[v.id]?.starred == true)
                      .toList();
                }

                if (all.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        'Chưa có từ vựng nào cho $selectedLevel.\nNội dung đang được bổ sung dần.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: AppColors.inkSoft),
                      ),
                    ),
                  );
                }
                if (filtered.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        showStarredOnly
                            ? 'Chưa có từ nào được lưu.\nMở Flashcard và chạm ngôi sao để lưu từ lại.'
                            : 'Không tìm thấy từ nào.',
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
                    border: Border.all(color: AppColors.border, width: 1.0),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: ListView.separated(
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) =>
                        const Divider(height: 1, color: AppColors.border),
                    itemBuilder: (context, i) => _VocabTile(
                      vocab: filtered[i],
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
          color: AppColors.mossSoft,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.check_circle_rounded,
              size: 17,
              color: AppColors.moss,
            ),
            const SizedBox(width: 8),
            Text(
              '$knownCount/$total từ đã thuộc',
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: AppColors.moss,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VocabTile extends StatelessWidget {
  const _VocabTile({required this.vocab, required this.starred});

  final Vocabulary vocab;
  final bool starred;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => showVocabDetailSheet(context, vocab),
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
                    '${vocab.word} 「${vocab.reading}」',
                    style: AppFonts.zenMaruGothic(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.ink,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    vocab.meanings.length > 1
                        ? '${vocab.primaryMeaning} · +${vocab.meanings.length - 1} nghĩa khác'
                        : vocab.primaryMeaning,
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
            if (vocab.partOfSpeech != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.chip,
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Text(
                  vocab.partOfSpeech!,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: AppColors.inkFaint,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Mở bottom sheet chi tiết 1 từ vựng — dùng chung giữa danh sách phẳng
/// (`VocabularyListScreen`) và các mini-card trên `VocabularyHomeScreen`.
void showVocabDetailSheet(BuildContext context, Vocabulary vocab) {
  showModalBottomSheet(
    context: context,
    showDragHandle: true,
    backgroundColor: AppColors.card,
    builder: (_) => VocabDetailSheet(vocab: vocab),
  );
}

class VocabDetailSheet extends StatelessWidget {
  const VocabDetailSheet({super.key, required this.vocab});

  final Vocabulary vocab;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 30),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      vocab.word,
                      style: AppFonts.zenMaruGothic(
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        color: AppColors.ink,
                      ),
                    ),
                    Text(
                      vocab.reading,
                      style: AppFonts.zenMaruGothic(
                        fontSize: 15,
                        fontWeight: FontWeight.w400,
                        color: AppColors.inkSoft,
                      ),
                    ),
                  ],
                ),
              ),
              if (vocab.partOfSpeech != null)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.chip,
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: Text(
                    vocab.partOfSpeech!,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.inkFaint,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          for (var i = 0; i < vocab.meanings.length; i++) ...[
            if (i > 0) const SizedBox(height: 18),
            _MeaningBlock(
              index: i,
              showNumber: vocab.meanings.length > 1,
              meaning: vocab.meanings[i],
            ),
          ],
        ],
      ),
    );
  }
}

class _MeaningBlock extends StatelessWidget {
  const _MeaningBlock({
    required this.index,
    required this.showNumber,
    required this.meaning,
  });

  final int index;
  final bool showNumber;
  final VocabMeaning meaning;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          showNumber ? '${index + 1}. ${meaning.meaningVi}' : meaning.meaningVi,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 15,
            color: AppColors.ink,
          ),
        ),
        if (meaning.exampleJp != null) ...[
          const SizedBox(height: 8),
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
                  meaning.exampleJp!,
                  style: AppFonts.zenMaruGothic(
                    fontSize: 15,
                    fontWeight: FontWeight.w400,
                    color: AppColors.ink,
                  ),
                ),
                if (meaning.exampleVi != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    meaning.exampleVi!,
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
      ],
    );
  }
}
