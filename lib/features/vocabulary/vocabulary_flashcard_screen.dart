import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../domain/entities/vocab_meaning.dart';
import '../../domain/entities/vocabulary.dart';
import '../../shared/flip_card.dart';
import '../lesson/providers/content_providers.dart';
import 'providers/vocab_progress_providers.dart';

/// Flashcard từ vựng — vuốt phải để đánh dấu đã thuộc, vuốt trái để đánh
/// dấu chưa thuộc (gom vào danh sách ôn lại cuối phiên). Chạm vào thẻ để
/// lật xem nghĩa; chạm ngôi sao góc trên để lưu từ xem lại sau.
class VocabularyFlashcardScreen extends ConsumerStatefulWidget {
  const VocabularyFlashcardScreen({super.key});

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
    if (mounted) ref.invalidate(vocabProgressProvider);
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
    if (mounted) ref.invalidate(vocabProgressProvider);
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
          if (all.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Chưa có từ vựng nào cho cấp độ này.',
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

          final vocab = deck[_index];
          final starred = _starredOverride[vocab.id] ??
              progressMap[vocab.id]?.starred ??
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
                      child: Column(
                        children: [
                          Text(
                            _reviewRound
                                ? 'Ôn từ chưa thuộc · ${_index + 1}/$total'
                                : '${_index + 1} / $total',
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              color: AppColors.inkSoft,
                            ),
                          ),
                        ],
                      ),
                    ),
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
                const SizedBox(height: 8),
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
                front: _VocabFront(vocab: widget.vocab),
                back: _VocabBack(vocab: widget.vocab),
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

class _VocabFront extends StatelessWidget {
  const _VocabFront({required this.vocab});

  final Vocabulary vocab;

  @override
  Widget build(BuildContext context) {
    return _CardShell(
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
    return _CardShell(
      background: AppColors.mossSoft,
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
