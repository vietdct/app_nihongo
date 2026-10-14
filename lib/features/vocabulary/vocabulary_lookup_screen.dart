// Màn tra cứu từ vựng (v2) — chuyển từ thiết kế "Nihongo App Redesign".
// Dùng font đóng gói sẵn (BeVietnamPro, ZenMaruGothic — xem pubspec.yaml) thay
// cho google_fonts để chạy offline. Mở bằng `showVocabDetailSheet` (đặt trong
// `vocabulary_list_screen.dart`, giữ nguyên chữ ký để mọi nơi gọi không phải đổi).
import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';

import '../../core/services/dialogue_audio.dart';
import '../../core/services/jp_voice_prefs.dart';
import '../../data/repositories/content_repository_provider.dart';
import '../../domain/entities/kanji.dart';
import '../../domain/entities/vocabulary.dart';
import '../../shared/kanji_text_utils.dart';
import '../kanji/kanji_detail_screen.dart';
import '../home/providers/mission_providers.dart';
import '../lesson/providers/level_providers.dart';
import 'providers/vocab_progress_providers.dart';

// ───────── Bảng màu ─────────
class NColors {
  static const bg = Color(0xFFFAF7F2);
  static const ink = Color(0xFF2A2420);
  static const inkSoft = Color(0xFF3A322C);
  static const inkLine = Color(0xFF4A4038);
  static const text2 = Color(0xFF6B6155);
  static const text3 = Color(0xFF948A7C);
  static const text4 = Color(0xFFB7AE9F);
  static const line = Color(0xFFEAE1D2);
  static const lineSoft = Color(0xFFF2EBE0);
  static const cream = Color(0xFFEDE6D9);
  static const creamMuted = Color(0xFFD8CFC0);
  static const accent = Color(0xFFE2632E);
  static const accentLight = Color(0xFFF08A5D);
  static const accentBg = Color(0xFFFBE6D8);
  static const accentDark = Color(0xFFB94A1E);
  static const indigo = Color(0xFF4B6278);
  static const indigoBg = Color(0xFFEEF1F4);
}

TextStyle jp(
  double size, {
  FontWeight w = FontWeight.w500,
  Color c = NColors.ink,
  double? h,
  double ls = 0,
}) =>
    TextStyle(
      fontFamily: 'ZenMaruGothic',
      fontSize: size,
      fontWeight: w,
      color: c,
      height: h,
      letterSpacing: ls,
    );

TextStyle vi(
  double size, {
  FontWeight w = FontWeight.w500,
  Color c = NColors.ink,
  double? h,
  double ls = 0,
}) =>
    TextStyle(
      fontFamily: 'BeVietnamPro',
      fontSize: size,
      fontWeight: w,
      color: c,
      height: h,
      letterSpacing: ls,
    );

List<BoxShadow> get softShadow => const [
      BoxShadow(color: Color(0x0A2A2420), blurRadius: 2, offset: Offset(0, 1)),
      BoxShadow(color: Color(0x0A2A2420), blurRadius: 18, offset: Offset(0, 6)),
    ];

// ───────── Model hiển thị (map từ entity Vocabulary) ─────────
class KanjiPart {
  const KanjiPart({
    required this.id,
    required this.levelId,
    required this.char,
    required this.hanViet,
    this.meaning = '',
    this.strokes,
    this.onyomi = const [],
    this.kunyomi = const [],
  });
  final String id, levelId, char, hanViet, meaning;
  final int? strokes;
  final List<String> onyomi, kunyomi;
}

class Meaning {
  const Meaning(this.text, [this.note]);
  final String text;
  final String? note;
}

class Example {
  const Example({required this.jp, this.vi});
  final String jp;
  final String? vi;
}

class RelatedWord {
  const RelatedWord({required this.vocab});
  final Vocabulary vocab;
  String get word => vocab.word;
  String get reading => vocab.reading;
  String get meaning => vocab.primaryMeaning;
}

class VocabDetail {
  const VocabDetail({
    required this.word,
    required this.reading,
    required this.parts,
    required this.meanings,
    this.tags = const [],
    this.examples = const [],
    this.related = const [],
    this.highlightKanji,
  });
  final String word;
  final String reading;

  /// Phân tích từng chữ Kanji (không trùng lặp) kèm âm Hán Việt.
  final List<KanjiPart> parts;
  final List<Meaning> meanings;
  final List<String> tags;
  final List<Example> examples;
  final List<RelatedWord> related;
  final String? highlightKanji;
}

// ───────── Màn hình ─────────
class VocabularyLookupScreen extends ConsumerStatefulWidget {
  const VocabularyLookupScreen({super.key, required this.vocab});
  final Vocabulary vocab;

  @override
  ConsumerState<VocabularyLookupScreen> createState() =>
      _VocabularyLookupScreenState();
}

class _VocabularyLookupScreenState extends ConsumerState<VocabularyLookupScreen>
    with SingleTickerProviderStateMixin {
  static const _initialExamples = 2;

  final _audio = DialogueAudio();
  final _tts = FlutterTts()
    ..setLanguage('ja-JP')
    ..setVolume(1.0)
    ..awaitSpeakCompletion(true);
  late final AnimationController _wave = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );

  List<Kanji> _kanji = const [];
  List<Vocabulary> _related = const [];
  bool? _starredOverride;
  AudioPlaybackSpeed _speed = AudioPlaybackSpeed.x100;
  String? _playingText;
  bool _showAllExamples = false;
  bool _usageOpen = false;
  int tab = 0;

  @override
  void initState() {
    super.initState();
    unawaited(_prepareVoice());
    unawaited(_loadExtras());
  }

  @override
  void dispose() {
    unawaited(_tts.stop());
    unawaited(_audio.dispose());
    _wave.dispose();
    super.dispose();
  }

  Future<void> _prepareVoice() async {
    final speed = await loadJpSpeechSpeed();
    if (mounted) setState(() => _speed = speed);
    await configureJpTts(_tts);
  }

  /// Tra Kanji (âm Hán Việt, số nét) và các từ khác chứa chung Kanji — cùng
  /// nguồn dữ liệu với bottom sheet cũ.
  Future<void> _loadExtras() async {
    final repo = ref.read(contentRepositoryProvider);
    final kanji = <Kanji>[];
    for (final c in uniqueKanjiChars(widget.vocab.word)) {
      final k = await repo.findKanjiByCharacter(c);
      if (k != null) kanji.add(k);
    }
    final related = await repo.findRelatedVocabulary(
      widget.vocab.word,
      excludeId: widget.vocab.id,
    );
    if (!mounted) return;
    setState(() {
      _kanji = kanji;
      _related = related;
    });
  }

  /// Bấm lại đúng câu đang phát thì dừng.
  Future<void> _speak(String text) async {
    if (text.isEmpty) return;
    final wasPlaying = _playingText == text;
    await _tts.stop();
    await _audio.stop();
    if (wasPlaying) {
      _setPlaying(null);
      return;
    }
    await _tts.setSpeechRate(_speed.ttsRate);
    _setPlaying(text);
    try {
      // Ưu tiên audio cloud tạo sẵn; chưa có file → TTS máy.
      if (await _audio.playSentence(text, _speed.multiplier)) return;
      if (_playingText != text) return;
      if (kDebugMode) debugPrint('[TTS] fallback giọng máy: "$text"');
      await _tts.speak(prepareJpForSpeech(text));
    } finally {
      // Câu khác đã được bấm trong lúc chờ thì không xoá trạng thái của nó.
      if (_playingText == text) _setPlaying(null);
    }
  }

  void _setPlaying(String? text) {
    if (!mounted) return;
    setState(() => _playingText = text);
    if (text == null) {
      _wave
        ..stop()
        ..value = 0;
    } else {
      _wave.repeat();
    }
  }

  Future<void> _pickSpeed() async {
    final picked = await showModalBottomSheet<AudioPlaybackSpeed>(
      context: context,
      backgroundColor: NColors.bg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (_) => _SpeedSheet(selected: _speed),
    );
    if (picked == null || picked == _speed || !mounted) return;
    setState(() => _speed = picked);
    await saveJpSpeechSpeed(picked);
  }

  Future<void> _toggleStar(bool current) async {
    final controller = ref.read(vocabProgressControllerProvider);
    if (controller == null) return;
    setState(() => _starredOverride = !current);
    try {
      await controller.setStarred(widget.vocab.id, !current);
    } catch (_) {
      // Lưu thất bại: trả icon về trạng thái cũ để không báo "đã lưu" giả.
      if (!mounted) return;
      setState(() => _starredOverride = current);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không lưu được, vui lòng thử lại.')),
      );
      return;
    }
    if (mounted) ref.invalidate(vocabProgressProvider);
  }

  Future<void> _mark(bool known) async {
    final controller = ref.read(vocabProgressControllerProvider);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    await controller?.setKnown(widget.vocab.id, known);
    ref.invalidate(vocabProgressProvider);
    ref.invalidate(dailyMissionStatusProvider);
    messenger.showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 2),
        content: Text(
          known
              ? 'Đã đánh dấu "đã thuộc".'
              : 'Đã đánh dấu "chưa nhớ" — sẽ ôn lại sớm.',
        ),
      ),
    );
    navigator.maybePop();
  }

  void _openRelated(Vocabulary related) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => VocabularyLookupScreen(vocab: related),
      ),
    );
  }

  /// Chữ Kanji xuất hiện nhiều nhất trong các từ liên quan — dùng làm chữ
  /// "CÙNG CHỮ" và tô nổi trong danh sách.
  String? _highlightKanji() {
    final chars = uniqueKanjiChars(widget.vocab.word);
    if (chars.isEmpty) return null;
    var best = chars.first;
    var bestCount = -1;
    for (final c in chars) {
      final n = _related.where((r) => r.word.contains(c)).length;
      if (n > bestCount) {
        best = c;
        bestCount = n;
      }
    }
    return best;
  }

  VocabDetail _detail(String levelCode) {
    final v = widget.vocab;
    return VocabDetail(
      word: v.word,
      reading: v.reading,
      highlightKanji: _highlightKanji(),
      tags: [
        if (levelCode.isNotEmpty) levelCode,
        if (v.partOfSpeech != null) v.partOfSpeech!,
        if (v.category != null) v.category!,
      ],
      parts: [
        for (final k in _kanji)
          KanjiPart(
            id: k.id,
            levelId: k.levelId,
            char: k.character,
            hanViet: k.hanViet.isEmpty ? '' : k.hanViet.first.toUpperCase(),
            meaning: k.meaningVi.isEmpty ? '' : k.meaningVi.first,
            strokes: k.strokeCount,
            onyomi: k.onyomi,
            kunyomi: k.kunyomi,
          ),
      ],
      meanings: [for (final m in v.meanings) Meaning(m.meaningVi)],
      examples: [
        for (final m in v.meanings)
          for (final e in m.allExamples) Example(jp: e.$1, vi: e.$2),
      ],
      related: [for (final r in _related) RelatedWord(vocab: r)],
    );
  }

  @override
  Widget build(BuildContext context) {
    final v = widget.vocab;
    final levels = ref.watch(jlptLevelsProvider).valueOrNull;
    final levelCode = levels == null
        ? ''
        : levels
                .where((l) => l.id == v.levelId)
                .map((l) => l.code)
                .firstOrNull ??
            '';
    final progress = ref.watch(vocabProgressProvider).valueOrNull?[v.id];
    final starred = _starredOverride ?? (progress?.starred == true);
    final d = _detail(levelCode);

    return Scaffold(
      backgroundColor: NColors.bg,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _topBar(context, levelCode),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.only(bottom: 24),
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: _hero(d, starred),
                  ),
                  if (_hasUsage(v))
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                      child: _usageSection(v),
                    ),
                  const SizedBox(height: 24),
                  _tabs(),
                  const SizedBox(height: 16),
                  ..._tabContent(d),
                ],
              ),
            ),
            _bottomBar(progress?.isKnown),
          ],
        ),
      ),
    );
  }

  List<Widget> _tabContent(VocabDetail d) {
    switch (tab) {
      case 0:
        if (d.examples.isEmpty) return [_empty('Chưa có ví dụ cho từ này.')];
        final shown = _showAllExamples
            ? d.examples
            : d.examples.take(_initialExamples).toList();
        final hidden = d.examples.length - shown.length;
        return [
          for (final e in shown)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
              child: _ExampleCard(
                example: e,
                highlight: _highlightTarget(e.jp, d.word),
                playing: _playingText == e.jp,
                onPlay: () => _speak(e.jp),
              ),
            ),
          if (hidden > 0)
            Center(
              child: TextButton(
                onPressed: () => setState(() => _showAllExamples = true),
                child: Text(
                  'Xem thêm $hidden ví dụ',
                  style: vi(13.5, w: FontWeight.w700, c: NColors.accent),
                ),
              ),
            ),
        ];
      case 1:
        if (d.parts.isEmpty) {
          return [_empty('Từ này không có chữ Kanji để phân tích.')];
        }
        return [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                for (final p in d.parts)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _KanjiPartCard(
                      part: p,
                      highlighted: p.char == d.highlightKanji,
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => KanjiDetailScreen(
                            kanjiId: p.id,
                            levelId: p.levelId,
                            single: true,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ];
      default:
        final similar = widget.vocab.similarWords;
        if (d.related.isEmpty && similar.isEmpty) {
          return [_empty('Chưa có từ liên quan.')];
        }
        return [
          if (similar.isNotEmpty) ...[
            _sectionHeader('TỪ GẦN NGHĨA', null),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 18),
              child: Column(
                children: [
                  for (final w in similar)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _SimilarRow(word: w),
                    ),
                ],
              ),
            ),
          ],
          if (d.related.isNotEmpty)
            _sectionHeader('CÙNG CHỮ', d.highlightKanji),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: LayoutBuilder(
              builder: (context, c) {
                final w = (c.maxWidth - 10) / 2;
                return Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    for (final r in d.related)
                      SizedBox(
                        width: w,
                        height: 104,
                        child: _RelatedCard(
                          word: r,
                          highlight: d.highlightKanji,
                          onTap: () => _openRelated(r.vocab),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        ];
    }
  }

  Widget _empty(String text) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
        child: Center(
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: vi(13, c: NColors.text3),
          ),
        ),
      );

  Widget _circleBtn(Widget child, VoidCallback? onTap) => InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: NColors.lineSoft),
          ),
          alignment: Alignment.center,
          child: child,
        ),
      );

  Widget _topBar(BuildContext context, String levelCode) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 14),
        child: Row(
          children: [
            _circleBtn(
              const Icon(
                Icons.arrow_back_ios_new_rounded,
                size: 14,
                color: NColors.ink,
              ),
              () => Navigator.maybePop(context),
            ),
            Expanded(
              child: Center(
                child: Text(
                  levelCode.isEmpty ? 'Từ vựng' : 'Từ vựng $levelCode',
                  style: vi(14, w: FontWeight.w800, c: NColors.text2),
                ),
              ),
            ),
            const SizedBox(width: 34),
          ],
        ),
      );

  Widget _hero(VocabDetail d, bool starred) {
    final showReading = d.reading.isNotEmpty && d.reading != d.word;
    final chars = d.word.runes.map(String.fromCharCode).toList();
    // Từ/cụm dài (VD "ご訪問くださる") thu nhỏ chữ để không tràn khung.
    final size =
        chars.length <= 4 ? 68.0 : (272.0 / chars.length).clamp(26.0, 68.0);
    final hanVietOf = {for (final p in d.parts) p.char: p.hanViet};

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: NColors.ink,
        borderRadius: BorderRadius.circular(26),
        boxShadow: const [
          BoxShadow(
            color: Color(0x382A2420),
            blurRadius: 34,
            offset: Offset(0, 14),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Chữ trang trí: lớp dưới cùng, rất mờ, bị cắt bởi khung thẻ
          // (Clip.antiAlias) và nằm trọn phía trên hàng nút.
          Positioned(
            right: -14,
            top: -10,
            child: IgnorePointer(
              child: ExcludeSemantics(
                child: Text(
                  chars.first,
                  style: jp(
                    120,
                    w: FontWeight.w900,
                    c: Colors.white.withValues(alpha: 0.05),
                    h: 1,
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (var i = 0; i < d.tags.length; i++)
                      _tag(d.tags[i], primary: i == 0),
                  ],
                ),
                const SizedBox(height: 12),
                if (showReading)
                  Text(d.reading, style: jp(15, c: NColors.text4, ls: 2)),
                Wrap(
                  spacing: 2,
                  children: [
                    for (final ch in chars)
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            ch,
                            style: jp(
                              size,
                              w: FontWeight.w700,
                              h: 1.05,
                              c: ch == d.highlightKanji
                                  ? NColors.accentLight
                                  : NColors.bg,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            hanVietOf[ch] ?? '',
                            style: vi(
                              10.5,
                              w: FontWeight.w700,
                              c: NColors.text3,
                              ls: 1.4,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                _MeaningList(meanings: d.meanings),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _playButton(d.word)),
                    const SizedBox(width: 8),
                    _darkSquare(
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _speed.label,
                            style: vi(
                              12.5,
                              w: FontWeight.w800,
                              c: NColors.accentLight,
                            ),
                          ),
                          const Icon(
                            Icons.keyboard_arrow_down_rounded,
                            size: 18,
                            color: NColors.accentLight,
                          ),
                        ],
                      ),
                      _pickSpeed,
                      width: 78,
                    ),
                    const SizedBox(width: 8),
                    _darkSquare(
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 220),
                        transitionBuilder: (child, anim) =>
                            ScaleTransition(scale: anim, child: child),
                        child: Icon(
                          starred
                              ? Icons.star_rounded
                              : Icons.star_outline_rounded,
                          key: ValueKey(starred),
                          color: NColors.accentLight,
                          size: 22,
                        ),
                      ),
                      () => _toggleStar(starred),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _tag(String t, {bool primary = false}) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: primary ? NColors.indigo : NColors.inkSoft,
          borderRadius: BorderRadius.circular(100),
        ),
        child: Text(
          t,
          style: vi(
            11,
            w: primary ? FontWeight.w800 : FontWeight.w600,
            c: primary ? Colors.white : NColors.creamMuted,
            ls: primary ? 0.5 : 0,
          ),
        ),
      );

  Widget _playButton(String word) {
    const bars = [8.0, 16.0, 11.0, 20.0, 9.0, 14.0, 6.0];
    final playing = _playingText == word;
    return Material(
      color: NColors.accent,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => _speak(word),
        child: SizedBox(
          height: 46,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              children: [
                Icon(
                  playing ? Icons.stop_rounded : Icons.volume_up_rounded,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Text(
                  playing ? 'Đang phát' : 'Nghe',
                  style: vi(14.5, w: FontWeight.w700, c: Colors.white),
                ),
                const Spacer(),
                if (playing)
                  AnimatedBuilder(
                    animation: _wave,
                    builder: (_, __) => Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        for (var i = 0; i < bars.length; i++)
                          Container(
                            width: 3,
                            height: 6 +
                                bars[i] *
                                    (0.5 +
                                        0.5 *
                                            math.sin(
                                              _wave.value * 2 * math.pi +
                                                  i * 0.9,
                                            )),
                            margin: const EdgeInsets.only(left: 3),
                            decoration: BoxDecoration(
                              color: NColors.accentBg,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _darkSquare(Widget child, VoidCallback onTap, {double width = 46}) =>
      Material(
        color: NColors.inkSoft,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child:
              SizedBox(width: width, height: 46, child: Center(child: child)),
        ),
      );

  /// Chỉ hiện khi từ có dữ liệu cách dùng thật (hiện mới có ở vài từ).
  bool _hasUsage(Vocabulary v) =>
      v.commonUsagePattern != null ||
      v.commonUsageDesc != null ||
      v.nuancePoints.isNotEmpty ||
      v.commonMistakeNote != null;

  Widget _usageSection(Vocabulary v) {
    final body = <Widget>[
      if (v.commonUsageDesc != null)
        Text(v.commonUsageDesc!, style: vi(13, c: NColors.text2, h: 1.55)),
      for (final e in v.commonUsageExamples)
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text.rich(
            TextSpan(
              children: [
                TextSpan(text: e.phrase, style: jp(14, w: FontWeight.w700)),
                TextSpan(
                  text: '  ${e.meaningVi}',
                  style: vi(12.5, c: NColors.text3),
                ),
              ],
            ),
          ),
        ),
      for (final n in v.nuancePoints)
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(
            '• ${n.replaceAll('**', '')}',
            style: vi(13, c: NColors.text2, h: 1.5),
          ),
        ),
      if (v.commonMistakeNote != null)
        Padding(
          padding: const EdgeInsets.only(top: 10),
          child: Text(
            'Dễ nhầm: ${v.commonMistakeNote}',
            style: vi(12.5, w: FontWeight.w600, c: NColors.accentDark, h: 1.5),
          ),
        ),
    ];
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: NColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: () => setState(() => _usageOpen = !_usageOpen),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Text(
                    '使い方 · Cách dùng',
                    style: vi(13, w: FontWeight.w800, c: NColors.ink),
                  ),
                  if (v.commonUsagePattern != null) ...[
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        v.commonUsagePattern!,
                        style: jp(12.5, c: NColors.accent),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ] else
                    const Spacer(),
                  Icon(
                    _usageOpen
                        ? Icons.expand_less_rounded
                        : Icons.expand_more_rounded,
                    color: NColors.text3,
                  ),
                ],
              ),
            ),
          ),
          if (_usageOpen)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: body,
              ),
            ),
        ],
      ),
    );
  }

  Widget _tabs() {
    const labels = ['Ví dụ', 'Phân tích Kanji', 'Từ liên quan'];
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: NColors.line)),
      ),
      child: Row(
        children: [
          for (var i = 0; i < labels.length; i++)
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => setState(() => tab = i),
              child: Container(
                margin: const EdgeInsets.only(right: 22),
                padding: const EdgeInsets.only(bottom: 11),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: tab == i ? NColors.accent : Colors.transparent,
                      width: 2.5,
                    ),
                  ),
                ),
                child: Text(
                  labels[i],
                  style: vi(
                    14,
                    w: tab == i ? FontWeight.w800 : FontWeight.w600,
                    c: tab == i ? NColors.accent : NColors.text2,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title, String? kanji) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              title,
              style: vi(11.5, w: FontWeight.w700, c: NColors.text4, ls: 0.8),
            ),
            if (kanji != null) ...[
              const SizedBox(width: 5),
              Text(kanji, style: jp(13, w: FontWeight.w700, c: NColors.accent)),
            ],
          ],
        ),
      );

  Widget _bottomBar(bool? isKnown) => Container(
        padding: EdgeInsets.fromLTRB(
          20,
          10,
          20,
          10 + MediaQuery.of(context).padding.bottom,
        ),
        decoration: const BoxDecoration(
          color: NColors.bg,
          border: Border(top: BorderSide(color: NColors.line)),
        ),
        child: Row(
          children: [
            Expanded(
              flex: 10,
              child: OutlinedButton(
                onPressed: () => _mark(false),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(44),
                  backgroundColor:
                      isKnown == false ? NColors.accentBg : Colors.white,
                  side: BorderSide(
                    color: isKnown == false ? NColors.accent : NColors.line,
                    width: 1.5,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
                child: Text(
                  'Chưa nhớ',
                  style: vi(
                    14.5,
                    w: FontWeight.w700,
                    c: isKnown == false ? NColors.accentDark : NColors.text2,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              flex: 14,
              child: FilledButton.icon(
                onPressed: () => _mark(true),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(44),
                  backgroundColor: NColors.ink,
                  side: isKnown == true
                      ? const BorderSide(color: NColors.accent, width: 2)
                      : null,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
                icon: Icon(
                  isKnown == true
                      ? Icons.check_circle_rounded
                      : Icons.check_rounded,
                  color: NColors.accentLight,
                  size: 20,
                ),
                label: Text(
                  'Đã thuộc',
                  style: vi(14.5, w: FontWeight.w700, c: Colors.white),
                ),
              ),
            ),
          ],
        ),
      );
}

// ───────── Danh sách nghĩa (hỗ trợ nhiều nghĩa) ─────────
class _MeaningList extends StatelessWidget {
  const _MeaningList({required this.meanings});
  final List<Meaning> meanings;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 4, 14, 4),
      decoration: BoxDecoration(
        color: NColors.inkSoft.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 10, bottom: 6),
            child: Row(
              children: [
                Text(
                  'NGHĨA',
                  style:
                      vi(10.5, w: FontWeight.w800, c: NColors.text3, ls: 1.2),
                ),
                const Spacer(),
                if (meanings.length > 1)
                  Text(
                    '${meanings.length} nghĩa',
                    style: vi(11, w: FontWeight.w600, c: NColors.text3),
                  ),
              ],
            ),
          ),
          for (var i = 0; i < meanings.length; i++)
            Container(
              padding: EdgeInsets.only(top: i == 0 ? 10 : 12, bottom: 12),
              decoration: BoxDecoration(
                border: i < meanings.length - 1
                    ? const Border(bottom: BorderSide(color: NColors.inkLine))
                    : null,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 22,
                    height: 22,
                    margin: const EdgeInsets.only(top: 1),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: i == 0 ? NColors.accent : NColors.inkLine,
                      borderRadius: BorderRadius.circular(7),
                    ),
                    child: Text(
                      '${i + 1}',
                      style: vi(
                        12,
                        w: FontWeight.w800,
                        c: i == 0 ? Colors.white : NColors.creamMuted,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          meanings[i].text,
                          style: i == 0
                              ? vi(
                                  17,
                                  w: FontWeight.w700,
                                  c: NColors.bg,
                                  h: 1.35,
                                )
                              : vi(
                                  15,
                                  w: FontWeight.w600,
                                  c: NColors.cream,
                                  h: 1.4,
                                ),
                        ),
                        if (meanings[i].note != null) ...[
                          const SizedBox(height: 3),
                          Text(
                            meanings[i].note!,
                            style: vi(
                              12,
                              c: i == 0 ? NColors.text4 : NColors.text3,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

// ───────── Thẻ con ─────────
List<TextSpan> _highlightSpans(
  String text,
  String? target,
  TextStyle base,
  Color hl,
) {
  if (target == null || target.isEmpty || !text.contains(target)) {
    return [TextSpan(text: text, style: base)];
  }
  final parts = text.split(target);
  final spans = <TextSpan>[];
  for (var i = 0; i < parts.length; i++) {
    if (parts[i].isNotEmpty) spans.add(TextSpan(text: parts[i], style: base));
    if (i < parts.length - 1) {
      spans.add(
        TextSpan(
          text: target,
          style: base.copyWith(color: hl, fontWeight: FontWeight.w700),
        ),
      );
    }
  }
  return spans;
}

/// Đoạn của [word] xuất hiện trong [sentence] để tô nổi: thử nguyên từ, bỏ ký
/// hiệu ngoặc/〜/…, bỏ phần ngoặc đứng riêng, tách theo "／", rồi cắt đuôi
/// る/い (động từ/tính từ chia dạng khác, VD 減らす → 減らします).
String? _highlightTarget(String sentence, String word) {
  final variants = <String>{};
  for (final part in word.split('／')) {
    variants
      ..add(part)
      ..add(part.replaceAll(RegExp('[（）()〜～…！!]'), ''))
      ..add(
        part
            .replaceAll(RegExp('[（(][^）)]*[）)]'), '')
            .replaceAll(RegExp('[〜～…！!]'), ''),
      );
  }
  final candidates = <String>[];
  for (final v in variants) {
    if (v.isEmpty) continue;
    candidates.add(v);
    if (v.length >= 3 && (v.endsWith('る') || v.endsWith('い'))) {
      candidates.add(v.substring(0, v.length - 1));
    }
  }
  candidates.sort((a, b) => b.length.compareTo(a.length));
  for (final c in candidates) {
    if (c.length >= 2 && sentence.contains(c)) return c;
  }
  return null;
}

class _ExampleCard extends StatelessWidget {
  const _ExampleCard({
    required this.example,
    required this.highlight,
    required this.onPlay,
    this.playing = false,
  });
  final Example example;
  final String? highlight;
  final VoidCallback onPlay;
  final bool playing;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: softShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text.rich(
                    TextSpan(
                      children: _highlightSpans(
                        example.jp,
                        highlight,
                        jp(16.5, h: 1.7),
                        NColors.accent,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                InkWell(
                  onTap: onPlay,
                  customBorder: const CircleBorder(),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: const BoxDecoration(
                      color: NColors.accentBg,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      playing ? Icons.stop_rounded : Icons.play_arrow_rounded,
                      size: 18,
                      color: NColors.accentDark,
                    ),
                  ),
                ),
              ],
            ),
            if (example.vi != null) ...[
              const SizedBox(height: 8),
              Text(example.vi!, style: vi(13, c: NColors.text2, h: 1.5)),
            ],
          ],
        ),
      );
}

class _RelatedCard extends StatelessWidget {
  const _RelatedCard({required this.word, required this.onTap, this.highlight});
  final RelatedWord word;
  final VoidCallback onTap;
  final String? highlight;

  @override
  Widget build(BuildContext context) => InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: NColors.line),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                word.reading,
                style: jp(11.5, c: NColors.text3),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text.rich(
                TextSpan(
                  children: _highlightSpans(
                    word.word,
                    highlight,
                    jp(22, w: FontWeight.w700),
                    NColors.accent,
                  ),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const Spacer(),
              Text(
                word.meaning,
                style: vi(12.5, c: NColors.text2),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      );
}

class _KanjiPartCard extends StatelessWidget {
  const _KanjiPartCard({
    required this.part,
    required this.onTap,
    this.highlighted = false,
  });
  final KanjiPart part;
  final bool highlighted;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final detail = [
      if (part.meaning.isNotEmpty) part.meaning,
      if (part.strokes != null) '${part.strokes} nét',
    ].join(' · ');
    final readings = [
      if (part.onyomi.isNotEmpty) 'On: ${part.onyomi.join('、')}',
      if (part.kunyomi.isNotEmpty) 'Kun: ${part.kunyomi.join('、')}',
    ].join('   ');
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: softShadow,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: highlighted ? NColors.accentBg : NColors.indigoBg,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    part.char,
                    style: jp(
                      28,
                      c: highlighted ? NColors.accentDark : NColors.indigo,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (part.hanViet.isNotEmpty)
                        Text(
                          part.hanViet,
                          style: vi(12, w: FontWeight.w800, ls: 1),
                        ),
                      if (part.hanViet.isNotEmpty && detail.isNotEmpty)
                        const SizedBox(height: 2),
                      if (detail.isNotEmpty)
                        Text(detail, style: vi(12, c: NColors.text3)),
                      if (readings.isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Text(readings, style: jp(12.5, c: NColors.text2)),
                      ],
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: NColors.text4,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ───────── Chọn tốc độ phát âm ─────────
class _SpeedSheet extends StatelessWidget {
  const _SpeedSheet({required this.selected});
  final AudioPlaybackSpeed selected;

  @override
  Widget build(BuildContext context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Tốc độ phát âm',
                style: vi(15, w: FontWeight.w800),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  for (final s in AudioPlaybackSpeed.values)
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(
                          right: s == AudioPlaybackSpeed.values.last ? 0 : 6,
                        ),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () => Navigator.of(context).pop(s),
                          child: Container(
                            height: 44,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color:
                                  s == selected ? NColors.accent : Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: s == selected
                                    ? NColors.accent
                                    : NColors.line,
                              ),
                            ),
                            child: Text(
                              s.label,
                              style: vi(
                                13,
                                w: FontWeight.w700,
                                c: s == selected ? Colors.white : NColors.text2,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      );
}

class _SimilarRow extends StatelessWidget {
  const _SimilarRow({required this.word});
  final VocabSimilarWord word;

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: NColors.line),
        ),
        child: Row(
          children: [
            Text(word.word, style: jp(18, w: FontWeight.w700)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                word.meaningVi,
                style: vi(12.5, c: NColors.text2),
              ),
            ),
          ],
        ),
      );
}
