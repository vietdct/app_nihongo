import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/entities/kanji.dart';
import '../../../domain/entities/lesson.dart';
import '../../../domain/services/quiz_generator.dart';
import '../../lesson/providers/content_providers.dart';

const _quizGenerator = QuizGenerator();

/// Quiz luyện đọc riêng 1 Kanji — pool là chính chữ đó (on/kun) + các từ
/// vựng thật có chứa chữ này (`vocab.word.contains(kanji.character)`, cùng
/// kỹ thuật honest-data đã dùng ở "TỪ VỰNG CHỨA CHỮ NÀY" trong Kanji Detail).
/// Dùng `readingOnly: true` để chỉ hỏi trục cách đọc, khác quiz Kanji chung
/// (`/quiz/kanji`) hỏi lẫn cả nghĩa lẫn cách đọc trên toàn bộ trình độ.
/// `autoDispose` — mỗi lần vào lại random câu hỏi mới, không đoán trước được.
final kanjiReadingPracticeQuestionsProvider = Provider.autoDispose
    .family<AsyncValue<List<QuizQuestion>>, String>((ref, kanjiId) {
  final kanjiAsync = ref.watch(kanjiListProvider);
  final vocabAsync = ref.watch(vocabularyListProvider);

  return kanjiAsync.when(
    loading: () => const AsyncValue.loading(),
    error: (e, st) => AsyncValue.error(e, st),
    data: (allKanji) {
      Kanji? target;
      for (final k in allKanji) {
        if (k.id == kanjiId) {
          target = k;
          break;
        }
      }
      final resolvedTarget = target;
      if (resolvedTarget == null) return const AsyncValue.data([]);

      return vocabAsync.whenData((allVocab) {
        final relatedVocab = allVocab
            .where((v) => v.word.contains(resolvedTarget.character));
        final pool = [
          LessonContentItem.kanji(resolvedTarget),
          for (final v in relatedVocab) LessonContentItem.vocabulary(v),
        ];
        return _quizGenerator.generate(
          pool: pool,
          readingOnly: true,
          questionCount: 10,
        );
      });
    },
  );
});
