import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../../data/repositories/content_repository_provider.dart';
import '../../domain/entities/jlpt_level.dart';
import '../../domain/entities/kanji.dart';
import '../../domain/entities/lesson.dart';
import '../../domain/entities/vocab_meaning.dart';
import '../../domain/entities/vocab_progress.dart';
import '../../domain/entities/vocabulary.dart';
import '../../shared/debounced_search_field.dart';
import '../../shared/jp_speak_button.dart';
import '../../shared/kanji_text_utils.dart';
import '../../shared/lesson_filter_dropdown.dart';
import '../../shared/level_badge.dart';
import '../../shared/vocab_category_filter_dropdown.dart';
import '../../shared/vocab_status_filter_dropdown.dart';
import '../../shared/motion/playing_indicator.dart';
import '../../shared/motion/stagger.dart';
import '../../shared/skeleton_layouts.dart';
import '../lesson/providers/content_providers.dart';
import '../lesson/providers/level_providers.dart';
import 'providers/vocab_progress_providers.dart';
import 'vocabulary_lookup_screen.dart';
import 'providers/vocab_review_providers.dart' show weakEaseThreshold;

final _vocabSearchQueryProvider = StateProvider<String>((ref) => '');
final _showStarredOnlyProvider = StateProvider<bool>((ref) => false);
final _selectedLessonFilterProvider = StateProvider<String?>((ref) => null);
final _selectedCategoryFilterProvider = StateProvider<String?>((ref) => null);
final _selectedStatusFilterProvider =
    StateProvider<VocabStatusFilter?>((ref) => null);

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
    final assignments =
        ref.watch(vocabularyLessonAssignmentsProvider).valueOrNull ??
            const <String, LessonAssignment>{};
    final vocabLessonIds = assignments.values.map((a) => a.lessonId).toSet();
    final lessons = (ref.watch(lessonsProvider).valueOrNull ?? const [])
        .where((l) => vocabLessonIds.contains(l.id))
        .toList();
    final rawSelectedLesson = ref.watch(_selectedLessonFilterProvider);
    final selectedLesson = rawSelectedLesson == null ||
            rawSelectedLesson == unassignedLessonFilter ||
            lessons.any((l) => l.id == rawSelectedLesson)
        ? rawSelectedLesson
        : null;
    final selectedCategory = ref.watch(_selectedCategoryFilterProvider);
    final selectedStatus = ref.watch(_selectedStatusFilterProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Từ vựng'),
        actions: [
          IconButton(
            tooltip: 'Làm mới nội dung',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => _refreshVocabularyContent(context, ref),
          ),
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
                    child: Row(
                      children: [
                        Expanded(
                          child: LessonFilterDropdown(
                            lessons: lessons,
                            selected: selectedLesson,
                            hasUnassigned:
                                all.any((v) => !assignments.containsKey(v.id)),
                            onSelected: (id) => ref
                                .read(_selectedLessonFilterProvider.notifier)
                                .state = id,
                            accentColor: AppColors.moss,
                            fillWidth: true,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: VocabCategoryFilterDropdown(
                            categories: {
                              for (final v in all)
                                if (v.category != null) v.category!,
                            }.toList()
                              ..sort(),
                            selected: selectedCategory,
                            hasUncategorized:
                                all.any((v) => v.category == null),
                            onSelected: (category) => ref
                                .read(
                                  _selectedCategoryFilterProvider.notifier,
                                )
                                .state = category,
                            accentColor: AppColors.indigo,
                            fillWidth: true,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: VocabStatusFilterDropdown(
                            selected: selectedStatus,
                            onSelected: (status) => ref
                                .read(_selectedStatusFilterProvider.notifier)
                                .state = status,
                            accentColor: AppColors.plum,
                            fillWidth: true,
                          ),
                        ),
                      ],
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
            // Stagger sống xuyên tìm kiếm/lọc/rỗng (không chạy lại khi gõ), bắt
            // đầu khi dữ liệu đầu tiên có; đổi cấp độ → group mới (key) → chạy
            // lại cho dataset mới. Chỉ 8 từ đầu được animate.
            child: StaggerGroup(
              key: ValueKey(selectedLevel),
              active: vocabAsync.hasValue,
              child: vocabAsync.when(
                loading: () => const ListCardSkeleton(trailingPill: true),
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
                  if (selectedCategory == uncategorizedFilter) {
                    filtered =
                        filtered.where((v) => v.category == null).toList();
                  } else if (selectedCategory != null) {
                    filtered = filtered
                        .where((v) => v.category == selectedCategory)
                        .toList();
                  }
                  switch (selectedStatus) {
                    case VocabStatusFilter.mastered:
                      filtered = filtered
                          .where((v) => progressMap[v.id]?.isKnown == true)
                          .toList();
                    case VocabStatusFilter.dueForReview:
                      filtered = filtered
                          .where((v) => progressMap[v.id]?.isDueNow ?? true)
                          .toList();
                    case VocabStatusFilter.hardest:
                      filtered = filtered
                          .where(
                            (v) =>
                                progressMap[v.id] != null &&
                                progressMap[v.id]!.reviewCount > 0 &&
                                progressMap[v.id]!.easeFactor <
                                    weakEaseThreshold,
                          )
                          .toList()
                        ..sort(
                          (a, b) => progressMap[a.id]!
                              .easeFactor
                              .compareTo(progressMap[b.id]!.easeFactor),
                        );
                    case VocabStatusFilter.mostForgotten:
                      filtered = filtered
                          .where(
                              (v) => (progressMap[v.id]?.lapseCount ?? 0) > 0)
                          .toList()
                        ..sort(
                          (a, b) => (progressMap[b.id]?.lapseCount ?? 0)
                              .compareTo(progressMap[a.id]?.lapseCount ?? 0),
                        );
                    case null:
                      break;
                  }
                  if (query.isNotEmpty) {
                    filtered = filtered
                        .where(
                          (v) =>
                              v.word.toLowerCase().contains(query) ||
                              v.reading.toLowerCase().contains(query) ||
                              v.meanings.any(
                                (m) =>
                                    m.meaningVi.toLowerCase().contains(query),
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
                      itemBuilder: (context, i) => StaggerItem(
                        index: i,
                        child: _VocabTile(
                          vocab: filtered[i],
                          starred: progressMap[filtered[i].id]?.starred == true,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
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

/// Mở màn tra cứu chi tiết 1 từ vựng (`VocabularyLookupScreen`) — dùng chung
/// giữa danh sách phẳng (`VocabularyListScreen`) và các mini-card trên
/// `VocabularyHomeScreen`. Giữ tên/chữ ký cũ để các nơi gọi không phải đổi;
/// `VocabDetailSheet` bên dưới là bản bottom sheet cũ, hiện không còn được mở.
void showVocabDetailSheet(BuildContext context, Vocabulary vocab) {
  Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => VocabularyLookupScreen(vocab: vocab),
    ),
  );
}

/// Bottom sheet "mini từ điển": header thay đổi theo từ có/không có Kanji,
/// các section (Từ liên quan/Kanji trong từ/Ví dụ/Trạng thái học) chỉ hiện khi
/// có dữ liệu thật — không tạo placeholder rỗng. Kanji breakdown + âm Hán Việt
/// tra qua `ContentRepository.findKanjiByCharacter` (mọi cấp độ đã cache, xem
/// `content_repository_impl.dart`), Từ liên quan là các từ khác chứa cùng
/// Kanji (app chưa có dữ liệu synonym/antonym nên không hiển thị 2 loại đó).
class VocabDetailSheet extends ConsumerStatefulWidget {
  const VocabDetailSheet({
    super.key,
    required this.vocab,
    required this.onOpenRelated,
  });

  final Vocabulary vocab;
  final ValueChanged<Vocabulary> onOpenRelated;

  @override
  ConsumerState<VocabDetailSheet> createState() => _VocabDetailSheetState();
}

class _VocabDetailSheetState extends ConsumerState<VocabDetailSheet> {
  List<Kanji> _kanjiBreakdown = const [];
  List<Vocabulary> _relatedWords = const [];
  bool? _starredOverride;

  @override
  void initState() {
    super.initState();
    unawaited(_loadExtras());
  }

  Future<void> _loadExtras() async {
    final repo = ref.read(contentRepositoryProvider);
    final chars = uniqueKanjiChars(widget.vocab.word);
    final kanjiResults = <Kanji>[];
    for (final c in chars) {
      final k = await repo.findKanjiByCharacter(c);
      if (k != null) kanjiResults.add(k);
    }
    final related = await repo.findRelatedVocabulary(
      widget.vocab.word,
      excludeId: widget.vocab.id,
    );
    if (!mounted) return;
    setState(() {
      _kanjiBreakdown = kanjiResults;
      _relatedWords = related;
    });
  }

  Future<void> _toggleStar(bool current) async {
    final controller = ref.read(vocabProgressControllerProvider);
    if (controller == null) return;
    setState(() => _starredOverride = !current);
    await controller.setStarred(widget.vocab.id, !current);
    if (mounted) ref.invalidate(vocabProgressProvider);
  }

  /// Ghép âm Hán Việt từng chữ theo đúng thứ tự trong từ (VD: 旅行 → LỮ HÀNH).
  /// Chữ nào chưa tra được Hán Việt sẽ bị bỏ qua thay vì hiện placeholder giả.
  String? get _hanViet {
    final parts = [
      for (final k in _kanjiBreakdown)
        if (k.hanViet.isNotEmpty) k.hanViet.first,
    ];
    return parts.isEmpty ? null : parts.join(' ').toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final vocab = widget.vocab;
    final levels = ref.watch(jlptLevelsProvider).valueOrNull;
    final levelCode = _levelCodeFor(levels, vocab.levelId);
    final progress = ref.watch(vocabProgressProvider).valueOrNull?[vocab.id];
    final starred = _starredOverride ?? (progress?.starred == true);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _VocabHeader(
          vocab: vocab,
          hanViet: _hanViet,
          levelCode: levelCode,
          starred: starred,
          onToggleStar: () => _toggleStar(starred),
          onClose: () => Navigator.maybePop(context),
        ),
        const SizedBox(height: 24),
        _MeaningSection(meanings: vocab.meanings),
        if (vocab.partOfSpeech != null) ...[
          const SizedBox(height: 12),
          _WordTypeSection(partOfSpeech: vocab.partOfSpeech!),
        ],
        if (vocab.commonUsagePattern != null) ...[
          const SizedBox(height: 12),
          _CommonUsageSection(
            pattern: vocab.commonUsagePattern!,
            desc: vocab.commonUsageDesc,
            examples: vocab.commonUsageExamples,
          ),
        ],
        if (vocab.meanings.any((m) => m.allExamples.isNotEmpty)) ...[
          const SizedBox(height: 12),
          _ExampleSentencesSection(word: vocab.word, meanings: vocab.meanings),
        ],
        if (vocab.nuancePoints.isNotEmpty) ...[
          const SizedBox(height: 12),
          _NuanceSection(word: vocab.word, points: vocab.nuancePoints),
        ],
        if (vocab.similarWords.isNotEmpty) ...[
          const SizedBox(height: 12),
          _SimilarWordsSection(words: vocab.similarWords),
        ],
        if (vocab.comparisons.isNotEmpty) ...[
          const SizedBox(height: 12),
          _ComparisonSection(word: vocab.word, comparisons: vocab.comparisons),
        ],
        if (vocab.commonMistakeNote != null ||
            vocab.commonMistakeSuggestions.isNotEmpty) ...[
          const SizedBox(height: 12),
          _CommonMistakesSection(
            note: vocab.commonMistakeNote,
            suggestions: vocab.commonMistakeSuggestions,
          ),
        ],
        if (_relatedWords.isNotEmpty) ...[
          const SizedBox(height: 12),
          _RelatedWordsSection(
            words: _relatedWords,
            onTap: widget.onOpenRelated,
          ),
        ],
        if (_kanjiBreakdown.isNotEmpty) ...[
          const SizedBox(height: 12),
          _KanjiBreakdownSection(kanjiList: _kanjiBreakdown),
        ],
        if (progress != null &&
            (progress.reviewCount > 0 || progress.isKnown != null)) ...[
          const SizedBox(height: 12),
          _LearningStatusSection(progress: progress),
        ],
      ],
    );
  }
}

String _levelCodeFor(List<JlptLevel>? levels, String levelId) {
  if (levels == null) return '';
  for (final l in levels) {
    if (l.id == levelId) return l.code;
  }
  return '';
}

class _VocabHeader extends StatelessWidget {
  const _VocabHeader({
    required this.vocab,
    required this.hanViet,
    required this.levelCode,
    required this.starred,
    required this.onToggleStar,
    required this.onClose,
  });

  final Vocabulary vocab;
  final String? hanViet;
  final String levelCode;
  final bool starred;
  final VoidCallback onToggleStar;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    // Ẩn dòng cách đọc khi nó trùng lặp với chữ (từ thuần kana) — không phải
    // khi từ "không có Kanji": từ số đếm như 9つ vẫn cần hiện cách đọc ここのつ.
    final showReading = vocab.reading.isNotEmpty && vocab.reading != vocab.word;
    final metadata = [
      if (vocab.partOfSpeech != null) vocab.partOfSpeech!,
      if (vocab.category != null) vocab.category!,
    ].join(' · ');

    return Column(
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
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppFonts.zenMaruGothic(
                      fontSize: 40,
                      fontWeight: FontWeight.w900,
                      color: AppColors.ink,
                    ).copyWith(height: 1.1),
                  ),
                  if (showReading) ...[
                    const SizedBox(height: 6),
                    Text(
                      vocab.reading,
                      style: AppFonts.zenMaruGothic(
                        fontSize: 17,
                        fontWeight: FontWeight.w500,
                        color: AppColors.inkSoft,
                      ),
                    ),
                  ],
                  if (hanViet != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      hanViet!,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.1,
                        color: AppColors.indigo,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 12),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 120),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.danger,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: IconButton(
                      onPressed: onClose,
                      tooltip: 'Đóng',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints.tightFor(
                        width: 44,
                        height: 44,
                      ),
                      icon: const Icon(
                        Icons.close_rounded,
                        color: Colors.white,
                        size: 21,
                      ),
                    ),
                  ),
                  if (metadata.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      metadata,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        height: 1.35,
                        color: AppColors.inkSoft,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Container(
              height: 44,
              padding: const EdgeInsets.only(left: 4, right: 16),
              decoration: BoxDecoration(
                color: AppColors.ink,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  JpSpeakButton(
                    text: vocab.word,
                    color: Colors.white,
                    size: 18,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints.tightFor(
                      width: 40,
                      height: 44,
                    ),
                  ),
                  const Text(
                    'Nghe',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.accentSoft,
                borderRadius: BorderRadius.circular(12),
              ),
              child: IconButton(
                onPressed: onToggleStar,
                tooltip: starred ? 'Bỏ lưu' : 'Lưu từ này',
                padding: EdgeInsets.zero,
                constraints:
                    const BoxConstraints.tightFor(width: 44, height: 44),
                icon: SwapIcon(
                  icon:
                      starred ? Icons.star_rounded : Icons.star_border_rounded,
                  color: AppColors.accent,
                  size: 21,
                ),
              ),
            ),
            const Spacer(),
            if (levelCode.isNotEmpty)
              Container(
                height: 44,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.indigo,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  levelCode,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _MeaningSection extends StatelessWidget {
  const _MeaningSection({required this.meanings});

  final List<VocabMeaning> meanings;

  @override
  Widget build(BuildContext context) {
    return _DetailSectionCard(
      title: 'Nghĩa',
      accent: AppColors.accent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < meanings.length; i++)
            Padding(
              padding: EdgeInsets.only(top: i == 0 ? 0 : 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 22,
                    child: Text(
                      '${i + 1}.',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.inkFaint,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      meanings[i].meaningVi,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        height: 1.35,
                        color: AppColors.ink,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _WordTypeSection extends StatelessWidget {
  const _WordTypeSection({required this.partOfSpeech});

  final String partOfSpeech;

  @override
  Widget build(BuildContext context) {
    return _DetailSectionCard(
      title: 'Loại từ',
      accent: AppColors.indigo,
      child: Text(
        partOfSpeech,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: AppColors.ink,
        ),
      ),
    );
  }
}

/// Tách đoạn text thành các đoạn thường/đậm dựa trên cặp `**...**` — dùng cho
/// nội dung biên soạn thủ công (sắc thái, lỗi thường gặp) để nhấn mạnh 1 cụm
/// từ trong câu mà không cần cấu trúc dữ liệu riêng.
List<InlineSpan> _parseBold(String text, TextStyle base, TextStyle bold) {
  final parts = text.split('**');
  return [
    for (var i = 0; i < parts.length; i++)
      if (parts[i].isNotEmpty)
        TextSpan(text: parts[i], style: i.isOdd ? bold : base),
  ];
}

class _CommonUsageSection extends StatelessWidget {
  const _CommonUsageSection({
    required this.pattern,
    required this.desc,
    required this.examples,
  });

  final String pattern;
  final String? desc;
  final List<VocabUsageExample> examples;

  @override
  Widget build(BuildContext context) {
    const base = TextStyle(fontSize: 13.5, color: AppColors.ink, height: 1.6);
    const boldMoss = TextStyle(
      fontWeight: FontWeight.w700,
      color: AppColors.moss,
    );
    return _DetailSectionCard(
      title: 'Cách dùng thường gặp',
      accent: AppColors.moss,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text.rich(
            TextSpan(
              children: [
                TextSpan(text: pattern, style: boldMoss),
                if (desc != null) TextSpan(text: ' — $desc', style: base),
              ],
            ),
            style: base,
          ),
          if (examples.isNotEmpty) ...[
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final ex in examples)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.mossSoft,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          ex.phrase,
                          style: AppFonts.zenMaruGothic(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.ink,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          ex.meaningVi,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.moss,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _NuanceSection extends StatelessWidget {
  const _NuanceSection({required this.word, required this.points});

  final String word;
  final List<String> points;

  @override
  Widget build(BuildContext context) {
    const base = TextStyle(fontSize: 13.5, color: AppColors.ink);
    const bold = TextStyle(
      fontSize: 13.5,
      fontWeight: FontWeight.w700,
      color: AppColors.ink,
    );
    return _DetailSectionCard(
      title: 'Sắc thái',
      accent: AppColors.plum,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$word thường mang sắc thái:',
            style: base.copyWith(height: 1.7),
          ),
          const SizedBox(height: 10),
          for (var i = 0; i < points.length; i++)
            Padding(
              padding: EdgeInsets.only(top: i == 0 ? 0 : 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 7, right: 8),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: AppColors.plum,
                        shape: BoxShape.circle,
                      ),
                      child: SizedBox(width: 4, height: 4),
                    ),
                  ),
                  Expanded(
                    child: Text.rich(
                      TextSpan(children: _parseBold(points[i], base, bold)),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _SimilarWordsSection extends StatelessWidget {
  const _SimilarWordsSection({required this.words});

  final List<VocabSimilarWord> words;

  @override
  Widget build(BuildContext context) {
    return _DetailSectionCard(
      title: 'Từ liên quan',
      accent: AppColors.teal,
      child: Column(
        children: [
          for (var i = 0; i < words.length; i++) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.tealSoft,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          words[i].word,
                          style: AppFonts.zenMaruGothic(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.ink,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          words[i].meaningVi,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.inkSoft,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (i < words.length - 1) const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }
}

class _ComparisonSection extends StatelessWidget {
  const _ComparisonSection({required this.word, required this.comparisons});

  final String word;
  final List<VocabComparison> comparisons;

  @override
  Widget build(BuildContext context) {
    return _DetailSectionCard(
      title: 'So sánh',
      accent: AppColors.indigo,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < comparisons.length; i++) ...[
            if (i > 0) const SizedBox(height: 14),
            Text(
              '$word vs ${comparisons[i].word}',
              style: AppFonts.zenMaruGothic(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _ComparisonCard(
                    word: word,
                    desc: comparisons[i].mainWordDesc,
                    color: AppColors.accent,
                    background: AppColors.accentSoft,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _ComparisonCard(
                    word: comparisons[i].word,
                    desc: comparisons[i].otherWordDesc,
                    color: AppColors.indigo,
                    background: AppColors.indigoSoft,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _ComparisonCard extends StatelessWidget {
  const _ComparisonCard({
    required this.word,
    required this.desc,
    required this.color,
    required this.background,
  });

  final String word;
  final String desc;
  final Color color;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            word,
            style: AppFonts.zenMaruGothic(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            desc,
            style: const TextStyle(
              fontSize: 12.5,
              height: 1.5,
              color: AppColors.ink,
            ),
          ),
        ],
      ),
    );
  }
}

class _CommonMistakesSection extends StatelessWidget {
  const _CommonMistakesSection({required this.note, required this.suggestions});

  final String? note;
  final List<String> suggestions;

  @override
  Widget build(BuildContext context) {
    const base = TextStyle(fontSize: 13.5, color: AppColors.ink, height: 1.65);
    const bold = TextStyle(
      fontSize: 13.5,
      fontWeight: FontWeight.w700,
      color: AppColors.ink,
      height: 1.65,
    );
    return _DetailSectionCard(
      title: 'Lỗi thường gặp',
      accent: AppColors.danger,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.dangerSoft,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (note != null)
              Text.rich(TextSpan(children: _parseBold(note!, base, bold))),
            if (suggestions.isNotEmpty) ...[
              if (note != null) const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final s in suggestions)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        s,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.danger,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _DetailSectionCard extends StatelessWidget {
  const _DetailSectionCard({
    required this.title,
    required this.accent,
    required this.child,
  });

  final String title;
  final Color accent;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 6,
                height: 6,
                decoration:
                    BoxDecoration(color: accent, shape: BoxShape.circle),
              ),
              const SizedBox(width: 8),
              Text(
                title.toUpperCase(),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                  color: accent,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _RelatedWordsSection extends StatelessWidget {
  const _RelatedWordsSection({required this.words, required this.onTap});

  final List<Vocabulary> words;
  final ValueChanged<Vocabulary> onTap;

  @override
  Widget build(BuildContext context) {
    return _DetailSectionCard(
      title: 'Từ chung Kanji',
      accent: AppColors.teal,
      child: Column(
        children: [
          for (var index = 0; index < words.length; index++) ...[
            _RelatedWordCard(
              word: words[index],
              onTap: () => onTap(words[index]),
            ),
            if (index < words.length - 1) const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }
}

class _RelatedWordCard extends StatelessWidget {
  const _RelatedWordCard({required this.word, required this.onTap});

  final Vocabulary word;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.tealSoft,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    word.word,
                    style: AppFonts.zenMaruGothic(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.ink,
                    ),
                  ),
                  if (word.reading != word.word) ...[
                    const SizedBox(height: 2),
                    Text(
                      word.reading,
                      style: AppFonts.zenMaruGothic(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AppColors.inkSoft,
                      ),
                    ),
                  ],
                  const SizedBox(height: 3),
                  Text(
                    word.primaryMeaning,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      height: 1.35,
                      color: AppColors.inkSoft,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              size: 20,
              color: AppColors.teal,
            ),
          ],
        ),
      ),
    );
  }
}

class _KanjiBreakdownSection extends StatelessWidget {
  const _KanjiBreakdownSection({required this.kanjiList});

  final List<Kanji> kanjiList;

  @override
  Widget build(BuildContext context) {
    return _DetailSectionCard(
      title: 'Kanji trong từ',
      accent: AppColors.indigo,
      child: Column(
        children: [
          for (var index = 0; index < kanjiList.length; index++) ...[
            _KanjiRow(kanji: kanjiList[index]),
            if (index < kanjiList.length - 1) const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }
}

class _KanjiRow extends StatelessWidget {
  const _KanjiRow({required this.kanji});

  final Kanji kanji;

  @override
  Widget build(BuildContext context) {
    final readings = [
      if (kanji.onyomi.isNotEmpty || kanji.kunyomi.isNotEmpty)
        [...kanji.onyomi, ...kanji.kunyomi].join(' / '),
      if (kanji.hanViet.isNotEmpty) kanji.hanViet.first.toUpperCase(),
    ].where((text) => text.isNotEmpty).join(' · ');

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 44,
          height: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.indigoSoft,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            kanji.character,
            style: AppFonts.zenMaruGothic(
              fontSize: 22,
              color: AppColors.indigo,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (readings.isNotEmpty)
                Text(
                  readings,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: AppColors.ink,
                  ),
                ),
              if (kanji.meaningVi.isNotEmpty)
                Text(
                  kanji.meaningVi.join(', '),
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: AppColors.inkSoft,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ExampleSentencesSection extends StatelessWidget {
  const _ExampleSentencesSection({required this.word, required this.meanings});

  final String word;
  final List<VocabMeaning> meanings;

  @override
  Widget build(BuildContext context) {
    final examples = [for (final m in meanings) ...m.allExamples];
    return _DetailSectionCard(
      title: 'Ví dụ',
      accent: AppColors.indigo,
      child: Column(
        children: [
          for (var index = 0; index < examples.length; index++) ...[
            _ExampleSentenceCard(
              word: word,
              exampleJp: examples[index].$1,
              exampleVi: examples[index].$2,
            ),
            if (index < examples.length - 1) const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }
}

class _ExampleSentenceCard extends StatelessWidget {
  const _ExampleSentenceCard({
    required this.word,
    required this.exampleJp,
    required this.exampleVi,
  });

  final String word;
  final String exampleJp;
  final String? exampleVi;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.canvas,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            margin: const EdgeInsets.only(top: 2),
            decoration: BoxDecoration(
              color: AppColors.indigoSoft,
              borderRadius: BorderRadius.circular(8),
            ),
            child: JpSpeakButton(
              text: exampleJp,
              color: AppColors.indigo,
              size: 15,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints.tightFor(width: 28, height: 28),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text.rich(
                  _highlightedExample(word, exampleJp),
                  style: AppFonts.zenMaruGothic(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: AppColors.ink,
                  ).copyWith(height: 1.6),
                ),
                if (exampleVi != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    exampleVi!,
                    style: const TextStyle(
                      fontSize: 12.5,
                      height: 1.4,
                      color: AppColors.inkSoft,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Tô nổi các lần xuất hiện của [word] trong câu ví dụ [text] bằng badge màu
/// cam (giống bản thiết kế) — không tô gì nếu từ không xuất hiện nguyên văn
/// trong câu (VD: câu chia động từ khác dạng từ điển).
InlineSpan _highlightedExample(String word, String text) {
  final baseStyle = AppFonts.zenMaruGothic(
    fontSize: 15,
    fontWeight: FontWeight.w500,
    color: AppColors.ink,
  );
  if (word.isEmpty || !text.contains(word)) {
    return TextSpan(text: text, style: baseStyle);
  }
  final spans = <InlineSpan>[];
  var start = 0;
  while (true) {
    final idx = text.indexOf(word, start);
    if (idx < 0) {
      spans.add(TextSpan(text: text.substring(start), style: baseStyle));
      break;
    }
    if (idx > start) {
      spans.add(TextSpan(text: text.substring(start, idx), style: baseStyle));
    }
    spans.add(
      WidgetSpan(
        alignment: PlaceholderAlignment.middle,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
          decoration: BoxDecoration(
            color: AppColors.accentSoft,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            word,
            style: AppFonts.zenMaruGothic(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.accent,
            ),
          ),
        ),
      ),
    );
    start = idx + word.length;
  }
  return TextSpan(children: spans);
}

class _LearningStatusSection extends StatelessWidget {
  const _LearningStatusSection({required this.progress});

  final VocabProgress progress;

  @override
  Widget build(BuildContext context) {
    final due = progress.dueAt;
    final status = progress.isKnown == true
        ? 'Đã thuộc'
        : progress.isKnown == false
            ? 'Đang học'
            : 'Chưa đánh giá';
    final nextReview = due == null
        ? 'Chưa đặt'
        : progress.isDueNow
            ? 'Hôm nay'
            : '${due.day}/${due.month}';

    return _DetailSectionCard(
      title: 'Trạng thái học',
      accent: AppColors.moss,
      child: Row(
        children: [
          Expanded(
            child: _LearningMetric(
              value: status,
              label: 'Trạng thái',
              color: AppColors.moss,
              background: AppColors.mossSoft,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _LearningMetric(
              value: '${progress.reviewCount}',
              label: 'Đã ôn',
              color: AppColors.indigo,
              background: AppColors.indigoSoft,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _LearningMetric(
              value: nextReview,
              label: 'Ôn tiếp',
              color: AppColors.inkSoft,
              background: AppColors.chip,
            ),
          ),
        ],
      ),
    );
  }
}

class _LearningMetric extends StatelessWidget {
  const _LearningMetric({
    required this.value,
    required this.label,
    required this.color,
    required this.background,
  });

  final String value;
  final String label;
  final Color color;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 72),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              height: 1.2,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
