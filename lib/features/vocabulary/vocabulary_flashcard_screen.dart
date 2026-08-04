import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../domain/entities/vocab_meaning.dart';
import '../../domain/entities/vocabulary.dart';
import '../../shared/card_dot_progress.dart';
import '../../shared/card_known_stats.dart';
import '../../shared/card_stamp_label.dart';
import '../../shared/flip_card.dart';
import '../../shared/gradient_card_shell.dart';
import '../home/providers/mission_providers.dart';
import '../lesson/providers/content_providers.dart';
import 'providers/vocab_progress_providers.dart';

/// Flashcard từ vựng — vuốt phải để đánh dấu đã thuộc, vuốt trái để đánh
/// dấu chưa thuộc (gom vào danh sách ôn lại cuối phiên). Chạm vào thẻ để
/// lật xem nghĩa; chạm ngôi sao góc trên để lưu từ xem lại sau.
///
/// [filterIds] khi được truyền (vd. từ Smart Review) chỉ giới hạn bộ thẻ
/// đúng những từ này thay vì cả cấp độ — dùng để ôn đúng tập từ AI đã chọn
/// bằng thao tác vuốt thay vì màn chấm điểm SRS cũ.
class VocabularyFlashcardScreen extends ConsumerStatefulWidget {
  const VocabularyFlashcardScreen({super.key, this.filterIds});

  final Set<String>? filterIds;

  @override
  ConsumerState<VocabularyFlashcardScreen> createState() =>
      _VocabularyFlashcardScreenState();
}

class _VocabularyFlashcardScreenState
    extends ConsumerState<VocabularyFlashcardScreen> {
  List<Vocabulary>? _fullDeck;
  List<Vocabulary>? _deck;
  int _index = 0;
  bool _reviewRound = false;
  final Set<String> _unknownIds = {};
  final Map<String, bool> _starredOverride = {};

  Future<void> _markKnown(
    Vocabulary v,
    VocabProgressController? controller,
  ) async {
    setState(() {
      _unknownIds.remove(v.id);
      _index++;
    });
    await controller?.setKnown(v.id, true);
    if (mounted) {
      ref.invalidate(vocabProgressProvider);
      ref.invalidate(dailyMissionStatusProvider);
    }
  }

  Future<void> _markUnknown(
    Vocabulary v,
    VocabProgressController? controller,
  ) async {
    setState(() {
      _unknownIds.add(v.id);
      _index++;
    });
    await controller?.setKnown(v.id, false);
    if (mounted) {
      ref.invalidate(vocabProgressProvider);
      ref.invalidate(dailyMissionStatusProvider);
    }
  }

  Future<void> _toggleStar(
    Vocabulary v,
    bool current,
    VocabProgressController? controller,
  ) async {
    final next = !current;
    setState(() => _starredOverride[v.id] = next);
    await controller?.setStarred(v.id, next);
    if (mounted) ref.invalidate(vocabProgressProvider);
  }

  void _showUnknownWords() {
    final words = _fullDeck!.where((v) => _unknownIds.contains(v.id)).toList();
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      backgroundColor: AppColors.card,
      isScrollControlled: true,
      builder: (sheetContext) => _UnknownWordsSheet(
        words: words,
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
      _deck = _fullDeck!.where((v) => _unknownIds.contains(v.id)).toList();
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
    final vocabAsync = ref.watch(vocabularyListProvider);
    final progressAsync = ref.watch(vocabProgressProvider);
    final controller = ref.watch(vocabProgressControllerProvider);

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(title: const Text('Flashcard từ vựng')),
      body: vocabAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Lỗi: $e')),
        data: (all) {
          final filterIds = widget.filterIds;
          final source = filterIds == null
              ? all
              : all.where((v) => filterIds.contains(v.id)).toList();

          if (source.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  filterIds == null
                      ? 'Chưa có từ vựng nào cho cấp độ này.'
                      : 'Không tìm thấy từ nào cần ôn.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.inkSoft),
                ),
              ),
            );
          }

          _fullDeck ??= source;
          _deck ??= List.of(source);
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

          final vocab = deck[_index];
          final starred = _starredOverride[vocab.id] ??
              progressMap[vocab.id]?.starred ??
              false;
          final total = deck.length;
          final wrongIndices = {
            for (var i = 0; i < _index; i++)
              if (_unknownIds.contains(deck[i].id)) i,
          };

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
                        onTap: _showUnknownWords,
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
                const SizedBox(height: 10),
                CardDotProgress(
                  total: total,
                  index: _index,
                  wrongIndices: wrongIndices,
                ),
                const SizedBox(height: 26),
                Expanded(
                  child: Center(
                    child: _SwipeableVocabCard(
                      key: ValueKey(vocab.id),
                      vocab: vocab,
                      starred: starred,
                      onSwipeRight: () => _markKnown(vocab, controller),
                      onSwipeLeft: () => _markUnknown(vocab, controller),
                      onToggleStar: () =>
                          _toggleStar(vocab, starred, controller),
                    ),
                  ),
                ),
                // "x / total" đặt dưới khung flashcard theo yêu cầu thiết kế.
                const SizedBox(height: 16),
                Text(
                  _reviewRound
                      ? 'Ôn từ chưa thuộc · ${_index + 1}/$total'
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
                Text(
                  _unknownIds.isNotEmpty
                      ? 'Vuốt phải: đã thuộc · Vuốt trái: chưa thuộc · Chạm badge để xem/ôn ngay'
                      : 'Vuốt phải: đã thuộc · Vuốt trái: chưa thuộc · Chạm: xem nghĩa',
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
                      ? 'Còn $unknownCount từ chưa thuộc'
                      : 'Hoàn thành lượt đầu — còn $unknownCount từ chưa thuộc',
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
                  child: Text('Ôn lại $unknownCount từ chưa thuộc'),
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

class _UnknownWordsSheet extends StatelessWidget {
  const _UnknownWordsSheet({required this.words, required this.onReviewNow});

  final List<Vocabulary> words;
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
              'Từ chưa thuộc (${words.length})',
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
                itemCount: words.length,
                separatorBuilder: (_, __) =>
                    const Divider(height: 1, color: AppColors.border),
                itemBuilder: (context, i) {
                  final v = words[i];
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${v.word} 「${v.reading}」',
                          style: AppFonts.zenMaruGothic(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.ink,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          v.primaryMeaning,
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
                child: Text('Ôn ngay ${words.length} từ này'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SwipeableVocabCard extends StatefulWidget {
  const _SwipeableVocabCard({
    super.key,
    required this.vocab,
    required this.starred,
    required this.onSwipeRight,
    required this.onSwipeLeft,
    required this.onToggleStar,
  });

  final Vocabulary vocab;
  final bool starred;
  final VoidCallback onSwipeRight;
  final VoidCallback onSwipeLeft;
  final VoidCallback onToggleStar;

  @override
  State<_SwipeableVocabCard> createState() => _SwipeableVocabCardState();
}

class _SwipeableVocabCardState extends State<_SwipeableVocabCard>
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
              FlipCard(
                front: _VocabFront(vocab: widget.vocab),
                back: _VocabBack(vocab: widget.vocab),
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

class _VocabFront extends StatelessWidget {
  const _VocabFront({required this.vocab});

  final Vocabulary vocab;

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
          if (vocab.partOfSpeech != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.chip,
                borderRadius: BorderRadius.circular(100),
              ),
              child: Text(
                vocab.partOfSpeech!,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.inkFaint,
                ),
              ),
            ),
          const SizedBox(height: 28),
          Text(
            vocab.word,
            textAlign: TextAlign.center,
            style: AppFonts.zenMaruGothic(
              fontSize: 52,
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

class _VocabBack extends StatelessWidget {
  const _VocabBack({required this.vocab});

  final Vocabulary vocab;

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
            vocab.reading,
            textAlign: TextAlign.center,
            style: AppFonts.zenMaruGothic(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: AppColors.moss,
            ),
          ),
          for (var i = 0; i < vocab.meanings.length; i++) ...[
            SizedBox(height: i == 0 ? 10 : 14),
            _MeaningEntry(
              index: i,
              showNumber: vocab.meanings.length > 1,
              meaning: vocab.meanings[i],
            ),
          ],
        ],
      ),
    );
  }
}

class _MeaningEntry extends StatelessWidget {
  const _MeaningEntry({
    required this.index,
    required this.showNumber,
    required this.meaning,
  });

  final int index;
  final bool showNumber;
  final VocabMeaning meaning;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          showNumber ? '${index + 1}. ${meaning.meaningVi}' : meaning.meaningVi,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.w800,
            color: AppColors.ink,
          ),
        ),
        if (meaning.exampleJp != null) ...[
          const SizedBox(height: 8),
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
                  meaning.exampleJp!,
                  style: AppFonts.zenMaruGothic(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w400,
                    color: AppColors.ink,
                  ),
                ),
                if (meaning.exampleVi != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    meaning.exampleVi!,
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
    );
  }
}
