import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nihongo/data/repositories/content_repository_provider.dart';
import 'package:nihongo/domain/entities/grammar_point.dart';
import 'package:nihongo/domain/entities/jlpt_level.dart';
import 'package:nihongo/domain/entities/kanji.dart';
import 'package:nihongo/domain/entities/lesson.dart';
import 'package:nihongo/domain/entities/vocabulary.dart';
import 'package:nihongo/domain/repositories/content_repository.dart';
import 'package:nihongo/features/grammar/grammar_home_screen.dart';
import 'package:nihongo/features/grammar/grammar_list_screen.dart';
import 'package:nihongo/features/kanji/kanji_home_screen.dart';
import 'package:nihongo/features/kanji/kanji_list_screen.dart';
import 'package:nihongo/features/lesson/it_learning_hub.dart';
import 'package:nihongo/features/lesson/providers/content_providers.dart';
import 'package:nihongo/features/lesson/providers/level_providers.dart';
import 'package:nihongo/features/vocabulary/vocabulary_home_screen.dart';
import 'package:nihongo/features/vocabulary/vocabulary_list_screen.dart';
import 'package:nihongo/shared/state_views.dart';

const _levels = [
  JlptLevel(id: 'l5', code: 'N5', title: 'N5', orderIndex: 0),
  JlptLevel(id: 'lit', code: 'IT', title: 'IT', orderIndex: 9),
];

class _FakeRepo extends Fake implements ContentRepository {
  int refreshCalls = 0;
  Object? failWith;

  @override
  Future<void> refreshFromRemote(String levelId, {bool coreN5Only = false}) {
    refreshCalls++;
    final e = failWith;
    return e == null ? Future<void>.value() : Future<void>.error(e);
  }
}

/// Mỗi màn: (tên, widget, provider danh sách, cấp độ, chữ trong tiêu đề rỗng).
typedef _Case = ({
  String name,
  Widget screen,
  Override Function(Stream<void> emptyList) override,
  String level,
  String emptyTitle,
});

final _cases = <_Case>[
  (
    name: 'Từ vựng (danh sách)',
    screen: const VocabularyListScreen(),
    override: (s) => vocabularyListProvider
        .overrideWith((ref) => s.map((_) => <Vocabulary>[])),
    level: 'N5',
    emptyTitle: 'Chưa có từ vựng nào cho N5',
  ),
  (
    name: 'Từ vựng (home)',
    screen: const VocabularyHomeScreen(),
    override: (s) => vocabularyListProvider
        .overrideWith((ref) => s.map((_) => <Vocabulary>[])),
    level: 'N5',
    emptyTitle: 'Chưa có từ vựng nào cho N5',
  ),
  (
    name: 'Kanji (danh sách)',
    screen: const KanjiListScreen(),
    override: (s) =>
        kanjiListProvider.overrideWith((ref) => s.map((_) => <Kanji>[])),
    level: 'N5',
    emptyTitle: 'Chưa có kanji nào cho N5',
  ),
  (
    name: 'Kanji (home)',
    screen: const KanjiHomeScreen(),
    override: (s) =>
        kanjiListProvider.overrideWith((ref) => s.map((_) => <Kanji>[])),
    level: 'N5',
    emptyTitle: 'Chưa có Kanji nào cho N5',
  ),
  (
    name: 'Ngữ pháp (danh sách)',
    screen: const GrammarListScreen(),
    override: (s) => grammarListProvider
        .overrideWith((ref) => s.map((_) => <GrammarPoint>[])),
    level: 'N5',
    emptyTitle: 'Chưa có ngữ pháp nào cho N5',
  ),
  (
    name: 'Ngữ pháp (home)',
    screen: const GrammarHomeScreen(),
    override: (s) => grammarListProvider
        .overrideWith((ref) => s.map((_) => <GrammarPoint>[])),
    level: 'N5',
    emptyTitle: 'Chưa có ngữ pháp nào cho N5',
  ),
  (
    name: 'Lộ trình IT',
    screen: const ItLearningHub(),
    override: (s) =>
        lessonsProvider.overrideWith((ref) => s.map((_) => <Lesson>[])),
    level: 'IT',
    emptyTitle: 'Chưa có nội dung bài học',
  ),
];

Future<(_FakeRepo, StreamController<void>, int Function())> _open(
  WidgetTester tester,
  _Case c, {
  required Future<void> Function() sync,
}) async {
  tester.view.physicalSize = const Size(1170, 2532);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  final repo = _FakeRepo();
  final stream = StreamController<void>();
  addTearDown(stream.close);
  var runs = 0;
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        jlptLevelsProvider.overrideWith((ref) async => _levels),
        selectedLevelCodeProvider.overrideWith((ref) => c.level),
        contentRefreshProvider.overrideWith((ref) {
          runs++;
          return sync();
        }),
        c.override(stream.stream),
        // Các luồng phụ của màn hình: rỗng, không chạm Drift.
        grammarLessonAssignmentsProvider
            .overrideWith((ref) => const Stream.empty()),
        vocabularyLessonAssignmentsProvider
            .overrideWith((ref) => const Stream.empty()),
        kanjiLessonAssignmentsProvider
            .overrideWith((ref) => const Stream.empty()),
        contentRepositoryProvider.overrideWithValue(repo),
      ],
      child: MaterialApp(home: c.screen),
    ),
  );
  await tester.pump();
  await tester.pump();
  return (repo, stream, () => runs);
}

void main() {
  for (final c in _cases) {
    group(c.name, () {
      testWidgets('đang đồng bộ + Drift rỗng: không báo rỗng, không báo lỗi',
          (tester) async {
        final (_, stream, _) = await _open(
          tester,
          c,
          sync: () => Completer<void>().future,
        );
        stream.add(null);
        await tester.pump();
        await tester.pump();
        expect(find.text(c.emptyTitle), findsNothing);
        expect(find.byType(ErrorState), findsNothing);
      });

      testWidgets('đồng bộ xong, thật sự rỗng: hiện trạng thái rỗng',
          (tester) async {
        final (_, stream, _) = await _open(tester, c, sync: () async {});
        stream.add(null);
        await tester.pump();
        await tester.pump();
        expect(find.text(c.emptyTitle), findsOneWidget);
        expect(find.byType(ErrorState), findsNothing);
      });

      testWidgets(
          'đồng bộ lỗi + cache rỗng: lỗi có Thử lại, retry chạy lại '
          'đồng bộ', (tester) async {
        var calls = 0;
        final (_, stream, runs) = await _open(
          tester,
          c,
          sync: () => ++calls == 1
              ? Future<void>.error(Exception('Connection failed'))
              : Future<void>.value(),
        );
        stream.add(null);
        await tester.pump();
        await tester.pump();
        expect(find.byType(ErrorState), findsOneWidget);
        expect(find.text(c.emptyTitle), findsNothing);
        expect(find.textContaining('Exception'), findsNothing);

        await tester.tap(find.text('Thử lại'));
        await tester.pump();
        await tester.pump();
        expect(runs(), 2);
        stream.add(null);
        await tester.pump();
        await tester.pump();
        expect(find.byType(ErrorState), findsNothing);
        expect(find.text(c.emptyTitle), findsOneWidget);
      });

      testWidgets('trạng thái rỗng kéo để làm mới được', (tester) async {
        final (repo, stream, _) = await _open(tester, c, sync: () async {});
        stream.add(null);
        await tester.pump();
        await tester.pump();
        await tester.drag(
          find.descendant(
            of: find.byType(EmptyState),
            matching: find.byType(Scrollable),
          ),
          const Offset(0, 400),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 600));
        expect(repo.refreshCalls, 1);
        await tester.pumpAndSettle();
      });
    });
  }

  // Giữ import entity dùng cho kiểu của provider (tránh cảnh báo unused).
  test('kiểu dữ liệu của các provider danh sách', () {
    expect(const <Vocabulary>[], isEmpty);
    expect(const <Kanji>[], isEmpty);
    expect(const <GrammarPoint>[], isEmpty);
    expect(const <Lesson>[], isEmpty);
  });
}
