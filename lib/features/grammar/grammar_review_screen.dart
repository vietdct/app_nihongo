import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../../domain/entities/grammar_point.dart';
import '../../domain/entities/grammar_progress.dart';
import '../../domain/services/srs_scheduler.dart';
import '../../shared/card_dot_progress.dart';
import '../../shared/card_known_stats.dart';
import '../../shared/card_stamp_label.dart';
import '../../shared/flip_card.dart';
import '../../shared/gradient_card_shell.dart';
import '../lesson/providers/content_providers.dart';
import '../review/providers/review_mistakes_providers.dart';
import 'providers/grammar_progress_providers.dart';

/// Hàng đợi ôn tập SRS thật (SM-2 rút gọn, xem `srs_scheduler.dart`) — khác
/// `GrammarFlashcardScreen` (bộ thẻ vuốt known/unknown tĩnh): ở đây chỉ hiện
/// đúng những mẫu đang due (`GrammarProgress.isDueNow`). Thẻ lật kiểu
/// flashcard (chạm để xem đáp án) + vuốt để chấm — chỉ 2 mức Nhớ/Quên (bỏ
/// mức "Nhớ mờ" trung gian) cho cảm giác chơi-thẻ nhanh, gọn giống hệt
/// Flashcard Từ vựng/Ngữ pháp thường đã có, thay vì 3 nút chấm tĩnh.
/// "Nhớ" ánh xạ sang [SrsGrade.good], "Quên" sang [SrsGrade.forgot].
class GrammarReviewScreen extends ConsumerStatefulWidget {
  const GrammarReviewScreen({super.key});

  @override
  ConsumerState<GrammarReviewScreen> createState() =>
      _GrammarReviewScreenState();
}

class _GrammarReviewScreenState extends ConsumerState<GrammarReviewScreen> {
  List<GrammarPoint>? _queue;
  int _reviewedCount = 0;
  int _forgotCount = 0;
  // Vị trí (theo số thứ tự đã ôn) mà lượt chấm đó là "Quên" — dùng tô đỏ
  // đúng chấm trong CardDotProgress, giống cách vocab đánh dấu wrongIndices.
  final Set<int> _wrongIndices = {};

  Future<void> _grade(
    GrammarPoint grammar,
    GrammarProgress? current,
    SrsGrade grade,
  ) async {
    final controller = ref.read(grammarProgressControllerProvider);
    if (controller != null) {
      await controller.recordReview(grammar.id, current, grade);
      if (mounted) ref.invalidate(grammarProgressProvider);
    }
    if (grade == SrsGrade.forgot) {
      await ref.read(reviewMistakesControllerProvider)?.recordMistake(
            sourceType: 'grammar',
            sourceId: grammar.id,
            correctAnswer: grammar.explanation,
            explanation: grammar.commonMistake,
          );
    }
    if (!mounted) return;
    setState(() {
      final queue = _queue!..removeAt(0);
      // Chấm "Quên" thì đẩy lại cuối hàng đợi TRONG phiên này — chỉ để hiển
      // thị lại trước khi kết thúc buổi ôn, không ghi thêm 1 interval nữa
      // (interval thật đã được tính đúng 1 lần ở recordReview phía trên).
      if (grade == SrsGrade.forgot) {
        queue.add(grammar);
        _forgotCount++;
        _wrongIndices.add(_reviewedCount);
      }
      _reviewedCount++;
    });
  }

  @override
  Widget build(BuildContext context) {
    final grammarAsync = ref.watch(grammarListProvider);
    final progressAsync = ref.watch(grammarProgressProvider);

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(title: const Text('Ôn tập ngữ pháp')),
      body: grammarAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Lỗi: $e')),
        data: (all) {
          final progress = progressAsync.valueOrNull;
          if (progress == null) {
            return progressAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Lỗi: $e')),
              data: (_) => const SizedBox.shrink(),
            );
          }

          // Giới hạn tối đa 10 mẫu/lượt (random trong tập due) — hàng đợi
          // không giới hạn trước đây khiến người mới dễ nản khi có quá nhiều
          // mẫu due cùng lúc (yêu cầu người dùng 2026-08-07).
          _queue ??= ([
            for (final g in all)
              if (progress[g.id]?.isDueNow ?? true) g,
          ]..shuffle())
              .take(10)
              .toList();
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
                  'Không có mẫu ngữ pháp nào cần ôn hôm nay!\nQuay lại sau hoặc học mẫu mới nhé.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.inkSoft),
                ),
              ),
            );
          }

          final grammar = queue.first;
          final current = progress[grammar.id];
          // Tổng số chấm = số đã ôn + số còn lại trong hàng đợi (kể cả thẻ
          // vừa bị đẩy lại cuối do "Quên") — nên khi requeue, progress tự
          // nới thêm 1 chấm thay vì báo sai đã xong.
          final total = _reviewedCount + queue.length;

          return Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            child: Column(
              children: [
                CardDotProgress(
                  total: total,
                  index: _reviewedCount,
                  wrongIndices: _wrongIndices,
                ),
                const SizedBox(height: 26),
                Expanded(
                  child: Center(
                    child: _SwipeableReviewCard(
                      key: ValueKey(grammar.id),
                      grammar: grammar,
                      onSwipeRight: () =>
                          _grade(grammar, current, SrsGrade.good),
                      onSwipeLeft: () =>
                          _grade(grammar, current, SrsGrade.forgot),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  '${_reviewedCount + 1} / $total',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppColors.inkSoft,
                  ),
                ),
                const SizedBox(height: 8),
                CardKnownStats(
                  known: _reviewedCount - _forgotCount,
                  unknown: _forgotCount,
                  knownLabel: 'Nhớ',
                  unknownLabel: 'Quên',
                ),
                const SizedBox(height: 10),
                const Text(
                  'Chạm để xem đáp án · Vuốt phải: Nhớ · Vuốt trái: Quên',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: AppColors.inkFaint),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _SwipeableReviewCard extends StatefulWidget {
  const _SwipeableReviewCard({
    super.key,
    required this.grammar,
    required this.onSwipeRight,
    required this.onSwipeLeft,
  });

  final GrammarPoint grammar;
  final VoidCallback onSwipeRight;
  final VoidCallback onSwipeLeft;

  @override
  State<_SwipeableReviewCard> createState() => _SwipeableReviewCardState();
}

class _SwipeableReviewCardState extends State<_SwipeableReviewCard>
    with SingleTickerProviderStateMixin {
  static const _threshold = 110.0;

  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 260),
  );
  Animation<Offset>? _animation;
  Offset _drag = Offset.zero;
  bool _completing = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      if (_animation != null) setState(() => _drag = _animation!.value);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onPanUpdate(DragUpdateDetails d) => setState(() => _drag += d.delta);

  void _onPanEnd(DragEndDetails d) {
    final vx = d.velocity.pixelsPerSecond.dx;
    final swipeRight = _drag.dx > _threshold || vx > 600;
    final swipeLeft = _drag.dx < -_threshold || vx < -600;

    if (swipeRight || swipeLeft) {
      _completing = true;
      final target = Offset(swipeRight ? 900 : -900, _drag.dy);
      _animation = Tween<Offset>(begin: _drag, end: target)
          .animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
      _controller.forward(from: 0).whenComplete(() {
        if (!mounted) return;
        if (swipeRight) {
          widget.onSwipeRight();
        } else {
          widget.onSwipeLeft();
        }
      });
    } else {
      _animation = Tween<Offset>(begin: _drag, end: Offset.zero)
          .animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
      _controller.forward(from: 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final rightProgress = (_drag.dx / _threshold).clamp(0.0, 1.0);
    final leftProgress = (-_drag.dx / _threshold).clamp(0.0, 1.0);
    final angle = (_drag.dx / 2800).clamp(-0.25, 0.25);

    return GestureDetector(
      onPanUpdate: _completing ? null : _onPanUpdate,
      onPanEnd: _completing ? null : _onPanEnd,
      child: Transform.translate(
        offset: _drag,
        child: Transform.rotate(
          angle: angle,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.topCenter,
            children: [
              FlipCard(
                front: _CardFront(grammar: widget.grammar),
                back: _CardBack(grammar: widget.grammar),
              ),
              if (rightProgress > 0.08)
                Positioned(
                  top: 24,
                  left: 24,
                  child: Opacity(
                    opacity: rightProgress,
                    child: const CardStampLabel(
                      text: 'NHỚ',
                      color: AppColors.moss,
                      angle: -0.21,
                    ),
                  ),
                ),
              if (leftProgress > 0.08)
                Positioned(
                  top: 24,
                  right: 20,
                  child: Opacity(
                    opacity: leftProgress,
                    child: const CardStampLabel(
                      text: 'QUÊN',
                      color: AppColors.danger,
                      angle: 0.21,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CardFront extends StatelessWidget {
  const _CardFront({required this.grammar});

  final GrammarPoint grammar;

  @override
  Widget build(BuildContext context) {
    return GradientCardShell(
      gradientColors: const [
        Color(0xFFFF9C5A),
        Color(0xFFFF7A45),
        Color(0xFFD85A93),
      ],
      shadowColor: AppColors.accent.withValues(alpha: 0.25),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.chip,
              borderRadius: BorderRadius.circular(100),
            ),
            child: const Text(
              'NGỮ PHÁP',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.inkFaint,
              ),
            ),
          ),
          const SizedBox(height: 28),
          Text(
            grammar.title,
            textAlign: TextAlign.center,
            style: AppFonts.zenMaruGothic(
              fontSize: 34,
              fontWeight: FontWeight.w800,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 28),
          const Icon(
            Icons.touch_app_outlined,
            color: AppColors.inkFaint,
            size: 20,
          ),
        ],
      ),
    );
  }
}

class _CardBack extends StatelessWidget {
  const _CardBack({required this.grammar});

  final GrammarPoint grammar;

  @override
  Widget build(BuildContext context) {
    return GradientCardShell(
      gradientColors: const [
        Color(0xFF3FB35B),
        Color(0xFF2D9A47),
        Color(0xFF1E8038),
      ],
      shadowColor: AppColors.moss.withValues(alpha: 0.25),
      innerBackground: const Color(0xFFEEFBF0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            grammar.explanation,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w800,
              color: AppColors.ink,
            ),
          ),
          if (grammar.exampleJp != null) ...[
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    grammar.exampleJp!,
                    style: AppFonts.zenMaruGothic(
                      fontSize: 14.5,
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
        ],
      ),
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
            const Icon(
              Icons.check_circle_rounded,
              color: AppColors.moss,
              size: 56,
            ),
            const SizedBox(height: 16),
            const Text(
              'Hoàn thành ôn tập hôm nay!',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
            ),
            const SizedBox(height: 8),
            Text(
              'Đã ôn $reviewedCount mẫu · Quên $forgotCount lần',
              style: const TextStyle(color: AppColors.inkSoft),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () => context.go('/'),
              style: FilledButton.styleFrom(backgroundColor: AppColors.plum),
              child: const Text('Về trang chủ'),
            ),
          ],
        ),
      ),
    );
  }
}
