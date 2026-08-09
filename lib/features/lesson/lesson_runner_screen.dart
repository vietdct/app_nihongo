import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/supabase_providers.dart';
import '../../core/theme/app_theme.dart';
import '../../domain/entities/lesson.dart';
import '../../domain/entities/lesson_progress.dart';
import '../../domain/services/lesson_objectives.dart';
import '../../domain/services/lesson_progress_log.dart';
import 'lesson_runner_steps.dart';
import 'providers/lesson_runner_providers.dart';
import 'providers/level_providers.dart';
import 'widgets/lesson_exercise_view.dart';
import 'widgets/lesson_intro_view.dart';
import 'widgets/lesson_listening_view.dart';
import 'widgets/lesson_mission_view.dart';
import 'widgets/lesson_objectives_view.dart';
import 'widgets/lesson_progress_header.dart';
import 'widgets/lesson_review_view.dart';
import 'widgets/lesson_understand_cards.dart';

/// Khung chạy 1 phiên học Lesson đầy đủ — cả 5 pha (Input/Understand/
/// Practice/Apply/Review) đều đã có nội dung thật, xem bản thiết kế "Lesson
/// Module" mục 15. Thay `LessonDetailScreen` (danh sách phẳng) làm lối vào
/// chính từ Lesson List.
class LessonRunnerScreen extends ConsumerStatefulWidget {
  const LessonRunnerScreen({super.key, required this.lessonId});

  final String lessonId;

  @override
  ConsumerState<LessonRunnerScreen> createState() => _LessonRunnerScreenState();
}

class _LessonRunnerScreenState extends ConsumerState<LessonRunnerScreen> {
  final _pageController = PageController();
  bool _restored = false;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _advanceTo(int index) {
    ref.read(lessonRunnerControllerProvider(widget.lessonId).notifier).goTo(index);
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
    );
    unawaited(_persistStep(index));
  }

  Future<void> _persistStep(int index) async {
    final sb = ref.read(supabaseProvider);
    final userId = ref.read(currentUserProvider)?.id;
    final totalSteps = ref.read(lessonRunnerStepsProvider(widget.lessonId)).valueOrNull?.length;
    if (userId == null || totalSteps == null || totalSteps == 0) return;
    await saveLessonStepProgress(sb, userId, widget.lessonId, index, totalSteps);
  }

  /// Nhảy thẳng tới bước đã lưu (nếu có, chưa hoàn thành, và hợp lệ với số
  /// bước hiện tại) đúng 1 lần khi vừa mở bài — không animate vì đây là
  /// khôi phục vị trí, không phải người dùng bấm "Tiếp".
  void _restoreIfNeeded(LessonProgress? progress, int totalSteps) {
    if (_restored || progress == null || progress.isCompleted || totalSteps == 0) return;
    final target = progress.lastStepIndex.clamp(0, totalSteps - 1);
    _restored = true;
    if (target <= 0) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(lessonRunnerControllerProvider(widget.lessonId).notifier).goTo(target);
      if (_pageController.hasClients) _pageController.jumpToPage(target);
    });
  }

  @override
  Widget build(BuildContext context) {
    final lessonAsync = ref.watch(lessonByIdProvider(widget.lessonId));
    final stepsAsync = ref.watch(lessonRunnerStepsProvider(widget.lessonId));
    final progressAsync = ref.watch(lessonProgressProvider(widget.lessonId));

    final steps = stepsAsync.valueOrNull;
    if (steps != null) _restoreIfNeeded(progressAsync.valueOrNull, steps.length);

    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: lessonAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Lỗi: $e')),
        data: (lesson) {
          if (lesson == null) {
            return const Center(
              child: Text('Không tìm thấy bài học.', style: TextStyle(color: AppColors.inkSoft)),
            );
          }
          return stepsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Lỗi: $e')),
            data: (steps) => _RunnerBody(
              lesson: lesson,
              steps: steps,
              lessonId: widget.lessonId,
              pageController: _pageController,
              onAdvance: _advanceTo,
            ),
          );
        },
      ),
    );
  }
}

class _RunnerBody extends ConsumerWidget {
  const _RunnerBody({
    required this.lesson,
    required this.steps,
    required this.lessonId,
    required this.pageController,
    required this.onAdvance,
  });

  final Lesson lesson;
  final List<LessonStep> steps;
  final String lessonId;
  final PageController pageController;
  final void Function(int) onAdvance;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (steps.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Bài học này chưa có nội dung.\nNội dung đang được bổ sung dần.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.inkSoft),
          ),
        ),
      );
    }

    final rawIndex = ref.watch(lessonRunnerControllerProvider(lessonId));
    final currentIndex = rawIndex.clamp(0, steps.length - 1);
    final items = steps.whereType<LessonUnderstandStep>().map((s) => s.item).toList();
    final levelLabel = ref.watch(selectedLevelCodeProvider);

    return SafeArea(
      child: Column(
        children: [
          LessonProgressHeader(
            currentPhase: phaseOfStep(steps[currentIndex]),
            onBack: () => Navigator.of(context).maybePop(),
          ),
          Expanded(
            child: PageView.builder(
              controller: pageController,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: steps.length,
              itemBuilder: (context, i) => Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                child: _StepView(
                  step: steps[i],
                  lesson: lesson,
                  items: items,
                  levelLabel: levelLabel,
                  onNext: i < steps.length - 1 ? () => onAdvance(i + 1) : null,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StepView extends StatelessWidget {
  const _StepView({
    required this.step,
    required this.lesson,
    required this.items,
    required this.levelLabel,
    required this.onNext,
  });

  final LessonStep step;
  final Lesson lesson;
  final List<LessonContentItem> items;
  final String levelLabel;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    return switch (step) {
      LessonIntroStep() =>
        LessonIntroView(lesson: lesson, items: items, levelLabel: levelLabel, onStart: onNext ?? _noop),
      LessonObjectivesStep() =>
        LessonObjectivesView(objectives: deriveLessonObjectives(items), onReady: onNext ?? _noop),
      LessonUnderstandStep(:final item) => _UnderstandStepView(item: item, onDone: onNext ?? _noop),
      LessonListeningStep(:final question) =>
        LessonListeningView(question: question, onDone: onNext ?? _noop),
      LessonExerciseStep(:final item) => LessonExerciseView(item: item, onDone: onNext ?? _noop),
      LessonMissionStep(:final mission) =>
        LessonMissionView(mission: mission, onDone: onNext ?? _noop),
      LessonReviewStep(:final items) =>
        LessonReviewView(items: items, lessonId: lesson.id, lessonTitle: lesson.title),
    };
  }

  static void _noop() {}
}

class _UnderstandStepView extends StatelessWidget {
  const _UnderstandStepView({required this.item, required this.onDone});

  final LessonContentItem item;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    return switch (item.type) {
      LessonItemType.vocabulary => LessonVocabUnderstandCard(vocab: item.vocabulary!, onDone: onDone),
      LessonItemType.kanji => LessonKanjiUnderstandCard(kanji: item.kanji!, onDone: onDone),
      LessonItemType.grammar => LessonGrammarUnderstandCard(grammar: item.grammar!, onDone: onDone),
    };
  }
}
