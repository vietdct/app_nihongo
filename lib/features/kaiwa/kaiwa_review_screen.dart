import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../../domain/entities/kaiwa_message.dart';
import '../../domain/services/srs_scheduler.dart';
import 'providers/kaiwa_review_providers.dart';

/// Hàng đợi ôn tập SRS thật (SM-2 rút gọn, xem `srs_scheduler.dart`) cho các
/// câu người học đã nói và bị AI sửa trong Kaiwa — khác `KaiwaHistoryScreen`
/// (xem lại nguyên buổi hội thoại): ở đây chỉ hiện đúng những câu đang due
/// ([KaiwaMessage.isDueNow]), gộp từ MỌI buổi hội thoại đã có.
class KaiwaReviewScreen extends ConsumerStatefulWidget {
  const KaiwaReviewScreen({super.key});

  @override
  ConsumerState<KaiwaReviewScreen> createState() => _KaiwaReviewScreenState();
}

class _KaiwaReviewScreenState extends ConsumerState<KaiwaReviewScreen> {
  List<KaiwaMessage>? _queue;
  bool _revealed = false;
  int _reviewedCount = 0;
  int _forgotCount = 0;

  Future<void> _grade(KaiwaMessage message, SrsGrade grade) async {
    final controller = ref.read(kaiwaReviewControllerProvider);
    if (controller != null) {
      await controller.recordReview(message.id, message, grade);
      if (mounted) ref.invalidate(kaiwaReviewQueueProvider);
    }
    if (!mounted) return;
    setState(() {
      final queue = _queue!..removeAt(0);
      // Chấm "Quên" thì đẩy lại cuối hàng đợi TRONG phiên này — chỉ để hiển
      // thị lại trước khi kết thúc buổi ôn, không ghi thêm 1 interval nữa
      // (interval thật đã được tính đúng 1 lần ở recordReview phía trên).
      if (grade == SrsGrade.forgot) {
        queue.add(message);
        _forgotCount++;
      }
      _reviewedCount++;
      _revealed = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final queueAsync = ref.watch(kaiwaReviewQueueProvider);

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(title: const Text('Ôn tập câu đã sửa')),
      body: queueAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Lỗi: $e')),
        data: (loaded) {
          _queue ??= [...loaded];
          final queue = _queue!;

          if (queue.isEmpty) {
            if (_reviewedCount > 0) {
              return _SummaryPanel(
                reviewedCount: _reviewedCount,
                forgotCount: _forgotCount,
              );
            }
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Không có câu nào cần ôn hôm nay!\nTrò chuyện thêm với AI Kaiwa để tích lũy câu cần sửa nhé.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.inkSoft),
                ),
              ),
            );
          }

          final message = queue.first;
          final feedback = message.feedback!;

          return Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            child: Column(
              children: [
                Text(
                  'Còn ${queue.length} câu · Đã ôn $_reviewedCount',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppColors.inkSoft,
                  ),
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: Center(
                    child: SingleChildScrollView(
                      child: _ReviewCard(
                        key: ValueKey(message.id),
                        message: message,
                        feedback: feedback,
                        revealed: _revealed,
                        onReveal: () => setState(() => _revealed = true),
                      ),
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
                          onTap: () => _grade(message, SrsGrade.forgot),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _GradeButton(
                          label: 'Nhớ mờ',
                          color: AppColors.accent,
                          onTap: () => _grade(message, SrsGrade.hard),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _GradeButton(
                          label: 'Nhớ rõ',
                          color: AppColors.moss,
                          onTap: () => _grade(message, SrsGrade.good),
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

class _ReviewCard extends StatelessWidget {
  const _ReviewCard({
    super.key,
    required this.message,
    required this.feedback,
    required this.revealed,
    required this.onReveal,
  });

  final KaiwaMessage message;
  final KaiwaFeedback feedback;
  final bool revealed;
  final VoidCallback onReveal;

  @override
  Widget build(BuildContext context) {
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
          const Text(
            'Bạn đã nói',
            style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: AppColors.inkFaint),
          ),
          const SizedBox(height: 8),
          Text(
            message.contentJp,
            textAlign: TextAlign.center,
            style: AppFonts.zenMaruGothic(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.ink),
          ),
          const SizedBox(height: 20),
          if (!revealed)
            FilledButton(
              onPressed: onReveal,
              style: FilledButton.styleFrom(backgroundColor: AppColors.teal),
              child: const Text('Nhớ lại cách nói đúng'),
            )
          else ...[
            const Divider(height: 32),
            const Text(
              'Cách nói tự nhiên hơn',
              style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: AppColors.inkFaint),
            ),
            const SizedBox(height: 8),
            Text(
              feedback.betterPhrasing,
              textAlign: TextAlign.center,
              style: AppFonts.zenMaruGothic(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.teal),
            ),
            if (feedback.explanation.trim().isNotEmpty) ...[
              const SizedBox(height: 14),
              Text(
                feedback.explanation,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 13.5, color: AppColors.ink),
              ),
            ],
            if (feedback.commonMistake.trim().isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                'Lỗi thường gặp: ${feedback.commonMistake}',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12.5, color: AppColors.inkSoft),
              ),
            ],
          ],
        ],
      ),
    );
  }
}

class _GradeButton extends StatelessWidget {
  const _GradeButton({
    required this.label,
    required this.color,
    required this.onTap,
  });

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
              'Đã ôn $reviewedCount câu · Quên $forgotCount lần',
              style: const TextStyle(color: AppColors.inkSoft),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () => context.go('/'),
              style: FilledButton.styleFrom(backgroundColor: AppColors.teal),
              child: const Text('Về trang chủ'),
            ),
          ],
        ),
      ),
    );
  }
}
