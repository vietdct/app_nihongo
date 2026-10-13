import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../../domain/entities/lesson.dart';
import '../../domain/services/practice_strategy.dart' show containsKanji;
import '../../shared/level_badge.dart';
import '../lesson/providers/content_providers.dart';
import '../lesson/providers/level_providers.dart';
import 'providers/listening_dialogue_providers.dart';
import 'providers/quiz_providers.dart';

final _lessonNoPrefix = RegExp(r'^(第\s*\d+\s*課)');

/// Nhãn ngắn "第8課" của bài; bài không có tiền tố thì dùng thứ tự.
String _lessonBadge(Lesson l) =>
    _lessonNoPrefix.firstMatch(l.title)?.group(1)?.replaceAll(' ', '') ??
    '第${l.orderIndex}課';

/// Màn chọn loại quiz — thay cho quiz gộp chung Từ vựng+Kanji+Ngữ pháp cũ.
/// Mỗi mục chỉ sinh câu hỏi từ đúng 1 mảng nội dung (xem
/// `levelCategoryQuizQuestionsProvider`); Nghe hiểu dùng lại màn `/listening`
/// đã tách riêng từ trước.
///
/// Khóa IT: đổi thành "Luyện tập" có ngữ cảnh — hiện bài đang học, cho chọn
/// phạm vi (Bài hiện tại / Toàn bộ IT) và số câu (5/10/20), chỉ dùng state
/// cục bộ. Các cấp N5–N1 giữ nguyên hành vi cũ.
class QuizCategoryScreen extends ConsumerWidget {
  const QuizCategoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isIt = ref.watch(selectedLevelCodeProvider) == 'IT';
    if (!isIt) return _buildPlain(context);

    final currentLesson = ref.watch(quizCurrentLessonProvider).valueOrNull;
    final learned = ref.watch(quizLearnedLessonsProvider).valueOrNull ?? [];
    var scope = ref.watch(quizScopeProvider);
    if (currentLesson == null) scope = QuizScope.all;
    final count = ref.watch(quizQuestionCountProvider);
    final lessonIdList = switch (scope) {
      QuizScope.current => [currentLesson!.id],
      QuizScope.learned => [for (final l in learned) l.id],
      QuizScope.all => <String>[],
    };
    final lessonId = lessonIdList.isEmpty ? null : lessonIdList.join(',');

    final qs = <String, String>{
      if (lessonId != null) 'lesson': lessonId,
      'count': '$count',
    };
    String path(String base) => Uri(path: base, queryParameters: qs).toString();

    int? countOf(LessonItemType type) {
      if (lessonId != null) {
        var total = 0;
        for (final id in lessonIdList) {
          final items = ref.watch(lessonItemsProvider(id)).valueOrNull;
          if (items == null) return null;
          total += items.where((i) => i.type == type).length;
        }
        return total;
      }
      return switch (type) {
        LessonItemType.vocabulary =>
          ref.watch(vocabularyListProvider).valueOrNull?.length,
        LessonItemType.kanji => ref.watch(kanjiListProvider).valueOrNull?.length,
        LessonItemType.grammar =>
          ref.watch(grammarListProvider).valueOrNull?.length,
      };
    }

    String? sub(int? n, String unit) => n == null ? null : '$n $unit';

    // Kanji IT hỏi cách đọc của cả TỪ có Kanji (không có bộ Kanji riêng), nên
    // đếm từ vựng có Kanji trong phạm vi đang chọn.
    int? kanjiWordN;
    if (lessonId != null) {
      kanjiWordN = 0;
      for (final id in lessonIdList) {
        final items = ref.watch(lessonItemsProvider(id)).valueOrNull;
        if (items == null) {
          kanjiWordN = null;
          break;
        }
        kanjiWordN = kanjiWordN! +
            items
                .where((i) =>
                    i.type == LessonItemType.vocabulary &&
                    containsKanji(i.vocabulary!.word))
                .length;
      }
    } else {
      kanjiWordN = ref
          .watch(vocabularyListProvider)
          .valueOrNull
          ?.where((v) => containsKanji(v.word))
          .length;
    }
    int? listeningN;
    if (lessonId != null) {
      listeningN = 0;
      for (final id in lessonIdList) {
        final d = ref.watch(listeningDialoguesForLessonProvider(id)).valueOrNull;
        if (d == null) {
          listeningN = null;
          break;
        }
        listeningN = listeningN! + d.length;
      }
    }

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        title: const Text('Luyện tập'),
        actions: const [LevelBadge(), SizedBox(width: 12)],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            currentLesson == null
                ? 'Tiếng Nhật IT'
                : 'Tiếng Nhật IT · ${_lessonBadge(currentLesson)}',
            style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.inkSoft),
          ),
          const SizedBox(height: 2),
          const Text('Chọn nội dung bạn muốn luyện',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.ink)),
          const SizedBox(height: 14),
          _ChipRow(
            label: 'Phạm vi',
            children: [
              if (currentLesson != null) ...[
                _OptionChip(
                  text: 'Bài hiện tại',
                  selected: scope == QuizScope.current,
                  onTap: () => ref.read(quizScopeProvider.notifier).state =
                      QuizScope.current,
                ),
                if (learned.length > 1)
                  _OptionChip(
                    text: 'Các bài đã học',
                    selected: scope == QuizScope.learned,
                    onTap: () => ref.read(quizScopeProvider.notifier).state =
                        QuizScope.learned,
                  ),
              ],
              _OptionChip(
                text: 'Toàn bộ IT',
                selected: scope == QuizScope.all,
                onTap: () => ref.read(quizScopeProvider.notifier).state =
                    QuizScope.all,
              ),
            ],
          ),
          const SizedBox(height: 10),
          _ChipRow(
            label: 'Số câu',
            children: [
              for (final n in const [5, 10, 20])
                _OptionChip(
                  text: '$n',
                  selected: count == n,
                  onTap: () =>
                      ref.read(quizQuestionCountProvider.notifier).state = n,
                ),
            ],
          ),
          const SizedBox(height: 16),
          _QuizCategoryCard(
            glyph: '語',
            label: 'Từ vựng',
            subtitle: sub(countOf(LessonItemType.vocabulary), 'từ'),
            color: AppColors.moss,
            bg: AppColors.mossSoft,
            onTap: () => context
                .push(path('/quiz/${QuizCategory.vocabulary.routeSegment}')),
          ),
          const SizedBox(height: 12),
          _QuizCategoryCard(
            glyph: '文',
            label: 'Ngữ pháp',
            subtitle: sub(countOf(LessonItemType.grammar), 'mẫu câu'),
            color: AppColors.plum,
            bg: AppColors.plumSoft,
            onTap: () => context
                .push(path('/quiz/${QuizCategory.grammar.routeSegment}')),
          ),
          const SizedBox(height: 12),
          _QuizCategoryCard(
            glyph: '字',
            label: 'Kanji',
            subtitle: sub(kanjiWordN, 'từ có Kanji'),
            color: AppColors.indigo,
            bg: AppColors.indigoSoft,
            onTap: () => context
                .push(path('/quiz/${QuizCategory.kanji.routeSegment}')),
          ),
          const SizedBox(height: 12),
          _QuizCategoryCard(
            glyph: '聴',
            label: 'Nghe hiểu',
            subtitle: sub(listeningN, 'hội thoại'),
            color: AppColors.accent,
            bg: AppColors.accentSoft,
            onTap: () => context.push(path('/listening')),
          ),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () => context.push('/review/today'),
              icon: const Icon(Icons.replay_rounded, size: 18),
              label: const Text('Ôn tập hôm nay (SRS)'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlain(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(title: const Text('Chọn loại quiz')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _QuizCategoryCard(
            glyph: '語',
            label: 'Từ vựng',
            color: AppColors.moss,
            bg: AppColors.mossSoft,
            onTap: () =>
                context.push('/quiz/${QuizCategory.vocabulary.routeSegment}'),
          ),
          const SizedBox(height: 12),
          _QuizCategoryCard(
            glyph: '文',
            label: 'Ngữ pháp',
            color: AppColors.plum,
            bg: AppColors.plumSoft,
            onTap: () =>
                context.push('/quiz/${QuizCategory.grammar.routeSegment}'),
          ),
          const SizedBox(height: 12),
          _QuizCategoryCard(
            glyph: '字',
            label: 'Kanji',
            color: AppColors.indigo,
            bg: AppColors.indigoSoft,
            onTap: () =>
                context.push('/quiz/${QuizCategory.kanji.routeSegment}'),
          ),
          const SizedBox(height: 12),
          _QuizCategoryCard(
            glyph: '聴',
            label: 'Nghe hiểu',
            color: AppColors.accent,
            bg: AppColors.accentSoft,
            onTap: () => context.push('/listening'),
          ),
        ],
      ),
    );
  }
}

class _ChipRow extends StatelessWidget {
  const _ChipRow({required this.label, required this.children});

  final String label;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 64,
          child: Text(label,
              style: const TextStyle(fontSize: 13, color: AppColors.inkSoft)),
        ),
        Expanded(
          child: Wrap(spacing: 8, runSpacing: 8, children: children),
        ),
      ],
    );
  }
}

class _OptionChip extends StatelessWidget {
  const _OptionChip(
      {required this.text, required this.selected, required this.onTap});

  final String text;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(text),
      selected: selected,
      onSelected: (_) => onTap(),
      selectedColor: AppColors.indigoSoft,
      labelStyle: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: selected ? AppColors.indigo : AppColors.inkSoft,
      ),
      side: BorderSide(
          color: selected ? AppColors.indigo : AppColors.border, width: 0.8),
      showCheckmark: false,
    );
  }
}

class _QuizCategoryCard extends StatelessWidget {
  const _QuizCategoryCard({
    required this.glyph,
    required this.label,
    this.subtitle,
    required this.color,
    required this.bg,
    required this.onTap,
  });

  final String glyph;
  final String label;
  final String? subtitle;
  final Color color;
  final Color bg;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.border, width: 0.6),
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
              alignment: Alignment.center,
              child: Text(glyph,
                  style: AppFonts.zenMaruGothic(fontSize: 22, color: color),),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.ink,),),
                  if (subtitle != null)
                    Text(subtitle!,
                        style: const TextStyle(
                            fontSize: 12.5, color: AppColors.inkSoft),),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded,
                color: AppColors.inkFaint,),
          ],
        ),
      ),
    );
  }
}
