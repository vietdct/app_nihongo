import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/entities/lesson.dart';
import '../../../domain/services/dialogue_listening_generator.dart';
import '../../../domain/services/quiz_generator.dart';
import '../../lesson/providers/content_providers.dart';
import '../../lesson/providers/level_providers.dart';
import 'listening_dialogue_providers.dart';

const _quizGenerator = QuizGenerator();
const _dialogueGenerator = DialogueListeningGenerator();

/// Quiz theo 1 bài học cụ thể — pool câu hỏi = đúng nội dung bài học đó
/// (`lessonItemsProvider`). Không cần distractorPool riêng: nếu bài học
/// quá ít item, QuizGenerator tự co số lựa chọn mỗi câu (xem quiz_generator.dart).
///
/// `autoDispose`: cố ý KHÔNG giữ cache — `Provider` thường sẽ chỉ gọi
/// `generate()` (và xáo trộn) đúng 1 lần rồi tái dùng mãi mãi trong suốt
/// vòng đời app, khiến làm lại quiz vẫn ra y hệt thứ tự câu/đáp án cũ
/// (dễ đoán). `autoDispose` khiến provider bị huỷ khi rời màn quiz, nên
/// lần vào sau tính lại từ đầu — random mới mỗi lần học.
final lessonQuizQuestionsProvider = Provider.autoDispose
    .family<AsyncValue<List<QuizQuestion>>, String>((ref, lessonId) {
  final itemsAsync = ref.watch(lessonItemsProvider(lessonId));
  return itemsAsync.whenData((items) => _quizGenerator.generate(pool: items));
});

/// 1 trong 3 mảng nội dung có thể quiz riêng theo trình độ — người dùng chọn
/// đúng 1 mảng trước khi vào quiz (xem `quiz_category_screen.dart`), không
/// còn gộp chung Vocabulary+Kanji+Grammar vào 1 bài như trước.
enum QuizCategory { vocabulary, kanji, grammar }

extension QuizCategoryLabel on QuizCategory {
  String get label => switch (this) {
        QuizCategory.vocabulary => 'Từ vựng',
        QuizCategory.kanji => 'Kanji',
        QuizCategory.grammar => 'Ngữ pháp',
      };

  /// Khớp giá trị dùng trong path `/quiz/:category` — xem app_router.dart.
  String get routeSegment => name;

  static QuizCategory? fromRouteSegment(String segment) {
    for (final c in QuizCategory.values) {
      if (c.routeSegment == segment) return c;
    }
    return null;
  }
}

/// Quiz theo 1 mảng nội dung riêng (Từ vựng/Kanji/Ngữ pháp) của trình độ
/// hiện tại (currentLevelIdProvider) — thay cho quiz gộp chung cũ.
/// `autoDispose` — xem giải thích ở [lessonQuizQuestionsProvider].
final levelCategoryQuizQuestionsProvider = Provider.autoDispose
    .family<AsyncValue<List<QuizQuestion>>, QuizCategory>((ref, category) {
  switch (category) {
    case QuizCategory.vocabulary:
      final vocab = ref.watch(vocabularyListProvider);
      return vocab.whenData(
        (items) => _quizGenerator.generate(
          pool: [for (final v in items) LessonContentItem.vocabulary(v)],
          questionCount: 15,
        ),
      );
    case QuizCategory.kanji:
      final kanji = ref.watch(kanjiListProvider);
      return kanji.whenData(
        (items) => _quizGenerator.generate(
          pool: [for (final k in items) LessonContentItem.kanji(k)],
          questionCount: 15,
        ),
      );
    case QuizCategory.grammar:
      final grammar = ref.watch(grammarListProvider);
      return grammar.whenData(
        (items) => _quizGenerator.generate(
          pool: [for (final g in items) LessonContentItem.grammar(g)],
          questionCount: 15,
        ),
      );
  }
});

/// Quiz nghe hiểu theo trình độ hiện tại — kiểu đề nghe JLPT thật, trộn nhiều
/// thể loại khác nhau (hội thoại hỏi chi tiết / hội thoại "làm gì trước-tiếp
/// theo" / độc thoại-thông báo / câu ngắn chọn phản hồi phù hợp — xem
/// `seed_listening_n5.sql` + `seed_listening_n5_more.sql`) để đỡ lặp lại
/// đúng 1 kiểu. Mỗi lần vào chọn ngẫu nhiên 1 tập con trong toàn bộ pool nên
/// thể loại/độ dài/thứ tự khác nhau mỗi lượt học. `autoDispose` — xem giải
/// thích ở [lessonQuizQuestionsProvider].
final levelListeningQuestionsProvider =
    Provider.autoDispose<AsyncValue<List<QuizQuestion>>>((ref) {
  final levelId = ref.watch(currentLevelIdProvider);
  if (levelId == null) return const AsyncValue.loading();

  final dialoguesAsync = ref.watch(listeningDialoguesForLevelProvider(levelId));
  return dialoguesAsync.whenData(
    (dialogues) =>
        _dialogueGenerator.generate(dialogues: dialogues, questionCount: 12),
  );
});
