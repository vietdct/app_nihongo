import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../domain/entities/kanji.dart';
import '../../shared/flip_card.dart';
import '../../shared/kanji_stroke_canvas.dart';
import '../lesson/providers/content_providers.dart';
import 'providers/kanji_progress_providers.dart';

/// Bấm vào 1 kanji mở flashcard dạng bộ thẻ vuốt qua — giống hệt từ vựng:
/// vuốt phải đánh dấu đã thuộc, vuốt trái đánh dấu chưa thuộc, chạm sao để
/// lưu lại, mặt trước vẽ hoạt hoạ nét chữ (KanjiVG), mặt sau là Hán Việt/
/// âm On/âm Kun/mẹo ghi nhớ/ví dụ. Bộ thẻ bắt đầu từ đúng chữ vừa bấm.
class KanjiDetailScreen extends ConsumerStatefulWidget {
  const KanjiDetailScreen({super.key, required this.kanjiId});

  final String kanjiId;

  @override
  ConsumerState<KanjiDetailScreen> createState() => _KanjiDetailScreenState();
}

class _KanjiDetailScreenState extends ConsumerState<KanjiDetailScreen> {
  List<Kanji>? _fullDeck;
  List<Kanji>? _deck;
  int _index = 0;
  bool _indexInitialized = false;
  bool _reviewRound = false;
  final Set<String> _unknownIds = {};
  final Map<String, bool> _starredOverride = {};

  Future<void> _markKnown(Kanji k, KanjiProgressController? controller) async {
    setState(() {
      _unknownIds.remove(k.id);
      _index++;
    });
    await controller?.setKnown(k.id, true);
    if (mounted) ref.invalidate(kanjiProgressProvider);
  }

  Future<void> _markUnknown(
    Kanji k,
    KanjiProgressController? controller,
  ) async {
    setState(() {
      _unknownIds.add(k.id);
      _index++;
    });
    await controller?.setKnown(k.id, false);
    if (mounted) ref.invalidate(kanjiProgressProvider);
  }

  Future<void> _toggleStar(
    Kanji k,
    bool current,
    KanjiProgressController? controller,
  ) async {
    final next = !current;
    setState(() => _starredOverride[k.id] = next);
    await controller?.setStarred(k.id, next);
    if (mounted) ref.invalidate(kanjiProgressProvider);
  }

  void _showUnknownKanji() {
    final items = _fullDeck!.where((k) => _unknownIds.contains(k.id)).toList();
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      backgroundColor: AppColors.card,
      isScrollControlled: true,
      builder: (sheetContext) => _UnknownKanjiSheet(
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
      _deck = _fullDeck!.where((k) => _unknownIds.contains(k.id)).toList();
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
    final kanjiAsync = ref.watch(kanjiListProvider);
    final progressAsync = ref.watch(kanjiProgressProvider);
    final controller = ref.watch(kanjiProgressControllerProvider);

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(title: const Text('Flashcard Kanji')),
      body: kanjiAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Lỗi: $e')),
        data: (all) {
          if (all.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Chưa có kanji nào cho cấp độ này.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.inkSoft),
                ),
              ),
            );
          }

          _fullDeck ??= all;
          _deck ??= List.of(all);
          if (!_indexInitialized) {
            final startIndex = all.indexWhere((k) => k.id == widget.kanjiId);
            _index = startIndex >= 0 ? startIndex : 0;
            _indexInitialized = true;
          }
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

          final kanji = deck[_index];
          final starred = _starredOverride[kanji.id] ??
              progressMap[kanji.id]?.starred ??
              false;
          final total = deck.length;

          return Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
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
                            ? 'Ôn chữ chưa thuộc · ${_index + 1}/$total'
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
                        onTap: _showUnknownKanji,
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
                ClipRRect(
                  borderRadius: BorderRadius.circular(100),
                  child: LinearProgressIndicator(
                    value: (_index + 1) / total,
                    minHeight: 5,
                    backgroundColor: AppColors.chip,
                    valueColor: const AlwaysStoppedAnimation(AppColors.accent),
                  ),
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: Center(
                    child: _SwipeableKanjiCard(
                      key: ValueKey(kanji.id),
                      kanji: kanji,
                      starred: starred,
                      onSwipeRight: () => _markKnown(kanji, controller),
                      onSwipeLeft: () => _markUnknown(kanji, controller),
                      onToggleStar: () =>
                          _toggleStar(kanji, starred, controller),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _unknownIds.isNotEmpty
                      ? 'Vuốt phải: đã thuộc · Vuốt trái: chưa thuộc · Chạm badge để xem/ôn ngay'
                      : 'Vuốt phải: đã thuộc · Vuốt trái: chưa thuộc · Chạm thẻ để lật',
                  textAlign: TextAlign.center,
                  style:
                      const TextStyle(fontSize: 12, color: AppColors.inkFaint),
                ),
                if (kanji.strokeData != null) ...[
                  const SizedBox(height: 3),
                  const Text(
                    'Dữ liệu nét chữ theo dự án KanjiVG (CC BY-SA)',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 10, color: AppColors.inkFaint),
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
                      ? 'Còn $unknownCount chữ chưa thuộc'
                      : 'Hoàn thành lượt đầu — còn $unknownCount chữ chưa thuộc',
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
                  child: Text('Ôn lại $unknownCount chữ chưa thuộc'),
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

class _UnknownKanjiSheet extends StatelessWidget {
  const _UnknownKanjiSheet({required this.items, required this.onReviewNow});

  final List<Kanji> items;
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
              'Chữ chưa thuộc (${items.length})',
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
                  final k = items[i];
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Row(
                      children: [
                        Text(
                          k.character,
                          style: AppFonts.zenMaruGothic(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: AppColors.ink,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            k.meaningVi.join(', '),
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.inkSoft,
                            ),
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
                child: Text('Ôn ngay ${items.length} chữ này'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SwipeableKanjiCard extends StatefulWidget {
  const _SwipeableKanjiCard({
    super.key,
    required this.kanji,
    required this.starred,
    required this.onSwipeRight,
    required this.onSwipeLeft,
    required this.onToggleStar,
  });

  final Kanji kanji;
  final bool starred;
  final VoidCallback onSwipeRight;
  final VoidCallback onSwipeLeft;
  final VoidCallback onToggleStar;

  @override
  State<_SwipeableKanjiCard> createState() => _SwipeableKanjiCardState();
}

class _SwipeableKanjiCardState extends State<_SwipeableKanjiCard>
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
                front: _KanjiFront(kanji: widget.kanji),
                back: _KanjiBack(kanji: widget.kanji),
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

class _CardShell extends StatelessWidget {
  const _CardShell({required this.child, this.background = AppColors.card});

  final Widget child;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxWidth: 420),
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: AppColors.border, width: 0.8),
        boxShadow: [
          BoxShadow(
            color: AppColors.ink.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _KanjiFront extends StatefulWidget {
  const _KanjiFront({required this.kanji});

  final Kanji kanji;

  @override
  State<_KanjiFront> createState() => _KanjiFrontState();
}

class _KanjiFrontState extends State<_KanjiFront> {
  final _canvasKey = GlobalKey<KanjiStrokeCanvasState>();

  @override
  Widget build(BuildContext context) {
    final strokeData = KanjiStrokeData.tryParse(widget.kanji.strokeData);
    return _CardShell(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.chip,
              borderRadius: BorderRadius.circular(100),
            ),
            child: Text(
              widget.kanji.meaningVi.join(', '),
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.inkFaint,
              ),
            ),
          ),
          const SizedBox(height: 18),
          KanjiStrokeCanvas(
            key: _canvasKey,
            character: widget.kanji.character,
            strokeData: strokeData,
          ),
          const SizedBox(height: 12),
          if (strokeData != null)
            IconButton(
              onPressed: () => _canvasKey.currentState?.replay(),
              icon: const Icon(Icons.replay_rounded),
              color: AppColors.inkFaint,
              tooltip: 'Xem lại nét vẽ',
            )
          else
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

class _KanjiBack extends StatelessWidget {
  const _KanjiBack({required this.kanji});

  final Kanji kanji;

  @override
  Widget build(BuildContext context) {
    return _CardShell(
      background: AppColors.indigoSoft,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (kanji.hanViet.isNotEmpty)
            Text(
              kanji.hanViet.join(' · ').toUpperCase(),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: AppColors.indigo,
                letterSpacing: 0.5,
              ),
            ),
          const SizedBox(height: 6),
          Text(
            kanji.meaningVi.join(', '),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _ReadingBlock(label: 'Âm On', values: kanji.onyomi),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _ReadingBlock(label: 'Âm Kun', values: kanji.kunyomi),
              ),
            ],
          ),
          if (kanji.mnemonic != null) ...[
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'MẸO GHI NHỚ',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: AppColors.inkFaint,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    kanji.mnemonic!,
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: AppColors.ink,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (kanji.exampleJp != null) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    kanji.exampleJp!,
                    style: AppFonts.zenMaruGothic(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: AppColors.ink,
                    ),
                  ),
                  if (kanji.exampleVi != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      kanji.exampleVi!,
                      style: const TextStyle(
                        fontSize: 12,
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

class _ReadingBlock extends StatelessWidget {
  const _ReadingBlock({required this.label, required this.values});

  final String label;
  final List<String> values;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: AppColors.inkFaint,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            values.isEmpty ? '—' : values.join('、'),
            style: AppFonts.zenMaruGothic(
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
              color: AppColors.ink,
            ),
          ),
        ],
      ),
    );
  }
}
