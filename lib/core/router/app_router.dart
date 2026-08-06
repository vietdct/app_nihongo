import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../features/auth/login_screen.dart';
import '../../features/grammar/grammar_compare_screen.dart';
import '../../features/grammar/grammar_detail_screen.dart';
import '../../features/grammar/grammar_flashcard_screen.dart';
import '../../features/grammar/grammar_list_screen.dart';
import '../../features/grammar/grammar_practice_screen.dart';
import '../../features/grammar/grammar_review_screen.dart';
import '../../features/grammar/grammar_tutor_screen.dart';
import '../../features/kaiwa/kaiwa_history_screen.dart';
import '../../features/kaiwa/kaiwa_home_screen.dart';
import '../../features/kaiwa/kaiwa_review_screen.dart';
import '../../features/kaiwa/kaiwa_roleplay_screen.dart';
import '../../features/kaiwa/kaiwa_scenario_map_screen.dart';
import '../../features/kaiwa/kaiwa_shadowing_screen.dart';
import '../../features/kaiwa/kaiwa_statistics_screen.dart';
import '../../features/kanji/kanji_detail_screen.dart';
import '../../features/kanji/kanji_draw_search_screen.dart';
import '../../features/kanji/kanji_list_screen.dart';
import '../../features/kanji/kanji_family_screen.dart';
import '../../features/kanji/kanji_review_screen.dart';
import '../../features/kanji/kanji_statistics_screen.dart';
import '../../features/kanji/kanji_stroke_practice_screen.dart';
import '../../features/kanji/kanji_tutor_screen.dart';
import '../../features/kanji/providers/kanji_reading_practice_providers.dart';
import '../../features/lesson/providers/content_providers.dart';
import '../../features/lesson/lesson_detail_screen.dart';
import '../../features/lesson/lesson_list_screen.dart';
import '../../features/lesson/lesson_runner_screen.dart';
import '../../features/lesson/providers/level_providers.dart';
import '../../features/premium/premium_screen.dart';
import '../../features/profile/pages/account_screen.dart';
import '../../features/profile/pages/achievements_screen.dart';
import '../../features/profile/pages/ai_insights_screen.dart';
import '../../features/profile/pages/bookmarks_screen.dart';
import '../../features/profile/pages/edit_profile_screen.dart';
import '../../features/profile/pages/history_screen.dart';
import '../../features/profile/pages/learning_overview_screen.dart';
import '../../features/quiz/providers/quiz_providers.dart';
import '../../features/review/jlpt_exam/exam_result_screen.dart';
import '../../features/review/jlpt_exam/exam_review_screen.dart';
import '../../features/review/jlpt_exam/exam_runner_screen.dart';
import '../../features/review/jlpt_exam/jlpt_exam_level_screen.dart';
import '../../features/review/jlpt_exam/custom_test_settings_screen.dart';
import '../../features/review/jlpt_exam/jlpt_exam_mode_screen.dart';
import '../../features/review/jlpt_exam/mini_test/mini_test_home_screen.dart';
import '../../features/review/jlpt_exam/mini_test/mini_test_result_screen.dart';
import '../../features/review/jlpt_exam/models/exam_review_answer.dart';
import '../../features/review/jlpt_exam/providers/jlpt_exam_content_providers.dart'
    show ExamRunSection;
import '../../features/review/review_mistakes_screen.dart';
import '../../features/review/review_mixed_quiz_custom_screen.dart';
import '../../features/review/review_mixed_quiz_screen.dart';
import '../../features/review/providers/mixed_quiz_providers.dart';
import '../../features/review/review_smart_screen.dart';
import '../../features/review/review_statistics_screen.dart';
import '../../features/review/review_today_screen.dart';
import '../../features/review/review_weak_points_screen.dart';
import 'main_tab_shell.dart';
import '../../features/quiz/quiz_category_screen.dart';
import '../../features/quiz/quiz_screen.dart';
import '../../features/vocabulary/vocabulary_flashcard_screen.dart';
import '../../features/vocabulary/vocabulary_home_screen.dart';
import '../../features/vocabulary/vocabulary_list_screen.dart';
import '../../features/vocabulary/vocabulary_review_screen.dart';
import '../network/supabase_providers.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final refresh = _AuthRefreshListenable(ref);
  ref.onDispose(refresh.dispose);

  return GoRouter(
    initialLocation: '/',
    refreshListenable: refresh,
    redirect: (context, state) {
      final atLogin = state.matchedLocation == '/login';
      if (!refresh.loggedIn) return atLogin ? null : '/login';
      if (atLogin) return '/';
      return null;
    },
    routes: [
      GoRoute(path: '/', builder: (_, __) => const MainTabShell()),
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
        path: '/lessons/:id/run',
        builder: (context, state) => LessonRunnerScreen(
          lessonId: state.pathParameters['id']!,
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
                  body: Center(child: CircularProgressIndicator()),
                ),
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
        path: '/quiz',
        builder: (_, __) => const QuizCategoryScreen(),
      ),
      GoRoute(
        path: '/quiz/:category',
        builder: (context, state) {
          final category = QuizCategoryLabel.fromRouteSegment(
            state.pathParameters['category']!,
          );
          if (category == null) {
            return const Scaffold(
              body: Center(child: Text('Loại quiz không hợp lệ')),
            );
          }
          return Consumer(
            builder: (context, ref, _) {
              final questionsAsync =
                  ref.watch(levelCategoryQuizQuestionsProvider(category));
              final level = ref.watch(selectedLevelCodeProvider);
              return questionsAsync.when(
                loading: () => const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                ),
                error: (e, _) => Scaffold(body: Center(child: Text('Lỗi: $e'))),
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
                body: Center(child: CircularProgressIndicator()),
              ),
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
        path: '/review/today',
        builder: (_, __) => const ReviewTodayScreen(),
      ),
      GoRoute(
        path: '/review/weak-points',
        builder: (_, __) => const ReviewWeakPointsScreen(),
      ),
      GoRoute(
        path: '/review/mistakes',
        builder: (_, __) => const ReviewMistakesScreen(),
      ),
      GoRoute(
        path: '/review/smart',
        builder: (_, __) => const ReviewSmartScreen(),
      ),
      GoRoute(
        path: '/review/statistics',
        builder: (_, __) => const ReviewStatisticsScreen(),
      ),
      GoRoute(
        path: '/review/jlpt-exam',
        builder: (_, __) => const JlptExamLevelScreen(),
      ),
      GoRoute(
        path: '/review/jlpt-exam/:levelId/mode',
        builder: (_, state) => JlptExamModeScreen(
          levelId: state.pathParameters['levelId']!,
        ),
      ),
      GoRoute(
        path: '/review/jlpt-exam/:levelId/mini',
        builder: (_, state) => MiniTestHomeScreen(
          levelId: state.pathParameters['levelId']!,
        ),
      ),
      GoRoute(
        path: '/review/jlpt-exam/:levelId/mini/result',
        builder: (_, state) => MiniTestResultScreen(
          args: state.extra! as MiniTestResultArgs,
        ),
      ),
      GoRoute(
        path: '/review/jlpt-exam/:levelId/custom/settings',
        builder: (_, state) => CustomTestSettingsScreen(
          levelId: state.pathParameters['levelId']!,
        ),
      ),
      GoRoute(
        path: '/review/jlpt-exam/:levelId/session/:mode',
        builder: (_, state) => ExamRunnerScreen(
          levelId: state.pathParameters['levelId']!,
          mode: state.pathParameters['mode']!,
          // Full Exam không truyền extra (null) — Mini Test truyền sẵn đề đã
          // sinh (docs/JLPT_MINI_TEST_DESIGN.md §7), xem ExamRunnerScreen.overrideSections.
          overrideSections: state.extra as List<ExamRunSection>?,
        ),
      ),
      GoRoute(
        path: '/review/jlpt-exam/result',
        builder: (_, state) => ExamResultScreen(
          args: state.extra! as ExamResultArgs,
        ),
      ),
      GoRoute(
        path: '/review/jlpt-exam/result/review',
        builder: (_, state) => ExamReviewScreen(
          sections: state.extra! as List<ExamReviewSection>,
        ),
      ),
      GoRoute(
        path: '/review/mixed-quiz',
        builder: (_, __) => const ReviewMixedQuizScreen(),
      ),
      GoRoute(
        path: '/review/mixed-quiz/:count',
        builder: (context, state) {
          final count = int.tryParse(state.pathParameters['count']!) ?? 10;
          return Consumer(
            builder: (context, ref, _) {
              final questions = ref.watch(mixedQuizQuestionsProvider(count));
              return QuizScreen(
                questions: questions,
                title: 'Quiz tổng hợp',
              );
            },
          );
        },
      ),
      GoRoute(
        path: '/review/mixed-quiz/custom',
        builder: (_, __) => const ReviewMixedQuizCustomScreen(),
      ),
      GoRoute(
        path: '/review/mixed-quiz/custom/play',
        builder: (context, state) {
          final config = state.extra! as MixedQuizConfig;
          return Consumer(
            builder: (context, ref, _) {
              final questions =
                  ref.watch(customMixedQuizQuestionsProvider(config));
              return QuizScreen(
                questions: questions,
                title: 'Quiz Tuỳ chỉnh',
                timedMode: config.timedMode,
                survivalMode: config.survivalMode,
              );
            },
          );
        },
      ),
      GoRoute(
        path: '/review/mixed-quiz/weak-points/:count',
        builder: (context, state) {
          final count = int.tryParse(state.pathParameters['count']!) ?? 10;
          return Consumer(
            builder: (context, ref, _) {
              final questions =
                  ref.watch(weakPointMixedQuizQuestionsProvider(count));
              return QuizScreen(
                questions: questions,
                title: 'Thử thách điểm yếu',
              );
            },
          );
        },
      ),
      GoRoute(
        path: '/vocabulary',
        builder: (_, __) => const VocabularyHomeScreen(),
      ),
      GoRoute(
        path: '/vocabulary/list',
        builder: (_, __) => const VocabularyListScreen(),
      ),
      GoRoute(
        path: '/vocabulary/flashcards',
        builder: (context, state) => VocabularyFlashcardScreen(
          startSmart: state.extra == true,
        ),
      ),
      GoRoute(
        path: '/vocabulary/review',
        builder: (_, __) => const VocabularyReviewScreen(),
      ),
      GoRoute(path: '/kanji', builder: (_, __) => const KanjiListScreen()),
      GoRoute(
        path: '/kanji/draw',
        builder: (_, __) => const KanjiDrawSearchScreen(),
      ),
      GoRoute(
        path: '/kanji/review',
        builder: (_, __) => const KanjiReviewScreen(),
      ),
      GoRoute(
        path: '/kanji/statistics',
        builder: (_, __) => const KanjiStatisticsScreen(),
      ),
      GoRoute(
        path: '/kanji/:id',
        builder: (context, state) => KanjiDetailScreen(
          kanjiId: state.pathParameters['id']!,
          filterIds: state.extra as Set<String>?,
        ),
      ),
      GoRoute(
        path: '/kanji/:id/practice',
        builder: (context, state) => KanjiStrokePracticeScreen(
          kanjiId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: '/kanji/:id/reading',
        builder: (context, state) {
          final kanjiId = state.pathParameters['id']!;
          return Consumer(
            builder: (context, ref, _) {
              final questionsAsync =
                  ref.watch(kanjiReadingPracticeQuestionsProvider(kanjiId));
              final allKanji = ref.watch(kanjiListProvider).valueOrNull;
              String? character;
              if (allKanji != null) {
                for (final k in allKanji) {
                  if (k.id == kanjiId) {
                    character = k.character;
                    break;
                  }
                }
              }
              return questionsAsync.when(
                loading: () => const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                ),
                error: (e, _) => Scaffold(body: Center(child: Text('Lỗi: $e'))),
                data: (questions) => QuizScreen(
                  questions: questions,
                  title: character == null
                      ? 'Luyện đọc Kanji'
                      : 'Luyện đọc: $character',
                ),
              );
            },
          );
        },
      ),
      GoRoute(
        path: '/kanji/:id/family',
        builder: (context, state) => KanjiFamilyScreen(
          kanjiId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: '/kanji/:id/tutor',
        builder: (context, state) => KanjiTutorScreen(
          kanjiId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(path: '/grammar', builder: (_, __) => const GrammarListScreen()),
      GoRoute(
        path: '/grammar/flashcards',
        builder: (_, __) => const GrammarFlashcardScreen(),
      ),
      GoRoute(
        path: '/grammar/practice',
        builder: (_, __) => const GrammarPracticeScreen(),
      ),
      GoRoute(
        path: '/grammar/review',
        builder: (_, __) => const GrammarReviewScreen(),
      ),
      GoRoute(
        path: '/grammar/:id',
        builder: (context, state) => GrammarDetailScreen(
          grammarId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: '/grammar/:id/tutor',
        builder: (context, state) => GrammarTutorScreen(
          grammarId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: '/grammar-compare/:idA/:idB',
        builder: (context, state) => GrammarCompareScreen(
          idA: state.pathParameters['idA']!,
          idB: state.pathParameters['idB']!,
        ),
      ),
      GoRoute(path: '/kaiwa', builder: (_, __) => const KaiwaHomeScreen()),
      GoRoute(
        path: '/kaiwa/topics',
        builder: (context, state) => KaiwaScenarioMapScreen(
          seedWord: state.extra as String?,
        ),
      ),
      GoRoute(
        path: '/kaiwa/topics/:scenarioId/roleplay',
        builder: (context, state) => KaiwaRoleplayScreen(
          scenarioId: state.pathParameters['scenarioId']!,
          seedWord: state.extra as String?,
        ),
      ),
      GoRoute(
        path: '/kaiwa/history',
        builder: (_, __) => const KaiwaHistoryScreen(),
      ),
      GoRoute(
        path: '/kaiwa/shadowing',
        builder: (_, __) => const KaiwaShadowingScreen(),
      ),
      GoRoute(
        path: '/kaiwa/review',
        builder: (_, __) => const KaiwaReviewScreen(),
      ),
      GoRoute(
        path: '/kaiwa/statistics',
        builder: (_, __) => const KaiwaStatisticsScreen(),
      ),
      GoRoute(path: '/premium', builder: (_, __) => const PremiumScreen()),
      GoRoute(
        path: '/profile/edit',
        builder: (_, __) => const EditProfileScreen(),
      ),
      GoRoute(
        path: '/profile/learning',
        builder: (_, __) => const LearningOverviewScreen(),
      ),
      GoRoute(
        path: '/profile/bookmarks',
        builder: (_, __) => const BookmarksScreen(),
      ),
      GoRoute(
        path: '/profile/history',
        builder: (_, __) => const HistoryScreen(),
      ),
      GoRoute(
        path: '/profile/achievements',
        builder: (_, __) => const AchievementsScreen(),
      ),
      GoRoute(
        path: '/profile/ai-insights',
        builder: (_, __) => const AiInsightsScreen(),
      ),
      GoRoute(
        path: '/profile/account',
        builder: (_, __) => const AccountScreen(),
      ),
    ],
  );
});

/// Bắc cầu từ Riverpod auth stream sang [Listenable] để go_router tự
/// đánh giá lại redirect mỗi khi trạng thái đăng nhập đổi.
///
/// [loggedIn] lấy thẳng từ giá trị `next` mà callback của [authStateProvider]
/// nhận được — KHÔNG đọc lại qua `ref.read/watch(currentUserProvider)`. Đọc
/// lại qua provider khác dễ dính đúng lúc provider đó chưa kịp rebuild theo
/// sự kiện vừa phát (redirect chạy ngay khi notifyListeners(), nhưng
/// currentUserProvider có thể rebuild ở 1 nhịp microtask sau đó), khiến
/// redirect đọc nhầm trạng thái "vẫn đăng nhập" ngay sau khi vừa đăng xuất.
class _AuthRefreshListenable extends ChangeNotifier {
  _AuthRefreshListenable(Ref ref) {
    loggedIn = ref.read(supabaseProvider).auth.currentSession != null;
    _sub = ref.listen<AsyncValue<AuthState>>(
      authStateProvider,
      (_, next) {
        loggedIn = next.valueOrNull?.session != null;
        notifyListeners();
      },
      fireImmediately: false,
    );
  }

  bool loggedIn = false;
  late final ProviderSubscription<AsyncValue<AuthState>> _sub;

  @override
  void dispose() {
    _sub.close();
    super.dispose();
  }
}
