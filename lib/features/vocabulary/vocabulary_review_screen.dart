import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../../domain/entities/vocab_progress.dart';
import '../../domain/services/srs_scheduler.dart';
import '../home/providers/mission_providers.dart';
import '../../shared/jp_speak_button.dart';
import 'providers/vocab_progress_providers.dart';
import 'providers/vocab_review_providers.dart';

/// Hàng đợi ôn tập SRS thật (SM-2 rút gọn, xem `srs_scheduler.dart`) — khác
/// `VocabularyFlashcardScreen` (bộ thẻ vuốt known/unknown tĩnh): ở đây chỉ
/// hiện đúng những từ đang due ([vocabReviewQueueProvider]), và người học tự
/// chấm mức nhớ (Quên/Nhớ mờ/Nhớ rõ) để tính lại lịch ôn tiếp theo. Mirror
/// `KanjiReviewScreen`/`GrammarReviewScreen`.
class VocabularyReviewScreen extends ConsumerStatefulWidget {
  const VocabularyReviewScreen({super.key});

  @override
  ConsumerState<VocabularyReviewScreen> createState() => _VocabularyReviewScreenState();
}

class _VocabularyReviewScreenState extends ConsumerState<VocabularyReviewScreen> {
  List<VocabReviewItem>? _queue;
  bool _revealed = false;
  int _reviewedCount = 0;
  int _forgotCount = 0;

  Future<void> _grade(VocabReviewItem item, VocabProgress? current, SrsGrade grade) async {
    final controller = ref.read(vocabProgressControllerProvider);
    if (controller != null) {
      await controller.recordReview(item.vocab.id, current, grade);
      if (mounted) {
        ref.invalidate(vocabProgressProvider);
        ref.invalidate(vocabReviewQueueProvider);
        ref.invalidate(dailyMissionStatusProvider);
      }
    }
    if (!mounted) return;
    setState(() {
      final queue = _queue!..removeAt(0);
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

  @override
  Widget build(BuildContext context) {
    final queueAsync = ref.watch(vocabReviewQueueProvider);
    final progressAsync = ref.watch(vocabProgressProvider);

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(title: const Text('Ôn tập Từ vựng')),
      body: queueAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Lỗi: $e')),
        data: (freshQueue) {
          final progress = progressAsync.valueOrNull ?? const <String, VocabProgress>{};

          _queue ??= [...freshQueue];
          final queue = _queue!;

          if (queue.isEmpty) {
            if (_reviewedCount > 0) {
              return _SummaryPanel(reviewedCount: _reviewedCount, forgotCount: _forgotCount);
            }
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Không có từ nào cần ôn hôm nay!\nQuay lại sau hoặc học từ mới nhé.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.inkSoft),
                ),
              ),
            );
          }

          final item = queue.first;
          final current = progress[item.vocab.id];

          return Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            child: Column(
              children: [
                Text(
                  'Còn ${queue.length} từ · Đã ôn $_reviewedCount',
                  style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.inkSoft),
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: Center(
                    child: _ReviewCard(
                      key: ValueKey(item.vocab.id),
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
                        child: _GradeButton(
                          label: 'Quên',
                          color: AppColors.danger,
                          onTap: () => _grade(item, current, SrsGrade.forgot),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _GradeButton(
                          label: 'Nhớ mờ',
                          color: AppColors.accent,
                          onTap: () => _grade(item, current, SrsGrade.hard),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _GradeButton(
                          label: 'Nhớ rõ',
                          color: AppColors.moss,
                          onTap: () => _grade(item, current, SrsGrade.good),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

String _reasonLabel(VocabReviewReason reason) => switch (reason) {
      VocabReviewReason.forgotten => 'Vừa quên',
      VocabReviewReason.overdue => 'Quá hạn',
      VocabReviewReason.weak => 'Từ khó',
      VocabReviewReason.due => 'Đến hạn',
    };

Color _reasonColor(VocabReviewReason reason) => switch (reason) {
      VocabReviewReason.forgotten => AppColors.danger,
      VocabReviewReason.overdue => AppColors.accent,
      VocabReviewReason.weak => AppColors.plum,
      VocabReviewReason.due => AppColors.indigo,
    };

class _ReviewCard extends StatelessWidget {
  const _ReviewCard({super.key, required this.item, required this.revealed, required this.onReveal});

  final VocabReviewItem item;
  final bool revealed;
  final VoidCallback onReveal;

  @override
  Widget build(BuildContext context) {
    final vocab = item.vocab;
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
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: _reasonColor(item.reason).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(100),
            ),
            child: Text(
              _reasonLabel(item.reason),
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w800,
                color: _reasonColor(item.reason),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                vocab.word,
                style: AppFonts.zenMaruGothic(
                  fontSize: 40,
                  fontWeight: FontWeight.w800,
                  color: AppColors.ink,
                ),
              ),
              JpSpeakButton(text: vocab.word),
            ],
          ),
          Text(
            vocab.reading,
            style: const TextStyle(fontSize: 16, color: AppColors.inkSoft),
          ),
          const SizedBox(height: 20),
          if (!revealed)
            FilledButton(
              onPressed: onReveal,
              style: FilledButton.styleFrom(backgroundColor: AppColors.indigo),
              child: const Text('Hiện đáp án'),
            )
          else
            Text(
              vocab.meanings.map((m) => m.meaningVi).join(' · '),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 15, color: AppColors.ink, fontWeight: FontWeight.w600),
            ),
        ],
      ),
    );
  }
}

class _GradeButton extends StatelessWidget {
  const _GradeButton({required this.label, required this.color, required this.onTap});

  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: onTap,
      style: FilledButton.styleFrom(backgroundColor: color),
      child: Text(label),
    );
  }
}

class _SummaryPanel extends StatelessWidget {
  const _SummaryPanel({required this.reviewedCount, required this.forgotCount});

  final int reviewedCount;
  final int forgotCount;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle_rounded, color: AppColors.moss, size: 56),
            const SizedBox(height: 16),
            const Text(
              'Hoàn thành ôn tập hôm nay!',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
            ),
            const SizedBox(height: 8),
            Text(
              'Đã ôn $reviewedCount từ · Quên $forgotCount lần',
              style: const TextStyle(color: AppColors.inkSoft),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () => context.go('/'),
              style: FilledButton.styleFrom(backgroundColor: AppColors.indigo),
              child: const Text('Về trang chủ'),
            ),
          ],
        ),
      ),
    );
  }
}
