import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/login_screen.dart';
import '../../features/grammar/grammar_flashcard_screen.dart';
import '../../features/grammar/grammar_list_screen.dart';
import '../../features/home/home_screen.dart';
import '../../features/kaiwa/kaiwa_home_screen.dart';
import '../../features/kanji/kanji_detail_screen.dart';
import '../../features/kanji/kanji_draw_search_screen.dart';
import '../../features/kanji/kanji_list_screen.dart';
import '../../features/lesson/lesson_detail_screen.dart';
import '../../features/lesson/lesson_list_screen.dart';
import '../../features/lesson/providers/level_providers.dart';
import '../../features/quiz/providers/quiz_providers.dart';
import '../../features/quiz/quiz_category_screen.dart';
import '../../features/quiz/quiz_screen.dart';
import '../../features/vocabulary/vocabulary_flashcard_screen.dart';
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
      GoRoute(
        path: '/lessons/:id/quiz',
        builder: (context, state) {
          final lessonId = state.pathParameters['id']!;
          final title = state.extra as String?;
          return Consumer(
            builder: (context, ref, _) {
              final questionsAsync =
                  ref.watch(lessonQuizQuestionsProvider(lessonId));
              return questionsAsync.when(
                loading: () => const Scaffold(
                    body: Center(child: CircularProgressIndicator()),),
                error: (e, _) => Scaffold(body: Center(child: Text('Lỗi: $e'))),
                data: (questions) => QuizScreen(
                  questions: questions,
                  title:
                      title == null ? 'Kiểm tra bài học' : 'Kiểm tra: $title',
                ),
              );
            },
          );
        },
      ),
      GoRoute(
          path: '/quiz', builder: (_, __) => const QuizCategoryScreen(),),
      GoRoute(
        path: '/quiz/:category',
        builder: (context, state) {
          final category = QuizCategoryLabel.fromRouteSegment(
              state.pathParameters['category']!,);
          if (category == null) {
            return const Scaffold(
                body: Center(child: Text('Loại quiz không hợp lệ')),);
          }
          return Consumer(
            builder: (context, ref, _) {
              final questionsAsync =
                  ref.watch(levelCategoryQuizQuestionsProvider(category));
              final level = ref.watch(selectedLevelCodeProvider);
              return questionsAsync.when(
                loading: () => const Scaffold(
                    body: Center(child: CircularProgressIndicator()),),
                error: (e, _) =>
                    Scaffold(body: Center(child: Text('Lỗi: $e'))),
                data: (questions) => QuizScreen(
                  questions: questions,
                  title: '${category.label} · $level',
                ),
              );
            },
          );
        },
      ),
      GoRoute(
        path: '/listening',
        builder: (context, state) => Consumer(
          builder: (context, ref, _) {
            final questionsAsync = ref.watch(levelListeningQuestionsProvider);
            final level = ref.watch(selectedLevelCodeProvider);
            return questionsAsync.when(
              loading: () => const Scaffold(
                  body: Center(child: CircularProgressIndicator()),),
              error: (e, _) => Scaffold(body: Center(child: Text('Lỗi: $e'))),
              data: (questions) => QuizScreen(
                questions: questions,
                title: 'Nghe hiểu $level',
                listeningMode: true,
              ),
            );
          },
        ),
      ),
      GoRoute(
          path: '/vocabulary',
          builder: (_, __) => const VocabularyListScreen(),),
      GoRoute(
          path: '/vocabulary/flashcards',
          builder: (_, __) => const VocabularyFlashcardScreen(),),
      GoRoute(path: '/kanji', builder: (_, __) => const KanjiListScreen()),
      GoRoute(
          path: '/kanji/draw',
          builder: (_, __) => const KanjiDrawSearchScreen(),),
      GoRoute(
        path: '/kanji/:id',
        builder: (context, state) =>
            KanjiDetailScreen(kanjiId: state.pathParameters['id']!),
      ),
      GoRoute(path: '/grammar', builder: (_, __) => const GrammarListScreen()),
      GoRoute(
          path: '/grammar/flashcards',
          builder: (_, __) => const GrammarFlashcardScreen(),),
      GoRoute(path: '/kaiwa', builder: (_, __) => const KaiwaHomeScreen()),
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
