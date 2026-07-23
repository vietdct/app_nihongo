import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/repositories/content_repository_provider.dart';
import '../../../domain/entities/kanji.dart';
import '../../../domain/entities/lesson.dart';
import '../../../domain/entities/vocabulary.dart';
import 'level_providers.dart';

/// Kích hoạt refresh từ Supabase một lần khi mở app (không chặn UI —
/// watchLessons/watchAllVocabulary/watchAllKanji đọc Drift ngay lập tức,
/// provider này chỉ âm thầm làm mới cache nền).
final contentRefreshProvider = FutureProvider<void>((ref) async {
  final levelId = await ref.watch(currentLevelIdProvider.future);
  final repo = ref.watch(contentRepositoryProvider);
  await repo.refreshFromRemote(levelId);
});

final lessonsProvider = StreamProvider<List<Lesson>>((ref) async* {
  ref.watch(contentRefreshProvider); // trigger refresh nền, không đợi kết quả
  final levelId = await ref.watch(currentLevelIdProvider.future);
  yield* ref.watch(contentRepositoryProvider).watchLessons(levelId);
});

final vocabularyListProvider = StreamProvider<List<Vocabulary>>((ref) {
  ref.watch(contentRefreshProvider);
  return ref.watch(contentRepositoryProvider).watchAllVocabulary();
});

final kanjiListProvider = StreamProvider<List<Kanji>>((ref) {
  ref.watch(contentRefreshProvider);
  return ref.watch(contentRepositoryProvider).watchAllKanji();
});

final lessonItemsProvider = StreamProvider.family<List<LessonContentItem>, String>((ref, lessonId) {
  return ref.watch(contentRepositoryProvider).watchLessonItems(lessonId);
});
