import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nihongo/data/repositories/content_repository_provider.dart';
import 'package:nihongo/domain/entities/jlpt_level.dart';
import 'package:nihongo/domain/entities/lesson.dart';
import 'package:nihongo/domain/repositories/content_repository.dart';
import 'package:nihongo/features/lesson/lesson_list_screen.dart';
import 'package:nihongo/features/lesson/providers/content_providers.dart';
import 'package:nihongo/features/lesson/providers/content_state.dart';
import 'package:nihongo/features/lesson/providers/level_providers.dart';
import 'package:nihongo/shared/skeleton_layouts.dart';
import 'package:nihongo/shared/state_views.dart';

const _levels = [
  JlptLevel(id: 'l5', code: 'N5', title: 'N5', orderIndex: 0),
];

const _lessonA = Lesson(id: 'a', title: '第1課', levelId: 'l5', orderIndex: 1);
const _lessonB = Lesson(id: 'b', title: '第2課', levelId: 'l5', orderIndex: 2);

/// Repository giả: đếm số lần gọi `refreshFromRemote` (đường "kéo để làm
/// mới"), không chạm Supabase/Drift.
class _FakeRepo extends Fake implements ContentRepository {
  int refreshCalls = 0;
  Completer<void>? hold;
  Object? failWith;

  @override
  Future<void> refreshFromRemote(String levelId, {bool coreN5Only = false}) {
    refreshCalls++;
    final error = failWith;
    if (error != null) return Future<void>.error(error);
    return hold?.future ?? Future<void>.value();
  }
}

/// Điều khiển từng nguồn trạng thái của màn hình.
class _Harness {
  final lessons = StreamController<List<Lesson>>();
  final repo = _FakeRepo();

  /// Mỗi lần `contentRefreshProvider` (đồng bộ nền) chạy lại, lấy 1 kết quả
  /// tiếp theo từ đây (hết thì dùng phần tử cuối).
  final syncOutcomes = <Future<void> Function()>[];
  int syncRuns = 0;

  Future<List<JlptLevel>> Function() levels = () async => _levels;
  int levelRuns = 0;

  Future<void> pump(
    WidgetTester tester, {
    bool reduceMotion = false,
    Brightness brightness = Brightness.light,
  }) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    addTearDown(lessons.close);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          jlptLevelsProvider.overrideWith((ref) {
            levelRuns++;
            return levels();
          }),
          contentRefreshProvider.overrideWith((ref) {
            final i = syncRuns++;
            return syncOutcomes[
                i < syncOutcomes.length ? i : syncOutcomes.length - 1]();
          }),
          lessonsProvider.overrideWith((ref) => lessons.stream),
          contentRepositoryProvider.overrideWithValue(repo),
        ],
        child: MaterialApp(
          theme: ThemeData(brightness: brightness),
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(disableAnimations: reduceMotion),
            child: child!,
          ),
          home: const LessonListScreen(),
        ),
      ),
    );
    await tester.pump();
  }
}

Future<void> _ok() async {}

final _emptyTitle = find.text('Chưa có bài học nào cho N5');
final _skeleton = find.byType(LessonListSkeleton);
final _errorState = find.byType(ErrorState);

Future<void> _pull(WidgetTester tester) async {
  await tester.drag(find.byType(Scrollable).first, const Offset(0, 400));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 600));
}

void main() {
  group('Loading ≠ Empty ≠ Error', () {
    testWidgets('đang đồng bộ lần đầu: skeleton, KHÔNG rỗng/lỗi',
        (tester) async {
      final h = _Harness()..syncOutcomes.add(() => Completer<void>().future);
      await h.pump(tester);
      expect(_skeleton, findsOneWidget);
      expect(_emptyTitle, findsNothing);
      expect(_errorState, findsNothing);
    });

    testWidgets(
        'Drift phát danh sách rỗng NHƯNG đồng bộ chưa xong → vẫn là loading, '
        'không báo "chưa có bài học"', (tester) async {
      final c = Completer<void>();
      final h = _Harness()..syncOutcomes.add(() => c.future);
      await h.pump(tester);
      h.lessons.add([]);
      await tester.pump();
      await tester.pump();
      expect(_skeleton, findsOneWidget);
      expect(_emptyTitle, findsNothing);

      // Đồng bộ xong thành công mà vẫn rỗng → mới là rỗng thật.
      c.complete();
      await tester.pump();
      await tester.pump();
      expect(_emptyTitle, findsOneWidget);
      expect(_skeleton, findsNothing);
      expect(_errorState, findsNothing);
    });

    testWidgets(
        'đồng bộ lỗi + cache rỗng: hiện lỗi (không phải rỗng), không '
        'lộ exception', (tester) async {
      final h = _Harness()
        ..syncOutcomes.add(() => Future.error(Exception('SocketException: x')));
      await h.pump(tester);
      h.lessons.add([]);
      await tester.pump();
      await tester.pump();
      expect(_errorState, findsOneWidget);
      expect(_emptyTitle, findsNothing);
      expect(find.textContaining('Exception'), findsNothing);
      expect(find.textContaining('Không kết nối được máy chủ'), findsOneWidget);
      expect(find.text('Thử lại'), findsOneWidget);
    });

    testWidgets(
        'không tra được cấp độ (mất mạng khi mở app): hiện lỗi chứ '
        'không quay mãi', (tester) async {
      final h = _Harness()
        ..syncOutcomes.add(_ok)
        ..levels = () => Future.error(Exception('Failed host lookup'));
      await h.pump(tester);
      await tester.pump();
      expect(_errorState, findsOneWidget);
      expect(_skeleton, findsNothing);
    });

    testWidgets(
        'có dữ liệu cache + đồng bộ lỗi: vẫn hiện danh sách cũ, không '
        'lỗi toàn màn hình', (tester) async {
      final h = _Harness()
        ..syncOutcomes.add(() => Future.error(Exception('mất mạng')));
      await h.pump(tester);
      h.lessons.add([_lessonA, _lessonB]);
      await tester.pump();
      await tester.pump();
      expect(find.text('第1課'), findsOneWidget);
      expect(find.text('第2課'), findsOneWidget);
      expect(_errorState, findsNothing);
      expect(_emptyTitle, findsNothing);
    });

    testWidgets(
        'đang đồng bộ nhưng đã có cache: hiện cache ngay, không '
        'skeleton', (tester) async {
      final h = _Harness()..syncOutcomes.add(() => Completer<void>().future);
      await h.pump(tester);
      h.lessons.add([_lessonA]);
      await tester.pump();
      await tester.pump();
      expect(find.text('第1課'), findsOneWidget);
      expect(_skeleton, findsNothing);
    });
  });

  group('Retry', () {
    testWidgets(
        'Thử lại chạy lại đúng đồng bộ nền 1 lần, rồi hiện dữ liệu '
        'thật', (tester) async {
      final h = _Harness()
        ..syncOutcomes.addAll([
          () => Future.error(Exception('Connection failed')),
          _ok,
        ]);
      await h.pump(tester);
      h.lessons.add([]);
      await tester.pump();
      await tester.pump();
      expect(h.syncRuns, 1);
      expect(_errorState, findsOneWidget);

      await tester.tap(find.text('Thử lại'));
      await tester.pump();
      // Đang thử lại: loading, không còn nút để bấm chồng.
      expect(_skeleton, findsOneWidget);
      expect(find.text('Thử lại'), findsNothing);

      h.lessons.add([_lessonA]);
      await tester.pump();
      await tester.pump();
      expect(h.syncRuns, 2);
      expect(find.text('第1課'), findsOneWidget);
      expect(_errorState, findsNothing);
    });

    testWidgets('bấm Thử lại hai lần liền chỉ tải 1 lần', (tester) async {
      final retry = Completer<void>();
      final h = _Harness()
        ..syncOutcomes.addAll([
          () => Future.error(Exception('Connection failed')),
          () => retry.future,
        ]);
      await h.pump(tester);
      h.lessons.add([]);
      await tester.pump();
      await tester.pump();

      final button = find.text('Thử lại');
      await tester.tap(button);
      await tester.tap(button, warnIfMissed: false);
      await tester.pump();
      await tester.pump();
      expect(h.syncRuns, 2); // 1 lần ban đầu + đúng 1 lần retry
      retry.complete();
      await tester.pump();
    });

    testWidgets('retry thất bại: vẫn là lỗi rõ ràng, còn nút Thử lại',
        (tester) async {
      final h = _Harness()
        ..syncOutcomes.addAll([
          () => Future.error(Exception('Connection failed')),
          () => Future.error(Exception('Connection failed again')),
        ]);
      await h.pump(tester);
      h.lessons.add([]);
      await tester.pump();
      await tester.pump();
      await tester.tap(find.text('Thử lại'));
      await tester.pump();
      await tester.pump();
      expect(_errorState, findsOneWidget);
      expect(find.text('Thử lại'), findsOneWidget);
      expect(_skeleton, findsNothing);
    });

    testWidgets('lỗi tra cấp độ → Thử lại tra lại cấp độ', (tester) async {
      final h = _Harness()..syncOutcomes.add(_ok);
      var fail = true;
      h.levels = () async {
        if (fail) throw Exception('Failed host lookup');
        return _levels;
      };
      await h.pump(tester);
      await tester.pump();
      expect(_errorState, findsOneWidget);
      fail = false;
      await tester.tap(find.text('Thử lại'));
      await tester.pump();
      await tester.pump();
      h.lessons.add([_lessonA]);
      await tester.pump();
      await tester.pump();
      expect(h.levelRuns, 2);
      expect(find.text('第1課'), findsOneWidget);
    });
  });

  group('Kéo để làm mới', () {
    testWidgets(
        'kéo gọi refreshFromRemote đúng 1 lần, chờ xong mới dừng; '
        'danh sách giữ nguyên', (tester) async {
      final h = _Harness()..syncOutcomes.add(_ok);
      await h.pump(tester);
      h.lessons.add([_lessonA, _lessonB]);
      await tester.pump();
      await tester.pump();

      final hold = h.repo.hold = Completer<void>();
      await tester.drag(find.byType(Scrollable).first, const Offset(0, 400));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(h.repo.refreshCalls, 1);
      // Đang làm mới: vẫn thấy danh sách, có indicator, không skeleton.
      expect(find.text('第1課'), findsOneWidget);
      expect(_skeleton, findsNothing);
      expect(find.byType(RefreshProgressIndicator), findsOneWidget);

      hold.complete();
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      expect(find.byType(RefreshProgressIndicator), findsNothing);
      expect(find.text('第1課'), findsOneWidget);
      expect(find.text('第2課'), findsOneWidget);
    });

    testWidgets('kéo liên tiếp khi đang làm mới không gửi request thứ hai',
        (tester) async {
      final h = _Harness()..syncOutcomes.add(_ok);
      await h.pump(tester);
      h.lessons.add([_lessonA]);
      await tester.pump();
      await tester.pump();

      final hold = h.repo.hold = Completer<void>();
      await _pull(tester);
      await _pull(tester);
      await _pull(tester);
      expect(h.repo.refreshCalls, 1);
      hold.complete();
      await tester.pumpAndSettle(); // indicator đóng hẳn
      // Hết request thì lần kéo sau là request mới.
      h.repo.hold = null;
      await _pull(tester);
      await tester.pumpAndSettle();
      expect(h.repo.refreshCalls, 2);
    });

    testWidgets(
        'đang đồng bộ nền thì kéo dùng lại request đó, không gửi '
        'thêm', (tester) async {
      final auto = Completer<void>();
      final h = _Harness()..syncOutcomes.add(() => auto.future);
      await h.pump(tester);
      h.lessons.add([_lessonA]);
      await tester.pump();
      await tester.pump();
      await _pull(tester);
      expect(h.repo.refreshCalls, 0);
      auto.complete();
      await tester.pump(const Duration(seconds: 1));
      expect(h.repo.refreshCalls, 0);
    });

    testWidgets(
        'làm mới lỗi: indicator dừng, giữ danh sách cũ, báo bằng '
        'SnackBar, không xoá cache', (tester) async {
      final h = _Harness()..syncOutcomes.add(_ok);
      await h.pump(tester);
      h.lessons.add([_lessonA, _lessonB]);
      await tester.pump();
      await tester.pump();

      h.repo.failWith = Exception('SocketException');
      await _pull(tester);
      await tester.pump(const Duration(seconds: 1));
      expect(h.repo.refreshCalls, 1);
      expect(find.byType(RefreshProgressIndicator), findsNothing);
      expect(find.text('第1課'), findsOneWidget);
      expect(find.text('第2課'), findsOneWidget);
      expect(_errorState, findsNothing);
      expect(_emptyTitle, findsNothing);
      expect(find.textContaining('Không làm mới được'), findsOneWidget);
      expect(find.textContaining('Exception'), findsNothing);
    });

    testWidgets(
        'danh sách rỗng thật vẫn kéo làm mới được; có dữ liệu thì '
        'biến mất rỗng, không nhân đôi mục', (tester) async {
      final h = _Harness()..syncOutcomes.add(_ok);
      await h.pump(tester);
      h.lessons.add([]);
      await tester.pump();
      await tester.pump();
      expect(_emptyTitle, findsOneWidget);

      await _pull(tester);
      expect(h.repo.refreshCalls, 1);
      // Sau làm mới, Drift phát dữ liệu (repo thật ghi DB → stream phát).
      h.lessons.add([_lessonA, _lessonB]);
      await tester.pump();
      await tester.pump();
      expect(_emptyTitle, findsNothing);
      expect(find.text('第1課'), findsOneWidget);

      // Nhiều lần làm mới nữa với cùng dữ liệu: không nhân đôi.
      for (var i = 0; i < 3; i++) {
        await _pull(tester);
        await tester.pump(const Duration(seconds: 1));
        h.lessons.add([_lessonA, _lessonB]);
        await tester.pump();
        await tester.pump();
      }
      expect(find.text('第1課'), findsOneWidget);
      expect(find.text('第2課'), findsOneWidget);
    });
  });

  group('ContentRefresher (nút làm mới + kéo dùng chung)', () {
    ProviderContainer make(_FakeRepo repo, Future<void> Function() sync) {
      final c = ProviderContainer(
        overrides: [
          jlptLevelsProvider.overrideWith((ref) async => _levels),
          contentRefreshProvider.overrideWith((ref) => sync()),
          contentRepositoryProvider.overrideWithValue(repo),
        ],
      );
      addTearDown(c.dispose);
      return c;
    }

    test('gọi đồng thời nhiều lần chỉ gửi 1 request, dùng chung kết quả',
        () async {
      final repo = _FakeRepo()..hold = Completer<void>();
      final c = make(repo, _ok);
      await c.read(jlptLevelsProvider.future);
      await c.read(contentRefreshProvider.future);

      final a = c.read(contentRefresherProvider).refresh();
      final b = c.read(contentRefresherProvider).refresh();
      final d = c.read(contentRefresherProvider).refresh();
      expect(repo.refreshCalls, 1);
      repo.hold!.complete();
      await Future.wait<void>([a, b, d]);

      // Xong rồi thì lần sau là request mới.
      repo.hold = null;
      await c.read(contentRefresherProvider).refresh();
      expect(repo.refreshCalls, 2);
    });

    test('lỗi: ném cho người gọi, cờ chạy được giải phóng để thử lại',
        () async {
      final repo = _FakeRepo()..failWith = Exception('Connection failed');
      final c = make(repo, _ok);
      await c.read(jlptLevelsProvider.future);
      await c.read(contentRefreshProvider.future);

      await expectLater(
        c.read(contentRefresherProvider).refresh(),
        throwsException,
      );
      repo.failWith = null;
      await c.read(contentRefresherProvider).refresh();
      expect(repo.refreshCalls, 2);
    });

    test('đồng bộ nền đang chạy: dùng lại, không gọi repository thêm',
        () async {
      final auto = Completer<void>();
      final repo = _FakeRepo();
      final c = make(repo, () => auto.future);
      await c.read(jlptLevelsProvider.future);
      c.read(contentRefreshProvider); // khởi động đồng bộ nền

      final f = c.read(contentRefresherProvider).refresh();
      expect(repo.refreshCalls, 0);
      auto.complete();
      await f;
      expect(repo.refreshCalls, 0);
    });

    test('chưa biết cấp độ: không làm gì, không lỗi', () async {
      final repo = _FakeRepo();
      final c = ProviderContainer(
        overrides: [
          jlptLevelsProvider
              .overrideWith((ref) => Completer<List<JlptLevel>>().future),
          contentRefreshProvider.overrideWith((ref) async {}),
          contentRepositoryProvider.overrideWithValue(repo),
        ],
      );
      addTearDown(c.dispose);
      await c.read(contentRefreshProvider.future);
      await c.read(contentRefresherProvider).refresh();
      expect(repo.refreshCalls, 0);
    });
  });

  group('Theme / reduced motion', () {
    for (final reduce in [false, true]) {
      for (final b in Brightness.values) {
        testWidgets('rỗng/lỗi/kéo hoạt động (reduceMotion=$reduce, $b)',
            (tester) async {
          final h = _Harness()
            ..syncOutcomes.addAll([
              () => Future.error(Exception('Connection failed')),
              _ok,
            ]);
          await h.pump(tester, reduceMotion: reduce, brightness: b);
          h.lessons.add([]);
          await tester.pump();
          await tester.pump();
          expect(_errorState, findsOneWidget);

          await tester.tap(find.text('Thử lại'));
          await tester.pump();
          await tester.pump();
          h.lessons.add([]);
          await tester.pump();
          await tester.pump();
          expect(_emptyTitle, findsOneWidget);

          await _pull(tester);
          expect(h.repo.refreshCalls, 1);
          await tester.pump(const Duration(seconds: 1));
        });
      }
    }
  });

  group('Tin nhắn lỗi thân thiện', () {
    test('mất mạng và lỗi chung được phân biệt, không lộ chi tiết', () {
      expect(
        loadErrorMessage(Exception('SocketException: Failed host lookup')),
        contains('mạng'),
      );
      final generic = loadErrorMessage(StateError('boom: secret stack'));
      expect(generic, isNot(contains('boom')));
      expect(generic, contains('Vui lòng thử lại'));
    });
  });
}
