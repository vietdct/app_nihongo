import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:nihongo/core/router/page_transitions.dart';
import 'package:nihongo/core/theme/app_theme.dart';

GoRouter _router({String initial = '/'}) => GoRouter(
      initialLocation: initial,
      routes: [
        GoRoute(
          path: '/',
          builder: (context, _) => Scaffold(
            body: Center(
              child: TextButton(
                onPressed: () => context.push('/detail/7?tab=2', extra: 'EX'),
                child: const Text('mở'),
              ),
            ),
          ),
        ),
        GoRoute(
          path: '/detail/:id',
          builder: (context, state) => Scaffold(
            appBar: AppBar(title: const Text('chi tiết')),
            body: Text(
              'id=${state.pathParameters['id']} '
              'tab=${state.uri.queryParameters['tab']} '
              'extra=${state.extra}',
            ),
          ),
        ),
      ],
    );

Future<void> _pump(
  WidgetTester tester,
  GoRouter router, {
  bool reduceMotion = false,
  TargetPlatform platform = TargetPlatform.iOS,
}) async {
  await tester.pumpWidget(
    MaterialApp.router(
      theme: AppTheme.light().copyWith(platform: platform),
      routerConfig: router,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(disableAnimations: reduceMotion),
        child: child!,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Finder get _cupertinoSlide => find.byType(CupertinoPageTransition);

void main() {
  testWidgets(
      'iOS, chuyển động bình thường: trượt Cupertino + vuốt cạnh trái '
      'quay lại', (tester) async {
    final router = _router();
    await _pump(tester, router);

    await tester.tap(find.text('mở'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(_cupertinoSlide, findsWidgets);
    // Đang trượt vào: mép trái màn mới còn lệch phải.
    expect(tester.getTopLeft(find.byType(AppBar)).dx, greaterThan(0));
    await tester.pumpAndSettle();
    expect(find.textContaining('id=7 tab=2 extra=EX'), findsOneWidget);

    // Vuốt từ mép trái.
    await tester.dragFrom(const Offset(2, 300), const Offset(400, 0));
    await tester.pumpAndSettle();
    expect(find.text('mở'), findsOneWidget);
    expect(find.textContaining('id=7'), findsNothing);
  });

  testWidgets(
      'iOS, giảm chuyển động: chỉ mờ (không trượt), vuốt-back và nút '
      'Back vẫn hoạt động', (tester) async {
    final router = _router();
    await _pump(tester, router, reduceMotion: true);

    await tester.tap(find.text('mở'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    // Màn mới có FadeTransition của builder và không trượt.
    final fade = tester.widget<FadeTransition>(
      find
          .ancestor(
            of: find.textContaining('id=7'),
            matching: find.byType(FadeTransition),
          )
          .first,
    );
    expect(fade.opacity.value, inInclusiveRange(0, 1));
    // Không bị dịch ngang: mép trái màn mới nằm đúng x=0 ngay giữa chuyển động.
    expect(tester.getTopLeft(find.byType(AppBar)).dx, 0);
    await tester.pumpAndSettle();
    expect(find.textContaining('id=7 tab=2 extra=EX'), findsOneWidget);

    // Vuốt cạnh trái vẫn pop được.
    await tester.dragFrom(const Offset(2, 300), const Offset(400, 0));
    await tester.pumpAndSettle();
    expect(find.text('mở'), findsOneWidget);

    // Và nút Back (pop bằng code) cũng vẫn chạy.
    await tester.tap(find.text('mở'));
    await tester.pumpAndSettle();
    router.pop();
    await tester.pumpAndSettle();
    expect(find.text('mở'), findsOneWidget);
  });

  testWidgets('mở thẳng deep link: path/query param đúng, không cần màn cha',
      (tester) async {
    final router = _router(initial: '/detail/42?tab=5');
    await _pump(tester, router);
    expect(find.textContaining('id=42 tab=5 extra=null'), findsOneWidget);
  });

  testWidgets(
      'đẩy liên tiếp nhiều màn rồi pop ngược về, không còn controller '
      'chạy', (tester) async {
    final router = _router();
    await _pump(tester, router, reduceMotion: true);
    for (var i = 0; i < 3; i++) {
      router.push('/detail/$i');
      await tester.pumpAndSettle();
    }
    expect(find.textContaining('id=2'), findsOneWidget);
    for (var i = 0; i < 3; i++) {
      router.pop();
      await tester.pumpAndSettle();
    }
    expect(find.text('mở'), findsOneWidget);
    expect(tester.hasRunningAnimations, isFalse);
  });

  testWidgets('bottom sheet và dialog vẫn mở/đóng đúng với theme mới',
      (tester) async {
    final router = _router();
    await _pump(tester, router, reduceMotion: true);
    final ctx = tester.element(find.text('mở'));

    showModalBottomSheet<void>(
      context: ctx,
      builder: (_) => const SizedBox(height: 120, child: Text('sheet')),
    );
    await tester.pumpAndSettle();
    expect(find.text('sheet'), findsOneWidget);
    Navigator.of(ctx).pop();
    await tester.pumpAndSettle();
    expect(find.text('sheet'), findsNothing);

    showDialog<void>(
      context: ctx,
      builder: (_) => const AlertDialog(content: Text('hộp thoại')),
    );
    await tester.pumpAndSettle();
    expect(find.text('hộp thoại'), findsOneWidget);
    Navigator.of(ctx).pop();
    await tester.pumpAndSettle();
    expect(find.text('hộp thoại'), findsNothing);
    expect(find.text('mở'), findsOneWidget);
  });

  test('Android và các nền tảng khác giữ builder mặc định của Flutter', () {
    final builders = AppTheme.light().pageTransitionsTheme.builders;
    expect(
      builders[TargetPlatform.android],
      isA<PredictiveBackPageTransitionsBuilder>(),
    );
    expect(
      builders[TargetPlatform.iOS],
      isA<ReducedMotionPageTransitionsBuilder>(),
    );
    expect(builders[TargetPlatform.windows], isA<ZoomPageTransitionsBuilder>());
  });

  test('builder chuyển tiếp đúng thời lượng/delegatedTransition của base', () {
    const base = CupertinoPageTransitionsBuilder();
    const b = ReducedMotionPageTransitionsBuilder();
    expect(b.transitionDuration, base.transitionDuration);
    expect(b.reverseTransitionDuration, base.reverseTransitionDuration);
    expect(b.delegatedTransition, isNotNull);
  });
}
