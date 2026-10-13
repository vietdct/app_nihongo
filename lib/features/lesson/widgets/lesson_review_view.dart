import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/supabase_providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../domain/entities/lesson.dart';
import '../../../domain/services/lesson_progress_log.dart';
import '../../../domain/services/srs_scheduler.dart';
import '../../grammar/providers/grammar_progress_providers.dart';
import '../../home/providers/mission_providers.dart';
import '../../kanji/providers/kanji_progress_providers.dart';
import '../../vocabulary/providers/vocab_progress_providers.dart';

/// Pha Review — chặng cuối thật của phiên học. Ôn lại đúng những từ vựng/
/// kanji/ngữ pháp vừa học bằng cơ chế SRS thật (SM-2 rút gọn), cùng cách tự
/// chấm mức nhớ (Quên/Nhớ mờ/Nhớ rõ) như `KanjiReviewScreen`/
/// `GrammarReviewScreen` — chỉ khác hàng đợi khoanh vùng đúng bài học này
/// thay vì toàn bộ due-queue cấp độ. Ghi lại qua ĐÚNG các controller đã có
/// (không tự tính SRS riêng) nên các màn Ôn tập Kanji/Ngữ pháp/Từ vựng
/// chuyên biệt sẽ thấy đúng lịch ôn tiếp theo do bước này tạo ra.
class LessonReviewView extends ConsumerStatefulWidget {
  const LessonReviewView({
    super.key,
    required this.items,
    required this.lessonId,
    required this.lessonTitle,
  });

  final List<LessonContentItem> items;
  final String lessonId;
  final String lessonTitle;

  @override
  ConsumerState<LessonReviewView> createState() => _LessonReviewViewState();
}

class _LessonReviewViewState extends ConsumerState<LessonReviewView> {
  late final List<LessonContentItem> _queue = List.of(widget.items);
  bool _revealed = false;
  int _reviewedCount = 0;
  int _forgotCount = 0;

  String _idOf(LessonContentItem item) => switch (item.type) {
        LessonItemType.vocabulary => item.vocabulary!.id,
        LessonItemType.kanji => item.kanji!.id,
        LessonItemType.grammar => item.grammar!.id,
      };

  Future<void> _grade(LessonContentItem item, SrsGrade grade) async {
    switch (item.type) {
      case LessonItemType.vocabulary:
        final controller = ref.read(vocabProgressControllerProvider);
        if (controller != null) {
          final current = ref.read(vocabProgressProvider).valueOrNull?[item.vocabulary!.id];
          await controller.recordReview(item.vocabulary!.id, current, grade);
          if (mounted) ref.invalidate(vocabProgressProvider);
        }
      case LessonItemType.kanji:
        final controller = ref.read(kanjiProgressControllerProvider);
        if (controller != null) {
          final current = ref.read(kanjiProgressProvider).valueOrNull?[item.kanji!.id];
          await controller.recordReview(item.kanji!.id, current, grade);
          if (mounted) ref.invalidate(kanjiProgressProvider);
        }
      case LessonItemType.grammar:
        final controller = ref.read(grammarProgressControllerProvider);
        if (controller != null) {
          final current = ref.read(grammarProgressProvider).valueOrNull?[item.grammar!.id];
          await controller.recordReview(item.grammar!.id, current, grade);
          if (mounted) ref.invalidate(grammarProgressProvider);
        }
    }
    if (mounted) ref.invalidate(dailyMissionStatusProvider);
    if (!mounted) return;
    setState(() {
      final queue = _queue..removeAt(0);
      // Chấm "Quên" thì đẩy lại cuối hàng đợi TRONG phiên này — chỉ để hiển
      // thị lại trước khi kết thúc buổi ôn, không ghi thêm 1 interval nữa
      // (interval thật đã được tính đúng 1 lần ở recordReview phía trên).
      if (grade == SrsGrade.forgot) {
        queue.add(item);
        _forgotCount++;
      }
      _reviewedCount++;
      _revealed = false;
    });
  }

  /// Đánh dấu bài đã hoàn thành trong `user_lesson_progress` — để thẻ
  /// "Continue Learning" ở Home bỏ qua bài này và chuyển sang bài kế tiếp.
  Future<void> _markCompleted() async {
    final sb = ref.read(supabaseProvider);
    final userId = ref.read(currentUserProvider)?.id;
    if (userId == null) return;
    await markLessonCompleted(sb, userId, widget.lessonId);
  }

  /// "Đang ôn: Từ vựng 12 · Kanji 3 · Ngữ pháp 4" — đếm theo loại từ toàn bộ
  /// mục của bài (không đổi khi hàng đợi giảm dần).
  String _scopeLabel() {
    int n(LessonItemType t) => widget.items.where((i) => i.type == t).length;
    final parts = [
      if (n(LessonItemType.vocabulary) > 0) 'Từ vựng ${n(LessonItemType.vocabulary)}',
      if (n(LessonItemType.kanji) > 0) 'Kanji ${n(LessonItemType.kanji)}',
      if (n(LessonItemType.grammar) > 0) 'Ngữ pháp ${n(LessonItemType.grammar)}',
    ];
    return 'Đang ôn: ${parts.join(' · ')}';
  }

  @override
  Widget build(BuildContext context) {
    if (_queue.isEmpty) {
      return _ReviewSummary(
        reviewedCount: _reviewedCount,
        forgotCount: _forgotCount,
        lessonId: widget.lessonId,
        lessonTitle: widget.lessonTitle,
        onComplete: _markCompleted,
      );
    }

    final item = _queue.first;

    return Column(
      children: [
        Text(
          'Còn ${_queue.length} mục · Đã ôn $_reviewedCount',
          style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.inkSoft),
        ),
        const SizedBox(height: 4),
        Text(
          _scopeLabel(),
          style: const TextStyle(fontSize: 12, color: AppColors.inkFaint),
        ),
        const SizedBox(height: 20),
        Expanded(
          child: Center(
            child: _ReviewCard(
              key: ValueKey('${item.type}-${_idOf(item)}'),
              item: item,
              revealed: _revealed,
              onReveal: () => setState(() => _revealed = true),
            ),
          ),
        ),
        if (_revealed) ...[
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: FilledButton(
                  onPressed: () => _grade(item, SrsGrade.forgot),
                  style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
                  child: const Text('Quên'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton(
                  onPressed: () => _grade(item, SrsGrade.hard),
                  style: FilledButton.styleFrom(backgroundColor: AppColors.accent),
                  child: const Text('Nhớ mờ'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton(
                  onPressed: () => _grade(item, SrsGrade.good),
                  style: FilledButton.styleFrom(backgroundColor: AppColors.moss),
                  child: const Text('Nhớ rõ'),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

class _ReviewCard extends StatelessWidget {
  const _ReviewCard({super.key, required this.item, required this.revealed, required this.onReveal});

  final LessonContentItem item;
  final bool revealed;
  final VoidCallback onReveal;

  @override
  Widget build(BuildContext context) {
    final (badge, color, front, back) = switch (item.type) {
      LessonItemType.vocabulary => (
          'Từ vựng',
          AppColors.moss,
          item.vocabulary!.word,
          '${item.vocabulary!.reading}\n${item.vocabulary!.primaryMeaning}',
        ),
      LessonItemType.kanji => (
          'Kanji',
          AppColors.indigo,
          item.kanji!.character,
          [
            if (item.kanji!.hanViet.isNotEmpty) item.kanji!.hanViet.join(' · ').toUpperCase(),
            item.kanji!.meaningVi.join(', '),
            if (item.kanji!.onyomi.isNotEmpty) 'On: ${item.kanji!.onyomi.join('、')}',
            if (item.kanji!.kunyomi.isNotEmpty) 'Kun: ${item.kanji!.kunyomi.join('、')}',
          ].join('\n'),
        ),
      LessonItemType.grammar => (
          'Ngữ pháp',
          AppColors.plum,
          item.grammar!.title,
          item.grammar!.explanation,
        ),
    };

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(badge, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: color)),
          const SizedBox(height: 12),
          Text(
            front,
            textAlign: TextAlign.center,
            style: AppFonts.zenMaruGothic(fontSize: 34, fontWeight: FontWeight.w800, color: AppColors.ink),
          ),
          const SizedBox(height: 20),
          if (!revealed)
            FilledButton(
              onPressed: onReveal,
              style: FilledButton.styleFrom(backgroundColor: color),
              child: const Text('Hiện đáp án'),
            )
          else
            Text(
              back,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14.5, color: AppColors.ink, height: 1.4),
            ),
        ],
      ),
    );
  }
}

class _ReviewSummary extends StatelessWidget {
  const _ReviewSummary({
    required this.reviewedCount,
    required this.forgotCount,
    required this.lessonId,
    required this.lessonTitle,
    required this.onComplete,
  });

  final int reviewedCount;
  final int forgotCount;
  final String lessonId;
  final String lessonTitle;
  final Future<void> Function() onComplete;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.check_circle_rounded, color: AppColors.moss, size: 56),
                const SizedBox(height: 16),
                const Text(
                  'Hoàn thành bài học!',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: AppColors.ink),
                ),
                const SizedBox(height: 8),
                Text(
                  'Đã ôn $reviewedCount mục · Quên $forgotCount lần',
                  style: const TextStyle(color: AppColors.inkSoft),
                ),
              ],
            ),
          ),
        ),
        SizedBox(
          width: double.infinity,
          child: TextButton(
            onPressed: () => context.push('/lessons/$lessonId/quiz', extra: lessonTitle),
            child: const Text('Làm bài kiểm tra nhanh'),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: () async {
              await onComplete();
              if (context.mounted) Navigator.of(context).maybePop();
            },
            child: const Text('Hoàn thành bài học'),
          ),
        ),
      ],
    );
  }
}
