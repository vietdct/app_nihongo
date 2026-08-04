import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../../domain/entities/kanji.dart';
import '../../domain/entities/vocabulary.dart';
import '../../shared/card_dot_progress.dart';
import '../../shared/card_known_stats.dart';
import '../../shared/card_stamp_label.dart';
import '../../shared/flip_card.dart';
import '../../shared/gradient_card_shell.dart';
import '../../shared/jp_speak_button.dart';
import '../../shared/kanji_stroke_canvas.dart';
import '../home/providers/mission_providers.dart';
import '../lesson/providers/content_providers.dart';
import '../lesson/providers/level_providers.dart';
import 'providers/kanji_family_providers.dart';
import 'providers/kanji_progress_providers.dart';

/// Bấm vào 1 kanji mở bộ thẻ vuốt qua — giống hệt từ vựng: vuốt phải đánh
/// dấu đã thuộc, vuốt trái đánh dấu chưa thuộc, chạm sao để lưu lại. Bộ thẻ
/// bắt đầu từ đúng chữ vừa bấm.
///
/// [filterIds] khi được truyền (vd. từ Smart Review) chỉ giới hạn bộ thẻ
/// đúng những chữ này thay vì cả cấp độ, đồng thời chuyển thẻ sang kiểu lật
/// 2 mặt đơn giản giống hệt flashcard từ vựng (mặt trước: chữ Hán, chạm để
/// lật xem Hán Việt/On/Kun/nghĩa) thay vì trang đầy đủ nét chữ + mẹo nhớ —
/// dùng để ôn nhanh đúng tập kanji AI đã chọn bằng thao tác vuốt thay vì
/// màn chấm điểm SRS cũ. Khi duyệt kanji bình thường (không qua Smart
/// Review, [filterIds] null) vẫn giữ trang đầy đủ: hoạt hoạ nét chữ
/// (KanjiVG), Hán Việt, nghĩa, âm On/Kun, mẹo ghi nhớ, ví dụ.
class KanjiDetailScreen extends ConsumerStatefulWidget {
  const KanjiDetailScreen({super.key, required this.kanjiId, this.filterIds});

  final String kanjiId;
  final Set<String>? filterIds;

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
    if (mounted) {
      ref.invalidate(kanjiProgressProvider);
      ref.invalidate(dailyMissionStatusProvider);
    }
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
    if (mounted) {
      ref.invalidate(kanjiProgressProvider);
      ref.invalidate(dailyMissionStatusProvider);
    }
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
    final vocabList = ref.watch(vocabularyListProvider).valueOrNull ?? const [];
    final levelCode = ref.watch(selectedLevelCodeProvider);

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(title: const Text('Flashcard Kanji')),
      body: kanjiAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Lỗi: $e')),
        data: (all) {
          final filterIds = widget.filterIds;
          final source = filterIds == null
              ? all
              : all.where((k) => filterIds.contains(k.id)).toList();

          if (source.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  filterIds == null
                      ? 'Chưa có kanji nào cho cấp độ này.'
                      : 'Không tìm thấy chữ nào cần ôn.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.inkSoft),
                ),
              ),
            );
          }

          _fullDeck ??= source;
          _deck ??= List.of(source);
          if (!_indexInitialized) {
            final startIndex = source.indexWhere((k) => k.id == widget.kanjiId);
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
          final simple = filterIds != null;
          final wrongIndices = {
            for (var i = 0; i < _index; i++)
              if (_unknownIds.contains(deck[i].id)) i,
          };
          final relatedVocab = simple
              ? const <Vocabulary>[]
              : [
                  for (final v in vocabList)
                    if (v.word.contains(kanji.character)) v,
                ].take(5).toList();
          final hasFamily = !simple && !computeKanjiFamily(kanji, all).isEmpty;

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
                    const Expanded(child: SizedBox.shrink()),
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
                // "x / total" luôn căn giữa tuyệt đối theo bề ngang màn hình,
                // tách khỏi hàng nút quay lại/badge (2 bên không đối xứng
                // nhau về độ rộng nên nếu dùng chung 1 Row, Expanded ở giữa
                // sẽ bị lệch tâm khi badge hiện/ẩn). Ở chế độ simple (flip
                // card), số này chuyển xuống dưới khung flashcard.
                if (!simple) ...[
                  const SizedBox(height: 6),
                  Text(
                    _reviewRound
                        ? 'Ôn chữ chưa thuộc · ${_index + 1}/$total'
                        : '${_index + 1} / $total',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: AppColors.inkSoft,
                    ),
                  ),
                ],
                const SizedBox(height: 14),
                simple
                    ? CardDotProgress(
                        total: total,
                        index: _index,
                        wrongIndices: wrongIndices,
                      )
                    : ClipRRect(
                        borderRadius: BorderRadius.circular(100),
                        child: LinearProgressIndicator(
                          value: (_index + 1) / total,
                          minHeight: 5,
                          backgroundColor: AppColors.chip,
                          valueColor:
                              const AlwaysStoppedAnimation(AppColors.accent),
                        ),
                      ),
                const SizedBox(height: 26),
                Expanded(
                  child: Center(
                    child: _SwipeableKanjiCard(
                      key: ValueKey(kanji.id),
                      kanji: kanji,
                      starred: starred,
                      relatedVocab: relatedVocab,
                      hasFamily: hasFamily,
                      simple: simple,
                      levelCode: levelCode,
                      onSwipeRight: () => _markKnown(kanji, controller),
                      onSwipeLeft: () => _markUnknown(kanji, controller),
                      onToggleStar: () =>
                          _toggleStar(kanji, starred, controller),
                    ),
                  ),
                ),
                SizedBox(height: simple ? 16 : 26),
                if (simple) ...[
                  Text(
                    _reviewRound
                        ? 'Ôn chữ chưa thuộc · ${_index + 1}/$total'
                        : '${_index + 1} / $total',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: AppColors.inkSoft,
                    ),
                  ),
                  const SizedBox(height: 8),
                  CardKnownStats(
                    known: _index - _unknownIds.length,
                    unknown: _unknownIds.length,
                  ),
                  const SizedBox(height: 10),
                ],
                Text(
                  _unknownIds.isNotEmpty
                      ? 'Vuốt phải: đã thuộc · Vuốt trái: chưa thuộc · Chạm badge để xem/ôn ngay'
                      : simple
                          ? 'Vuốt phải: đã thuộc · Vuốt trái: chưa thuộc · Chạm: xem nghĩa'
                          : 'Vuốt phải: đã thuộc · Vuốt trái: chưa thuộc',
                  textAlign: TextAlign.center,
                  style:
                      const TextStyle(fontSize: 12, color: AppColors.inkFaint),
                ),
                if (!simple && kanji.strokeData != null) ...[
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
    required this.relatedVocab,
    required this.hasFamily,
    required this.simple,
    required this.levelCode,
    required this.onSwipeRight,
    required this.onSwipeLeft,
    required this.onToggleStar,
  });

  final Kanji kanji;
  final bool starred;
  final List<Vocabulary> relatedVocab;
  final bool hasFamily;
  final bool simple;
  final String levelCode;
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
              widget.simple
                  ? FlipCard(
                      front: _KanjiFront(
                        kanji: widget.kanji,
                        levelCode: widget.levelCode,
                      ),
                      back: _KanjiBack(kanji: widget.kanji),
                    )
                  : _KanjiCardContent(
                      kanji: widget.kanji,
                      relatedVocab: widget.relatedVocab,
                      hasFamily: widget.hasFamily,
                      onMarkKnown: widget.onSwipeRight,
                    ),
              if (rightProgress > 0)
                Positioned.fill(
                  child: IgnorePointer(
                    child: Opacity(
                      opacity: rightProgress * 0.35,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: AppColors.moss,
                          borderRadius: BorderRadius.circular(28),
                        ),
                      ),
                    ),
                  ),
                ),
              if (leftProgress > 0)
                Positioned.fill(
                  child: IgnorePointer(
                    child: Opacity(
                      opacity: leftProgress * 0.35,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: AppColors.danger,
                          borderRadius: BorderRadius.circular(28),
                        ),
                      ),
                    ),
                  ),
                ),
              if (rightProgress > 0.08)
                Positioned(
                  top: 24,
                  left: 24,
                  child: Opacity(
                    opacity: rightProgress,
                    child: const CardStampLabel(
                      text: 'ĐÃ THUỘC',
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
                      text: 'CHƯA THUỘC',
                      color: AppColors.danger,
                      angle: 0.21,
                    ),
                  ),
                ),
              Positioned(
                top: 16,
                right: 16,
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
                      size: 28,
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

/// Thẻ lật 2 mặt cho Smart Review — theo đúng mockup "Flashcard Final"
/// (claude.ai/design): viền gradient cam→hồng ở mặt trước, xanh lá ở mặt
/// sau, thay cho khung viền phẳng cũ. Mặt trước chỉ gợi ý (số nét + 1 cách
/// đọc), chạm để lật xem đầy đủ Hán Việt/On-Kun/nghĩa/ví dụ ở mặt sau.
class _KanjiFront extends StatelessWidget {
  const _KanjiFront({required this.kanji, required this.levelCode});

  final Kanji kanji;
  final String levelCode;

  @override
  Widget build(BuildContext context) {
    final reading = kanji.kunyomi.isNotEmpty
        ? kanji.kunyomi.first
        : (kanji.onyomi.isNotEmpty ? kanji.onyomi.first : null);
    return GradientCardShell(
      gradientColors: const [Color(0xFFFF9C5A), Color(0xFFFF7A45), Color(0xFFD85A93)],
      shadowColor: AppColors.accent.withValues(alpha: 0.25),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.indigoSoft, Color(0xFFD1DBFF)],
              ),
              borderRadius: BorderRadius.circular(100),
            ),
            child: Text(
              '$levelCode · KANJI',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: AppColors.indigo,
                letterSpacing: 0.5,
              ),
            ),
          ),
          const SizedBox(height: 28),
          Text(
            kanji.character,
            textAlign: TextAlign.center,
            style: AppFonts.zenMaruGothic(
              fontSize: 96,
              fontWeight: FontWeight.w900,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 10,
            runSpacing: 8,
            children: [
              if (kanji.strokeCount != null)
                _FrontChip(icon: Icons.gesture_rounded, label: '${kanji.strokeCount} nét'),
              if (reading != null) _FrontChip(label: reading, isJapanese: true),
            ],
          ),
          const SizedBox(height: 28),
          _AudioButton(
            text: reading ?? kanji.character,
            background: const Color(0xFFFFF3EB),
            iconColor: AppColors.accent,
          ),
        ],
      ),
    );
  }
}

class _FrontChip extends StatelessWidget {
  const _FrontChip({this.icon, required this.label, this.isJapanese = false});

  final IconData? icon;
  final String label;
  final bool isJapanese;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3EB),
        borderRadius: BorderRadius.circular(100),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: AppColors.accent),
            const SizedBox(width: 6),
          ],
          Text(
            label,
            style: isJapanese
                ? AppFonts.zenMaruGothic(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.accent,
                  )
                : const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.accent,
                  ),
          ),
        ],
      ),
    );
  }
}

/// Nút loa tròn bọc quanh [JpSpeakButton] có sẵn (TTS dùng chung giọng đã
/// lưu toàn app) để khớp kiểu nút tròn nổi trong thiết kế thay vì IconButton
/// phẳng mặc định.
class _AudioButton extends StatelessWidget {
  const _AudioButton({
    required this.text,
    required this.background,
    required this.iconColor,
    this.size = 52,
  });

  final String text;
  final Color background;
  final Color iconColor;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: background, shape: BoxShape.circle),
      child: JpSpeakButton(text: text, color: iconColor, size: size * 0.42),
    );
  }
}

class _KanjiBack extends StatelessWidget {
  const _KanjiBack({required this.kanji});

  final Kanji kanji;

  @override
  Widget build(BuildContext context) {
    final readingForAudio = kanji.kunyomi.isNotEmpty
        ? kanji.kunyomi.first
        : (kanji.onyomi.isNotEmpty ? kanji.onyomi.first : kanji.character);
    return GradientCardShell(
      gradientColors: const [Color(0xFF3FB35B), Color(0xFF2D9A47), Color(0xFF1E8038)],
      shadowColor: AppColors.moss.withValues(alpha: 0.25),
      innerBackground: const Color(0xFFEEFBF0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            kanji.character,
            textAlign: TextAlign.center,
            style: AppFonts.zenMaruGothic(
              fontSize: 52,
              fontWeight: FontWeight.w900,
              color: AppColors.ink,
            ),
          ),
          if (kanji.hanViet.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              kanji.hanViet.join(' · ').toUpperCase(),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: AppColors.indigo,
                letterSpacing: 1,
              ),
            ),
          ],
          const SizedBox(height: 10),
          Text(
            kanji.meaningVi.join(', '),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _ReadingPill(
                  label: 'ON',
                  value: kanji.onyomi.isEmpty ? '—' : kanji.onyomi.join(' · '),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _ReadingPill(
                  label: 'KUN',
                  value: kanji.kunyomi.isEmpty ? '—' : kanji.kunyomi.join(' · '),
                ),
              ),
            ],
          ),
          if (kanji.exampleJp != null) ...[
            const SizedBox(height: 18),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    kanji.exampleJp!,
                    style: AppFonts.zenMaruGothic(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w400,
                      color: AppColors.ink,
                    ),
                  ),
                  if (kanji.exampleVi != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      kanji.exampleVi!,
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
          const SizedBox(height: 24),
          _AudioButton(
            text: readingForAudio,
            background: Colors.white,
            iconColor: AppColors.moss,
            size: 48,
          ),
        ],
      ),
    );
  }
}

class _ReadingPill extends StatelessWidget {
  const _ReadingPill({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: AppColors.inkSoft,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            textAlign: TextAlign.center,
            style: AppFonts.zenMaruGothic(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.ink,
            ),
          ),
        ],
      ),
    );
  }
}

/// Toàn bộ nội dung 1 chữ Hán trên MỘT trang cuộn dọc duy nhất (không lật
/// mặt) — đúng cấu trúc thiết kế: khối minh hoạ nét chữ ở trên, các mục
/// Nghĩa/Onyomi/Kunyomi/Mẹo ghi nhớ/Ví dụ mỗi mục 1 khối riêng bên dưới.
class _KanjiCardContent extends StatefulWidget {
  const _KanjiCardContent({
    required this.kanji,
    required this.relatedVocab,
    required this.hasFamily,
    required this.onMarkKnown,
  });

  final Kanji kanji;
  final List<Vocabulary> relatedVocab;
  final bool hasFamily;
  final VoidCallback onMarkKnown;

  @override
  State<_KanjiCardContent> createState() => _KanjiCardContentState();
}

class _KanjiCardContentState extends State<_KanjiCardContent> {
  final _canvasKey = GlobalKey<KanjiStrokeCanvasState>();

  @override
  Widget build(BuildContext context) {
    final kanji = widget.kanji;
    final strokeData = KanjiStrokeData.tryParse(kanji.strokeData);
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 420),
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppColors.border),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.ink.withValues(alpha: 0.06),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 180,
                    height: 180,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.canvas,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.indigoSoft, width: 2),
                    ),
                    child: KanjiStrokeCanvas(
                      key: _canvasKey,
                      character: kanji.character,
                      strokeData: strokeData,
                      size: 150,
                      strokeColor: AppColors.ink,
                      guideColor: AppColors.ink.withValues(alpha: 0.12),
                    ),
                  ),
                  const SizedBox(height: 14),
                  if (strokeData != null)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        InkWell(
                          borderRadius: BorderRadius.circular(100),
                          onTap: () => _canvasKey.currentState?.replay(),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 9,
                            ),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [AppColors.indigo, Color(0xFF7B61FF)],
                              ),
                              borderRadius: BorderRadius.circular(100),
                              boxShadow: [
                                BoxShadow(
                                  color:
                                      AppColors.indigo.withValues(alpha: 0.3),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.play_arrow_rounded,
                                  size: 16,
                                  color: Colors.white,
                                ),
                                SizedBox(width: 5),
                                Text(
                                  'Xem lại nét vẽ',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 12,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        InkWell(
                          borderRadius: BorderRadius.circular(100),
                          onTap: () =>
                              context.push('/kanji/${kanji.id}/practice'),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 9,
                            ),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(100),
                              border: Border.all(
                                color: AppColors.indigo,
                                width: 1.5,
                              ),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.edit_rounded,
                                  size: 15,
                                  color: AppColors.indigo,
                                ),
                                SizedBox(width: 5),
                                Text(
                                  'Luyện viết',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 12,
                                    color: AppColors.indigo,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    )
                  else
                    const Icon(
                      Icons.touch_app_outlined,
                      color: AppColors.inkFaint,
                      size: 20,
                    ),
                  if (kanji.hanViet.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    Text(
                      kanji.hanViet.join(' · ').toUpperCase(),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: AppColors.indigo,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),
            _Section(
              color: AppColors.indigo,
              label: 'NGHĨA',
              child: _InfoBox(
                child: Text(
                  kanji.meaningVi.join(', '),
                  style: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),
            _Section(
              color: AppColors.indigo,
              label: 'ONYOMI',
              trailing: 'âm Hán',
              child: _InfoBox(
                background: AppColors.indigoSoft,
                child: Text(
                  kanji.onyomi.isEmpty ? '—' : kanji.onyomi.join('、'),
                  style: AppFonts.zenMaruGothic(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: AppColors.indigo,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),
            _Section(
              color: AppColors.indigo,
              label: 'KUNYOMI',
              trailing: 'âm Nhật',
              child: _InfoBox(
                child: Text(
                  kanji.kunyomi.isEmpty ? '—' : kanji.kunyomi.join('、'),
                  style: AppFonts.zenMaruGothic(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.ink,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (kanji.onyomi.isNotEmpty || kanji.kunyomi.isNotEmpty)
                  InkWell(
                    borderRadius: BorderRadius.circular(100),
                    onTap: () => context.push('/kanji/${kanji.id}/reading'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 9,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.indigoSoft,
                        borderRadius: BorderRadius.circular(100),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.record_voice_over_rounded,
                            size: 15,
                            color: AppColors.indigo,
                          ),
                          SizedBox(width: 5),
                          Text(
                            'Luyện đọc',
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 12,
                              color: AppColors.indigo,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                if (widget.hasFamily)
                  InkWell(
                    borderRadius: BorderRadius.circular(100),
                    onTap: () => context.push('/kanji/${kanji.id}/family'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 9,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(100),
                        border: Border.all(
                          color: AppColors.indigo,
                          width: 1.5,
                        ),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.account_tree_rounded,
                            size: 15,
                            color: AppColors.indigo,
                          ),
                          SizedBox(width: 5),
                          Text(
                            'Gia đình Kanji',
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 12,
                              color: AppColors.indigo,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                InkWell(
                  borderRadius: BorderRadius.circular(100),
                  onTap: () => context.push('/kanji/${kanji.id}/tutor'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 9,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.tealSoft,
                      borderRadius: BorderRadius.circular(100),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.auto_awesome_rounded,
                          size: 15,
                          color: AppColors.teal,
                        ),
                        SizedBox(width: 5),
                        Text(
                          'Hỏi AI',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 12,
                            color: AppColors.teal,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            if (kanji.mnemonic != null) ...[
              const SizedBox(height: 14),
              _Section(
                color: AppColors.moss,
                label: 'MẸO GHI NHỚ',
                child: _InfoBox(
                  background: AppColors.chip,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.lightbulb_rounded,
                        color: AppColors.accent,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          kanji.mnemonic!,
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
            if (kanji.exampleJp != null) ...[
              const SizedBox(height: 14),
              _Section(
                color: AppColors.plum,
                label: 'VÍ DỤ',
                child: _InfoBox(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        kanji.exampleJp!,
                        style: AppFonts.zenMaruGothic(
                          fontSize: 15,
                          fontWeight: FontWeight.w400,
                          color: AppColors.ink,
                        ),
                      ),
                      if (kanji.exampleVi != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          kanji.exampleVi!,
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
            if (widget.relatedVocab.isNotEmpty) ...[
              const SizedBox(height: 14),
              _Section(
                color: AppColors.moss,
                label: 'TỪ VỰNG CHỨA CHỮ NÀY',
                child: _InfoBox(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (var i = 0; i < widget.relatedVocab.length; i++) ...[
                        if (i > 0) const SizedBox(height: 8),
                        RichText(
                          text: TextSpan(
                            children: [
                              TextSpan(
                                text: widget.relatedVocab[i].word,
                                style: AppFonts.zenMaruGothic(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.ink,
                                ),
                              ),
                              TextSpan(
                                text:
                                    '（${widget.relatedVocab[i].reading}） ${widget.relatedVocab[i].primaryMeaning}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.inkSoft,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: FilledButton(
                    onPressed: () => context.push('/quiz/kanji'),
                    child: const Text('Quiz'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: widget.onMarkKnown,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.indigo,
                      side: const BorderSide(color: AppColors.indigo, width: 2),
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

class _Section extends StatelessWidget {
  const _Section({
    required this.color,
    required this.label,
    required this.child,
    this.trailing,
  });

  final Color color;
  final String label;
  final String? trailing;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: AppColors.ink,
              ),
            ),
            if (trailing != null) ...[
              const SizedBox(width: 6),
              Text(
                trailing!,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: AppColors.inkFaint,
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 8),
        child,
      ],
    );
  }
}

class _InfoBox extends StatelessWidget {
  const _InfoBox({required this.child, this.background = AppColors.card});

  final Widget child;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(16),
        border: background == AppColors.card
            ? Border.all(color: AppColors.border)
            : null,
      ),
      child: child,
    );
  }
}
