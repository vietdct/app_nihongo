import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../../domain/entities/grammar_point.dart';
import '../../shared/motion/animated_progress_bar.dart';
import '../lesson/providers/content_providers.dart';
import 'providers/grammar_progress_providers.dart';
import 'widgets/grammar_content_sections.dart';
import '../../shared/jp_example_text.dart';

/// Bộ thẻ ngữ pháp vuốt qua — vuốt phải để đánh dấu đã thuộc, vuốt trái để
/// đánh dấu chưa thuộc (gom vào danh sách ôn lại cuối phiên). Mỗi thẻ là 1
/// trang đầy đủ giải thích/ví dụ/lỗi thường gặp; chạm ngôi sao để lưu lại.
class GrammarFlashcardScreen extends ConsumerStatefulWidget {
  const GrammarFlashcardScreen({super.key});

  @override
  ConsumerState<GrammarFlashcardScreen> createState() =>
      _GrammarFlashcardScreenState();
}

class _GrammarFlashcardScreenState
    extends ConsumerState<GrammarFlashcardScreen> {
  List<GrammarPoint>? _fullDeck;
  List<GrammarPoint>? _deck;
  int _index = 0;
  bool _reviewRound = false;
  final Set<String> _unknownIds = {};
  final Map<String, bool> _starredOverride = {};

  Future<void> _markKnown(
    GrammarPoint g,
    GrammarProgressController? controller,
  ) async {
    setState(() {
      _unknownIds.remove(g.id);
      _index++;
    });
    await controller?.setKnown(g.id, true);
    if (mounted) ref.invalidate(grammarProgressProvider);
  }

  Future<void> _markUnknown(
    GrammarPoint g,
    GrammarProgressController? controller,
  ) async {
    setState(() {
      _unknownIds.add(g.id);
      _index++;
    });
    await controller?.setKnown(g.id, false);
    if (mounted) ref.invalidate(grammarProgressProvider);
  }

  Future<void> _toggleStar(
    GrammarPoint g,
    bool current,
    GrammarProgressController? controller,
  ) async {
    final next = !current;
    setState(() => _starredOverride[g.id] = next);
    await controller?.setStarred(g.id, next);
    if (mounted) ref.invalidate(grammarProgressProvider);
  }

  void _showUnknownGrammar() {
    final items = _fullDeck!.where((g) => _unknownIds.contains(g.id)).toList();
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      backgroundColor: AppColors.card,
      isScrollControlled: true,
      builder: (sheetContext) => _UnknownGrammarSheet(
        items: items,
        onReviewNow: () {
          Navigator.pop(sheetContext);
          _startReview();
        },
      ),
    );
  }

  void _goBack() {
    if (_index > 0) setState(() => _index--);
  }

  void _startReview() {
    setState(() {
      _deck = _fullDeck!.where((g) => _unknownIds.contains(g.id)).toList();
      _unknownIds.clear();
      _index = 0;
      _reviewRound = true;
    });
  }

  void _restart() {
    setState(() {
      _deck = List.of(_fullDeck!);
      _unknownIds.clear();
      _index = 0;
      _reviewRound = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final grammarAsync = ref.watch(grammarListProvider);
    final progressAsync = ref.watch(grammarProgressProvider);
    final controller = ref.watch(grammarProgressControllerProvider);

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(title: const Text('Flashcard ngữ pháp')),
      body: grammarAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Lỗi: $e')),
        data: (all) {
          if (all.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Chưa có ngữ pháp nào cho cấp độ này.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.inkSoft),
                ),
              ),
            );
          }

          _fullDeck ??= all;
          _deck ??= List.of(all);
          final deck = _deck!;
          final progressMap = progressAsync.valueOrNull ?? const {};

          if (_index >= deck.length) {
            return _SummaryPanel(
              unknownCount: _unknownIds.length,
              reviewRound: _reviewRound,
              onReview: _startReview,
              onRestart: _restart,
            );
          }

          final grammar = deck[_index];
          final starred = _starredOverride[grammar.id] ??
              progressMap[grammar.id]?.starred ??
              false;
          final total = deck.length;

          return Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
            child: Column(
              children: [
                Row(
                  children: [
                    IconButton(
                      onPressed: _index == 0 ? null : _goBack,
                      icon: const Icon(Icons.undo_rounded),
                      color: AppColors.inkSoft,
                      tooltip: 'Thẻ trước',
                    ),
                    Expanded(
                      child: Text(
                        _reviewRound
                            ? 'Ôn ngữ pháp chưa thuộc · ${_index + 1}/$total'
                            : '${_index + 1} / $total',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: AppColors.inkSoft,
                        ),
                      ),
                    ),
                    if (_unknownIds.isNotEmpty)
                      InkWell(
                        borderRadius: BorderRadius.circular(100),
                        onTap: _showUnknownGrammar,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.accentSoft,
                            borderRadius: BorderRadius.circular(100),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '${_unknownIds.length} chưa thuộc',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.accentStrong,
                                ),
                              ),
                              const Icon(
                                Icons.chevron_right_rounded,
                                size: 14,
                                color: AppColors.accentStrong,
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      const SizedBox(width: 48),
                  ],
                ),
                const SizedBox(height: 4),
                AnimatedProgressBar(
                  value: (_index + 1) / total,
                  minHeight: 5,
                  backgroundColor: AppColors.chip,
                  color: AppColors.plum,
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: Center(
                    child: _SwipeableGrammarCard(
                      key: ValueKey(grammar.id),
                      grammar: grammar,
                      starred: starred,
                      onSwipeRight: () => _markKnown(grammar, controller),
                      onSwipeLeft: () => _markUnknown(grammar, controller),
                      onToggleStar: () =>
                          _toggleStar(grammar, starred, controller),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _unknownIds.isNotEmpty
                      ? 'Vuốt phải: đã thuộc · Vuốt trái: chưa thuộc · Chạm badge để xem/ôn ngay'
                      : 'Vuốt phải: đã thuộc · Vuốt trái: chưa thuộc',
                  textAlign: TextAlign.center,
                  style:
                      const TextStyle(fontSize: 12, color: AppColors.inkFaint),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _SummaryPanel extends StatelessWidget {
  const _SummaryPanel({
    required this.unknownCount,
    required this.reviewRound,
    required this.onReview,
    required this.onRestart,
  });

  final int unknownCount;
  final bool reviewRound;
  final VoidCallback onReview;
  final VoidCallback onRestart;

  @override
  Widget build(BuildContext context) {
    final allKnown = unknownCount == 0;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(allKnown ? '🎉' : '📚', style: const TextStyle(fontSize: 48)),
            const SizedBox(height: 14),
            Text(
              allKnown
                  ? 'Bạn đã thuộc hết!'
                  : reviewRound
                      ? 'Còn $unknownCount điểm chưa thuộc'
                      : 'Hoàn thành lượt đầu — còn $unknownCount điểm chưa thuộc',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 18,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(height: 28),
            if (!allKnown)
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: onReview,
                  child: Text('Ôn lại $unknownCount điểm chưa thuộc'),
                ),
              ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: onRestart,
                child: const Text('Học lại từ đầu'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _UnknownGrammarSheet extends StatelessWidget {
  const _UnknownGrammarSheet({required this.items, required this.onReviewNow});

  final List<GrammarPoint> items;
  final VoidCallback onReviewNow;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Ngữ pháp chưa thuộc (${items.length})',
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 17,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(height: 12),
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.4,
              ),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: items.length,
                separatorBuilder: (_, __) =>
                    const Divider(height: 1, color: AppColors.border),
                itemBuilder: (context, i) {
                  final g = items[i];
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          g.title,
                          style: AppFonts.zenMaruGothic(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.ink,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          g.explanation,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.inkSoft,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: onReviewNow,
                child: Text('Ôn ngay ${items.length} điểm này'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SwipeableGrammarCard extends StatefulWidget {
  const _SwipeableGrammarCard({
    super.key,
    required this.grammar,
    required this.starred,
    required this.onSwipeRight,
    required this.onSwipeLeft,
    required this.onToggleStar,
  });

  final GrammarPoint grammar;
  final bool starred;
  final VoidCallback onSwipeRight;
  final VoidCallback onSwipeLeft;
  final VoidCallback onToggleStar;

  @override
  State<_SwipeableGrammarCard> createState() => _SwipeableGrammarCardState();
}

class _SwipeableGrammarCardState extends State<_SwipeableGrammarCard>
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
      onHorizontalDragUpdate: _completing ? null : _onPanUpdate,
      onHorizontalDragEnd: _completing ? null : _onPanEnd,
      child: Transform.translate(
        offset: _drag,
        child: Transform.rotate(
          angle: angle,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.topCenter,
            children: [
              _GrammarCardContent(
                grammar: widget.grammar,
                onMarkKnown: widget.onSwipeRight,
              ),
              if (rightProgress > 0.08)
                Positioned(
                  top: 22,
                  left: 22,
                  child: Opacity(
                    opacity: rightProgress,
                    child: const _StampLabel(
                      text: 'ĐÃ THUỘC',
                      color: AppColors.moss,
                    ),
                  ),
                ),
              if (leftProgress > 0.08)
                Positioned(
                  top: 22,
                  right: 22,
                  child: Opacity(
                    opacity: leftProgress,
                    child: const _StampLabel(
                      text: 'CHƯA THUỘC',
                      color: AppColors.accentStrong,
                    ),
                  ),
                ),
              Positioned(
                top: 14,
                right: 14,
                child: GestureDetector(
                  onTap: widget.onToggleStar,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    child: Icon(
                      widget.starred
                          ? Icons.star_rounded
                          : Icons.star_border_rounded,
                      color: widget.starred
                          ? AppColors.accent
                          : AppColors.inkFaint,
                      size: 26,
                    ),
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

class _StampLabel extends StatelessWidget {
  const _StampLabel({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.card,
        border: Border.all(color: color, width: 2.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w900,
          fontSize: 15,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

/// Toàn bộ nội dung 1 điểm ngữ pháp trên MỘT trang cuộn dọc duy nhất (không
/// lật mặt) — đúng cấu trúc thiết kế: thẻ tiêu đề gradient nhỏ ở trên, các
/// mục Ý nghĩa/Ví dụ/Mẹo ghi nhớ/So sánh/Lỗi thường gặp mỗi mục 1 khối riêng.
class _GrammarCardContent extends StatelessWidget {
  const _GrammarCardContent({required this.grammar, required this.onMarkKnown});

  final GrammarPoint grammar;
  final VoidCallback onMarkKnown;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 420),
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppColors.plum, Color(0xFF8A3B70)],
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.plum.withValues(alpha: 0.25),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Text(
                grammar.title,
                textAlign: TextAlign.center,
                style: AppFonts.zenMaruGothic(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (grammar.meanings.isNotEmpty)
              GrammarSection(
                color: AppColors.plum,
                label: 'Ý NGHĨA',
                child: Column(
                  children: [
                    for (final (i, meaning) in grammar.meanings.indexed)
                      Padding(
                        padding: EdgeInsets.only(
                          bottom: i == grammar.meanings.length - 1 ? 0 : 10,
                        ),
                        child: GrammarMeaningCard(
                          index: i + 1,
                          meaning: meaning,
                        ),
                      ),
                  ],
                ),
              )
            else
              GrammarSection(
                color: AppColors.plum,
                label: 'Ý NGHĨA',
                child: GrammarInfoBox(
                  child: Text(
                    grammar.explanation,
                    style: const TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.ink,
                      height: 1.4,
                    ),
                  ),
                ),
              ),
            if (grammar.meanings.isEmpty && grammar.exampleJp != null) ...[
              const SizedBox(height: 14),
              GrammarSection(
                color: AppColors.indigo,
                label: 'VÍ DỤ',
                child: GrammarInfoBox(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      JpExampleText(
                        grammar.exampleJp!,
                        style: AppFonts.zenMaruGothic(
                          fontSize: 15,
                          fontWeight: FontWeight.w400,
                          color: AppColors.ink,
                        ),
                      ),
                      if (grammar.exampleVi != null) ...[
                        const SizedBox(height: 5),
                        Text(
                          grammar.exampleVi!,
                          style: const TextStyle(
                            fontSize: 11.5,
                            color: AppColors.inkSoft,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
            if (grammar.memoryTip != null) ...[
              const SizedBox(height: 14),
              GrammarSection(
                color: AppColors.moss,
                label: 'MẸO GHI NHỚ',
                child: GrammarInfoBox(
                  background: AppColors.chip,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.lightbulb_rounded,
                          color: AppColors.accent, size: 20,),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          grammar.memoryTip!,
                          style: const TextStyle(
                            fontSize: 12.5,
                            color: AppColors.ink,
                            height: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            if (grammar.comparisonNote != null) ...[
              const SizedBox(height: 14),
              GrammarSection(
                color: AppColors.plum,
                label: 'SO SÁNH',
                child: GrammarInfoBox(
                  background: AppColors.plumSoft,
                  child: Text(
                    grammar.comparisonNote!,
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: AppColors.ink,
                      height: 1.4,
                    ),
                  ),
                ),
              ),
            ],
            if (grammar.commonMistake != null) ...[
              const SizedBox(height: 14),
              GrammarSection(
                color: AppColors.danger,
                label: 'LỖI THƯỜNG GẶP',
                child: GrammarInfoBox(
                  background: AppColors.dangerSoft,
                  child: Text(
                    grammar.commonMistake!,
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: AppColors.danger,
                      height: 1.4,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: FilledButton(
                    onPressed: () => context.push('/quiz/grammar'),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.plum,
                    ),
                    child: const Text('Quiz ngữ pháp'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onMarkKnown,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.plum,
                      side: const BorderSide(color: AppColors.plum, width: 2),
                    ),
                    icon: const Icon(Icons.check_rounded, size: 18),
                    label: const Text('Đã thuộc'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
