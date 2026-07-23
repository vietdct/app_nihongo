import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/login_screen.dart';
import '../../features/home/home_screen.dart';
import '../../features/kanji/kanji_detail_screen.dart';
import '../../features/kanji/kanji_list_screen.dart';
import '../../features/lesson/lesson_detail_screen.dart';
import '../../features/lesson/lesson_list_screen.dart';
import '../../features/vocabulary/vocabulary_list_screen.dart';
import '../network/supabase_providers.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final refresh = _AuthRefreshListenable(ref);
  ref.onDispose(refresh.dispose);

  return GoRouter(
    initialLocation: '/',
    refreshListenable: refresh,
    redirect: (context, state) {
      final loggedIn = ref.read(currentUserProvider) != null;
      final atLogin = state.matchedLocation == '/login';
      if (!loggedIn) return atLogin ? null : '/login';
      if (atLogin) return '/';
      return null;
    },
    routes: [
      GoRoute(path: '/', builder: (_, __) => const HomeScreen()),
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/lessons', builder: (_, __) => const LessonListScreen()),
      GoRoute(
        path: '/lessons/:id',
        builder: (context, state) => LessonDetailScreen(
          lessonId: state.pathParameters['id']!,
          title: state.extra as String?,
        ),
      ),
      GoRoute(path: '/vocabulary', builder: (_, __) => const VocabularyListScreen()),
      GoRoute(path: '/kanji', builder: (_, __) => const KanjiListScreen()),
      GoRoute(
        path: '/kanji/:id',
        builder: (context, state) => KanjiDetailScreen(kanjiId: state.pathParameters['id']!),
      ),
    ],
  );
});

/// Bắc cầu từ Riverpod auth stream sang [Listenable] để go_router tự
/// đánh giá lại redirect mỗi khi trạng thái đăng nhập đổi.
class _AuthRefreshListenable extends ChangeNotifier {
  _AuthRefreshListenable(Ref ref) {
    _sub = ref.listen(
      authStateProvider,
      (_, __) => notifyListeners(),
      fireImmediately: false,
    );
  }

  late final ProviderSubscription<Object?> _sub;

  @override
  void dispose() {
    _sub.close();
    super.dispose();
  }
}
