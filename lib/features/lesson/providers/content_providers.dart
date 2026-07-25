import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/repositories/content_repository_provider.dart';
import '../../../domain/entities/grammar_point.dart';
import '../../../domain/entities/kanji.dart';
import '../../../domain/entities/lesson.dart';
import '../../../domain/entities/vocabulary.dart';
import 'level_providers.dart';

/// Kích hoạt refresh từ Supabase mỗi khi đổi cấp độ (không chặn UI —
/// watchLessons/watchVocabulary/watchKanji đọc Drift ngay lập tức,
/// provider này chỉ âm thầm làm mới cache nền cho cấp độ đang chọn).
final contentRefreshProvider = FutureProvider<void>((ref) async {
  final levelId = ref.watch(currentLevelIdProvider);
  if (levelId == null) return;
  final repo = ref.watch(contentRepositoryProvider);
  await repo.refreshFromRemote(levelId);
});

final lessonsProvider = StreamProvider<List<Lesson>>((ref) {
  ref.watch(contentRefreshProvider); // trigger refresh nền, không đợi kết quả
  final levelId = ref.watch(currentLevelIdProvider);
  if (levelId == null) return const Stream.empty();
  return ref.watch(contentRepositoryProvider).watchLessons(levelId);
});

final vocabularyListProvider = StreamProvider<List<Vocabulary>>((ref) {
  ref.watch(contentRefreshProvider);
  final levelId = ref.watch(currentLevelIdProvider);
  if (levelId == null) return const Stream.empty();
  return ref.watch(contentRepositoryProvider).watchVocabulary(levelId);
});

final kanjiListProvider = StreamProvider<List<Kanji>>((ref) {
  ref.watch(contentRefreshProvider);
  final levelId = ref.watch(currentLevelIdProvider);
  if (levelId == null) return const Stream.empty();
  return ref.watch(contentRepositoryProvider).watchKanji(levelId);
});

final grammarListProvider = StreamProvider<List<GrammarPoint>>((ref) {
  ref.watch(contentRefreshProvider);
  final levelId = ref.watch(currentLevelIdProvider);
  if (levelId == null) return const Stream.empty();
  return ref.watch(contentRepositoryProvider).watchGrammar(levelId);
});

final grammarLessonAssignmentsProvider = StreamProvider<Map<String, LessonAssignment>>((ref) {
  final levelId = ref.watch(currentLevelIdProvider);
  if (levelId == null) return const Stream.empty();
  return ref.watch(contentRepositoryProvider).watchGrammarLessonAssignments(levelId);
});

final lessonItemsProvider = StreamProvider.family<List<LessonContentItem>, String>((ref, lessonId) {
  return ref.watch(contentRepositoryProvider).watchLessonItems(lessonId);
});

final vocabularyLessonAssignmentsProvider = StreamProvider<Map<String, LessonAssignment>>((ref) {
  final levelId = ref.watch(currentLevelIdProvider);
  if (levelId == null) return const Stream.empty();
  return ref.watch(contentRepositoryProvider).watchVocabularyLessonAssignments(levelId);
});

final kanjiLessonAssignmentsProvider = StreamProvider<Map<String, LessonAssignment>>((ref) {
  final levelId = ref.watch(currentLevelIdProvider);
  if (levelId == null) return const Stream.empty();
  return ref.watch(contentRepositoryProvider).watchKanjiLessonAssignments(levelId);
});
