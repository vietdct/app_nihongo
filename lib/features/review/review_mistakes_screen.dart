import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../domain/entities/review_mistake.dart';
import '../lesson/providers/content_providers.dart';
import 'providers/review_mistakes_providers.dart';

enum _MistakeFilter { all, vocab, kanji, grammar, bookmarked }

/// Mistake Notebook — liệt kê lỗi thật đã ghi nhận từ 3 màn Review
/// (`review_mistakes_providers.dart`). Không có "quiz từ lỗi" hay AI comment
/// ở bản này — đó thuộc AI Review Coach, chưa triển khai (`docs/TASK.md`).
class ReviewMistakesScreen extends ConsumerStatefulWidget {
  const ReviewMistakesScreen({super.key});

  @override
  ConsumerState<ReviewMistakesScreen> createState() =>
      _ReviewMistakesScreenState();
}

class _ReviewMistakesScreenState extends ConsumerState<ReviewMistakesScreen> {
  _MistakeFilter _filter = _MistakeFilter.all;

  @override
  Widget build(BuildContext context) {
    final mistakesAsync = ref.watch(reviewMistakesProvider);

    // vocab/kanji/grammar list dùng để tra tên hiển thị theo source_id —
    // cùng nguồn đã dùng ở Weak Points, không nhân bản dữ liệu.
    final vocabList = ref.watch(vocabularyListProvider).valueOrNull ?? const [];
    final kanjiList = ref.watch(kanjiListProvider).valueOrNull ?? const [];
    final grammarList = ref.watch(grammarListProvider).valueOrNull ?? const [];

    String titleFor(ReviewMistake m) => switch (m.sourceType) {
          'vocab' => vocabList
                  .where((v) => v.id == m.sourceId)
                  .map((v) => v.word)
                  .firstOrNull ??
              m.sourceId,
          'kanji' => kanjiList
                  .where((k) => k.id == m.sourceId)
                  .map((k) => k.character)
                  .firstOrNull ??
              m.sourceId,
          'grammar' => grammarList
                  .where((g) => g.id == m.sourceId)
                  .map((g) => g.title)
                  .firstOrNull ??
              m.sourceId,
          _ => m.sourceId,
        };

    Color colorFor(String sourceType) => switch (sourceType) {
          'vocab' => AppColors.moss,
          'kanji' => AppColors.indigo,
          'grammar' => AppColors.plum,
          _ => AppColors.inkFaint,
        };

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(title: const Text('Sổ tay lỗi')),
      body: mistakesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Lỗi: $e')),
        data: (all) {
          final filtered = all.where((m) {
            return switch (_filter) {
              _MistakeFilter.all => true,
              _MistakeFilter.vocab => m.sourceType == 'vocab',
              _MistakeFilter.kanji => m.sourceType == 'kanji',
              _MistakeFilter.grammar => m.sourceType == 'grammar',
              _MistakeFilter.bookmarked => m.bookmarked,
            };
          }).toList();

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      for (final f in _MistakeFilter.values) ...[
                        _FilterChip(
                          label: switch (f) {
                            _MistakeFilter.all => 'Tất cả',
                            _MistakeFilter.vocab => 'Từ vựng',
                            _MistakeFilter.kanji => 'Kanji',
                            _MistakeFilter.grammar => 'Ngữ pháp',
                            _MistakeFilter.bookmarked => 'Đã đánh dấu',
                          },
                          selected: _filter == f,
                          onTap: () => setState(() => _filter = f),
                        ),
                        const SizedBox(width: 8),
                      ],
                    ],
                  ),
                ),
              ),
              Expanded(
                child: filtered.isEmpty
                    ? const _EmptyMistakesState()
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                        itemCount: filtered.length,
                        itemBuilder: (context, i) {
                          final m = filtered[i];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _MistakeCard(
                              mistake: m,
                              title: titleFor(m),
                              color: colorFor(m.sourceType),
                              onToggleBookmark: () async {
                                await ref
                                    .read(reviewMistakesControllerProvider)
                                    ?.setBookmarked(m.id, !m.bookmarked);
                                ref.invalidate(reviewMistakesProvider);
                              },
                              onSaveNote: (note) async {
                                await ref
                                    .read(reviewMistakesControllerProvider)
                                    ?.setNote(m.id, note);
                                ref.invalidate(reviewMistakesProvider);
                              },
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

extension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(100),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.accent : AppColors.chip,
          borderRadius: BorderRadius.circular(100),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
            color: selected ? Colors.white : AppColors.inkSoft,
          ),
        ),
      ),
    );
  }
}

class _EmptyMistakesState extends StatelessWidget {
  const _EmptyMistakesState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.auto_awesome_outlined,
              size: 48,
              color: AppColors.accent,
            ),
            SizedBox(height: 12),
            Text(
              'Chưa có lỗi nào được ghi nhận',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 16,
                color: AppColors.ink,
              ),
            ),
            SizedBox(height: 6),
            Text(
              'Khi bạn chấm "Quên" ở màn Review, lỗi sẽ được lưu lại đây.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: AppColors.inkSoft),
            ),
          ],
        ),
      ),
    );
  }
}

class _MistakeCard extends StatelessWidget {
  const _MistakeCard({
    required this.mistake,
    required this.title,
    required this.color,
    required this.onToggleBookmark,
    required this.onSaveNote,
  });

  final ReviewMistake mistake;
  final String title;
  final Color color;
  final VoidCallback onToggleBookmark;
  final void Function(String note) onSaveNote;

  Future<void> _editNote(BuildContext context) async {
    final controller = TextEditingController(text: mistake.note ?? '');
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ghi chú cá nhân'),
        content: TextField(
          controller: controller,
          maxLines: 3,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Vì sao bạn hay sai...'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Huỷ'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Lưu'),
          ),
        ],
      ),
    );
    if (result != null) onSaveNote(result);
  }

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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                    color: AppColors.ink,
                  ),
                ),
              ),
              Text(
                'Sai ${mistake.occurrenceCount} lần',
                style: const TextStyle(fontSize: 11, color: AppColors.inkSoft),
              ),
              const SizedBox(width: 6),
              InkWell(
                onTap: onToggleBookmark,
                child: Icon(
                  mistake.bookmarked ? Icons.bookmark : Icons.bookmark_border,
                  size: 20,
                  color: mistake.bookmarked
                      ? AppColors.accent
                      : AppColors.inkFaint,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            mistake.correctAnswer,
            style: const TextStyle(fontSize: 13.5, color: AppColors.ink),
          ),
          if (mistake.explanation != null &&
              mistake.explanation!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              mistake.explanation!,
              style: const TextStyle(fontSize: 12.5, color: AppColors.inkSoft),
            ),
          ],
          const SizedBox(height: 8),
          InkWell(
            onTap: () => _editNote(context),
            child: Text(
              (mistake.note == null || mistake.note!.isEmpty)
                  ? '+ Thêm ghi chú'
                  : 'Ghi chú: ${mistake.note}',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.indigo,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
