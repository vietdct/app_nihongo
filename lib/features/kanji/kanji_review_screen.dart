import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../../domain/entities/kanji.dart';
import '../../domain/entities/kanji_progress.dart';
import '../../domain/services/srs_scheduler.dart';
import '../home/providers/mission_providers.dart';
import '../lesson/providers/content_providers.dart';
import 'providers/kanji_progress_providers.dart';

/// Hàng đợi ôn tập SRS thật (SM-2 rút gọn, xem `srs_scheduler.dart`) — khác
/// `KanjiDetailScreen` (bộ thẻ vuốt known/unknown tĩnh): ở đây chỉ hiện
/// đúng những chữ đang due (`KanjiProgress.isDueNow`), và người học tự chấm
/// mức nhớ (Quên/Nhớ mờ/Nhớ rõ) để tính lại lịch ôn tiếp theo.
class KanjiReviewScreen extends ConsumerStatefulWidget {
  const KanjiReviewScreen({super.key});

  @override
  ConsumerState<KanjiReviewScreen> createState() => _KanjiReviewScreenState();
}

class _KanjiReviewScreenState extends ConsumerState<KanjiReviewScreen> {
  List<Kanji>? _queue;
  bool _revealed = false;
  int _reviewedCount = 0;
  int _forgotCount = 0;

  Future<void> _grade(Kanji kanji, KanjiProgress? current, SrsGrade grade) async {
    final controller = ref.read(kanjiProgressControllerProvider);
    if (controller != null) {
      await controller.recordReview(kanji.id, current, grade);
      if (mounted) {
        ref.invalidate(kanjiProgressProvider);
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
        queue.add(kanji);
        _forgotCount++;
      }
      _reviewedCount++;
      _revealed = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final kanjiAsync = ref.watch(kanjiListProvider);
    final progressAsync = ref.watch(kanjiProgressProvider);

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(title: const Text('Ôn tập Kanji')),
      body: kanjiAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Lỗi: $e')),
        data: (all) {
          final progress =
              progressAsync.valueOrNull ?? const <String, KanjiProgress>{};

          _queue ??= [
            for (final k in all)
              if (progress[k.id]?.isDueNow ?? true) k,
          ];
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
                  'Không có chữ nào cần ôn hôm nay!\nQuay lại sau hoặc học chữ mới nhé.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.inkSoft),
                ),
              ),
            );
          }

          final kanji = queue.first;
          final current = progress[kanji.id];

          return Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            child: Column(
              children: [
                Text(
                  'Còn ${queue.length} chữ · Đã ôn $_reviewedCount',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppColors.inkSoft,
                  ),
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: Center(
                    child: _ReviewCard(
                      key: ValueKey(kanji.id),
                      kanji: kanji,
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
                          onTap: () => _grade(kanji, current, SrsGrade.forgot),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _GradeButton(
                          label: 'Nhớ mờ',
                          color: AppColors.accent,
                          onTap: () => _grade(kanji, current, SrsGrade.hard),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _GradeButton(
                          label: 'Nhớ rõ',
                          color: AppColors.moss,
                          onTap: () => _grade(kanji, current, SrsGrade.good),
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
    required this.kanji,
    required this.revealed,
    required this.onReveal,
  });

  final Kanji kanji;
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
          Text(
            kanji.character,
            style: AppFonts.zenMaruGothic(
              fontSize: 72,
              fontWeight: FontWeight.w800,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 20),
          if (!revealed)
            FilledButton(
              onPressed: onReveal,
              style: FilledButton.styleFrom(backgroundColor: AppColors.indigo),
              child: const Text('Hiện đáp án'),
            )
          else ...[
            if (kanji.hanViet.isNotEmpty)
              Text(
                kanji.hanViet.join(' · ').toUpperCase(),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: AppColors.indigo,
                  letterSpacing: 1,
                ),
              ),
            const SizedBox(height: 6),
            Text(
              kanji.meaningVi.join(', '),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14.5, color: AppColors.ink),
            ),
            if (kanji.onyomi.isNotEmpty || kanji.kunyomi.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                [
                  if (kanji.onyomi.isNotEmpty) 'On: ${kanji.onyomi.join('、')}',
                  if (kanji.kunyomi.isNotEmpty) 'Kun: ${kanji.kunyomi.join('、')}',
                ].join('   '),
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
            const Icon(Icons.check_circle_rounded,
                color: AppColors.moss, size: 56,),
            const SizedBox(height: 16),
            const Text(
              'Hoàn thành ôn tập hôm nay!',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
            ),
            const SizedBox(height: 8),
            Text(
              'Đã ôn $reviewedCount chữ · Quên $forgotCount lần',
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
