import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../../shared/level_badge.dart';
import '../../shared/motion/fade_switcher.dart';
import '../../shared/motion/press_scale.dart';
import '../../shared/skeleton_layouts.dart';
import 'it_learning_hub.dart';
import 'providers/content_providers.dart';
import 'providers/level_providers.dart';

class LessonListScreen extends ConsumerWidget {
  const LessonListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lessons = ref.watch(lessonsProvider);
    final selectedLevel = ref.watch(selectedLevelCodeProvider);
    if (selectedLevel == 'IT') return const ItLearningHub();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bài học'),
        actions: const [LevelBadge(), SizedBox(width: 12)],
      ),
      body: FadeSwitcher(
        child: lessons.when(
        loading: () => const LessonListSkeleton(key: ValueKey('loading')),
        error: (e, _) =>
            Center(key: const ValueKey('error'), child: Text('Lỗi: $e')),
        data: (items) {
          if (items.isEmpty) {
            return Center(
              key: const ValueKey('empty'),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Chưa có bài học nào cho $selectedLevel.\nNội dung đang được bổ sung dần.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.inkSoft),
                ),
              ),
            );
          }
          return ListView.separated(
            key: const ValueKey('data'),
            padding: const EdgeInsets.all(20),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, i) {
              final lesson = items[i];
              return PressScale(
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () => context.push('/lessons/${lesson.id}/run'),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border, width: 0.6),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(color: AppColors.indigoSoft, borderRadius: BorderRadius.circular(12)),
                          alignment: Alignment.center,
                          child: Text('課', style: AppFonts.zenMaruGothic(fontSize: 18, color: AppColors.indigo)),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(lesson.title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5, color: AppColors.ink)),
                              if (lesson.description != null) ...[
                                const SizedBox(height: 2),
                                Text(
                                  lesson.description!,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 12.5, color: AppColors.inkSoft),
                                ),
                              ],
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right, color: AppColors.inkFaint),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
        ),
      ),
    );
  }
}
