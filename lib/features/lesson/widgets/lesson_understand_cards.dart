import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../domain/entities/grammar_point.dart';
import '../../../domain/entities/kanji.dart';
import '../../../domain/entities/vocab_meaning.dart';
import '../../../domain/entities/vocabulary.dart';
import '../../../shared/jp_speak_button.dart';
import '../../../shared/kanji_stroke_canvas.dart';
import '../../grammar/widgets/grammar_content_sections.dart';

/// 3 thẻ "Understand" — cố ý xây MỚI, nhẹ, chỉ đọc (không có swipe/star/SRS
/// như `VocabularyFlashcardScreen`/`KanjiDetailScreen`) thay vì tách widget
/// con từ 2 màn đó: đây là lần ĐẦU TIÊN người học thấy nội dung này trong
/// bài, hành động phù hợp là "đọc rồi bấm tiếp", không phải đánh giá
/// biết/chưa biết (việc đó thuộc về Flashcard/Review, xảy ra sau khi đã học
/// qua Lesson). Có trùng lặp hiển thị nhỏ với các màn kia — chấp nhận được
/// vì đổi lại tách rời hoàn toàn state (không rủi ro ảnh hưởng ngược lại
/// flashcard/progress khi chỉnh sửa Lesson).
class _UnderstandCardShell extends StatelessWidget {
  const _UnderstandCardShell({
    required this.badgeLabel,
    required this.badgeColor,
    required this.badgeSoft,
    required this.onDone,
    required this.child,
  });

  final String badgeLabel;
  final Color badgeColor;
  final Color badgeSoft;
  final VoidCallback onDone;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppColors.border, width: 1.0),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(color: badgeSoft, borderRadius: BorderRadius.circular(100)),
                    child: Text(
                      badgeLabel,
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: badgeColor),
                    ),
                  ),
                  const SizedBox(height: 16),
                  child,
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: FilledButton(onPressed: onDone, child: const Text('Đã hiểu →')),
        ),
      ],
    );
  }
}

class LessonVocabUnderstandCard extends StatelessWidget {
  const LessonVocabUnderstandCard({super.key, required this.vocab, required this.onDone});

  final Vocabulary vocab;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    return _UnderstandCardShell(
      badgeLabel: 'Từ vựng mới',
      badgeColor: AppColors.moss,
      badgeSoft: AppColors.mossSoft,
      onDone: onDone,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  vocab.word,
                  style: AppFonts.zenMaruGothic(fontSize: 36, fontWeight: FontWeight.w800, color: AppColors.ink),
                ),
              ),
              JpSpeakButton(text: vocab.word, color: AppColors.moss),
            ],
          ),
          Text(
            vocab.reading,
            style: AppFonts.zenMaruGothic(fontSize: 17, fontWeight: FontWeight.w600, color: AppColors.moss),
          ),
          const SizedBox(height: 16),
          for (var i = 0; i < vocab.meanings.length; i++) ...[
            if (i > 0) const SizedBox(height: 14),
            _VocabMeaningBlock(index: i, showNumber: vocab.meanings.length > 1, meaning: vocab.meanings[i]),
          ],
        ],
      ),
    );
  }
}

class _VocabMeaningBlock extends StatelessWidget {
  const _VocabMeaningBlock({required this.index, required this.showNumber, required this.meaning});

  final int index;
  final bool showNumber;
  final VocabMeaning meaning;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          showNumber ? '${index + 1}. ${meaning.meaningVi}' : meaning.meaningVi,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.ink),
        ),
        if (meaning.exampleJp != null) ...[
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: AppColors.mossSoft, borderRadius: BorderRadius.circular(14)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(meaning.exampleJp!, style: AppFonts.zenMaruGothic(fontSize: 14, color: AppColors.ink)),
                if (meaning.exampleVi != null) ...[
                  const SizedBox(height: 4),
                  Text(meaning.exampleVi!, style: const TextStyle(fontSize: 12.5, color: AppColors.inkSoft)),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class LessonKanjiUnderstandCard extends StatefulWidget {
  const LessonKanjiUnderstandCard({super.key, required this.kanji, required this.onDone});

  final Kanji kanji;
  final VoidCallback onDone;

  @override
  State<LessonKanjiUnderstandCard> createState() => _LessonKanjiUnderstandCardState();
}

class _LessonKanjiUnderstandCardState extends State<LessonKanjiUnderstandCard> {
  final _canvasKey = GlobalKey<KanjiStrokeCanvasState>();

  @override
  Widget build(BuildContext context) {
    final kanji = widget.kanji;
    final strokeData = KanjiStrokeData.tryParse(kanji.strokeData);

    return _UnderstandCardShell(
      badgeLabel: 'Kanji mới',
      badgeColor: AppColors.indigo,
      badgeSoft: AppColors.indigoSoft,
      onDone: widget.onDone,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: GestureDetector(
              onTap: () => _canvasKey.currentState?.replay(),
              child: KanjiStrokeCanvas(
                key: _canvasKey,
                character: kanji.character,
                strokeData: strokeData,
                size: 160,
              ),
            ),
          ),
          if (strokeData != null)
            const Padding(
              padding: EdgeInsets.only(top: 6, bottom: 4),
              child: Center(
                child: Text('Chạm để xem lại nét viết', style: TextStyle(fontSize: 11.5, color: AppColors.inkFaint)),
              ),
            ),
          const SizedBox(height: 12),
          Text(
            kanji.meaningVi.join(' · '),
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AppColors.ink),
          ),
          if (kanji.hanViet.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text('Hán Việt: ${kanji.hanViet.join('、')}', style: const TextStyle(fontSize: 13, color: AppColors.inkSoft)),
          ],
          const SizedBox(height: 10),
          if (kanji.onyomi.isNotEmpty) _ReadingRow(label: 'On', readings: kanji.onyomi),
          if (kanji.kunyomi.isNotEmpty) _ReadingRow(label: 'Kun', readings: kanji.kunyomi),
          if (kanji.mnemonic != null) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: AppColors.indigoSoft, borderRadius: BorderRadius.circular(14)),
              child: Text(kanji.mnemonic!, style: const TextStyle(fontSize: 13, color: AppColors.ink, height: 1.4)),
            ),
          ],
          if (kanji.exampleJp != null) ...[
            const SizedBox(height: 10),
            Text(kanji.exampleJp!, style: AppFonts.zenMaruGothic(fontSize: 14, color: AppColors.ink)),
            if (kanji.exampleVi != null) ...[
              const SizedBox(height: 4),
              Text(kanji.exampleVi!, style: const TextStyle(fontSize: 12.5, color: AppColors.inkSoft)),
            ],
          ],
        ],
      ),
    );
  }
}

class _ReadingRow extends StatelessWidget {
  const _ReadingRow({required this.label, required this.readings});

  final String label;
  final List<String> readings;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 36,
            child: Text(label, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.inkFaint)),
          ),
          Expanded(
            child: Text(readings.join('、'), style: AppFonts.zenMaruGothic(fontSize: 13.5, color: AppColors.ink)),
          ),
        ],
      ),
    );
  }
}

class LessonGrammarUnderstandCard extends StatelessWidget {
  const LessonGrammarUnderstandCard({super.key, required this.grammar, required this.onDone});

  final GrammarPoint grammar;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    return _UnderstandCardShell(
      badgeLabel: 'Ngữ pháp mới',
      badgeColor: AppColors.plum,
      badgeSoft: AppColors.plumSoft,
      onDone: onDone,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  grammar.title,
                  style: AppFonts.zenMaruGothic(fontSize: 24, fontWeight: FontWeight.w800, color: AppColors.ink),
                ),
              ),
              JpSpeakButton(text: grammar.title, color: AppColors.plum),
            ],
          ),
          const SizedBox(height: 8),
          Text(grammar.explanation, style: const TextStyle(fontSize: 14.5, color: AppColors.ink, height: 1.45)),
          if (grammar.exampleJp != null) ...[
            const SizedBox(height: 16),
            GrammarSection(
              color: AppColors.plum,
              label: 'VÍ DỤ',
              child: GrammarInfoBox(
                background: AppColors.plumSoft,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(grammar.exampleJp!, style: AppFonts.zenMaruGothic(fontSize: 14.5, color: AppColors.ink)),
                    if (grammar.exampleVi != null) ...[
                      const SizedBox(height: 6),
                      Text(grammar.exampleVi!, style: const TextStyle(fontSize: 12.5, color: AppColors.inkSoft)),
                    ],
                  ],
                ),
              ),
            ),
          ],
          if (grammar.commonMistake != null) ...[
            const SizedBox(height: 16),
            GrammarSection(
              color: AppColors.danger,
              label: 'LỖI THƯỜNG GẶP',
              child: GrammarInfoBox(
                background: AppColors.dangerSoft,
                child: Text(grammar.commonMistake!, style: const TextStyle(fontSize: 13.5, color: AppColors.ink)),
              ),
            ),
          ],
          if (grammar.memoryTip != null) ...[
            const SizedBox(height: 16),
            GrammarSection(
              color: AppColors.accent,
              label: 'MẸO NHỚ',
              child: GrammarInfoBox(
                background: AppColors.accentSoft,
                child: Text(grammar.memoryTip!, style: const TextStyle(fontSize: 13.5, color: AppColors.ink)),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
