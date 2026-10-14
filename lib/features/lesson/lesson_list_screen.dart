import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../../shared/level_badge.dart';
import '../../shared/motion/press_scale.dart';
import '../../shared/motion/stagger.dart';
import '../../shared/skeleton_layouts.dart';
import '../../shared/state_views.dart';
import 'it_learning_hub.dart';
import 'providers/content_providers.dart';
import 'providers/content_state.dart';
import 'providers/level_providers.dart';

class LessonListScreen extends ConsumerWidget {
  const LessonListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lessons = resolveContentList(ref, ref.watch(lessonsProvider));
    final selectedLevel = ref.watch(selectedLevelCodeProvider);
    if (selectedLevel == 'IT') return const ItLearningHub();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bài học'),
        actions: const [LevelBadge(), SizedBox(width: 12)],
      ),
      body: lessons.when(
        loading: () => const LessonListSkeleton(),
        error: (e, _) => ErrorState(
          error: e,
          onRetry: () => retryContentSync(ref, streamProvider: lessonsProvider),
        ),
        data: (items) {
          if (items.isEmpty) {
            return RefreshIndicator(
              onRefresh: () => pullToRefreshContent(context, ref),
              child: EmptyState(
                icon: Icons.menu_book_outlined,
                title: 'Chưa có bài học nào cho $selectedLevel',
                message:
                    'Nội dung đang được bổ sung dần. Kéo xuống để làm mới.',
              ),
            );
          }
          // Stagger gắn với vòng đời nhánh `data`: chạy khi danh sách vừa hiện
          // (mở màn / đổi cấp độ → tải lại), không chạy lại khi rebuild hay
          // cuộn; chỉ 8 bài đầu được animate.
          return RefreshIndicator(
            onRefresh: () => pullToRefreshContent(context, ref),
            child: StaggerGroup(
              child: ListView.separated(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                itemCount: items.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, i) {
                  final lesson = items[i];
                  return StaggerItem(
                    index: i,
                    child: PressScale(
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () => context.push('/lessons/${lesson.id}/run'),
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppColors.card,
                            borderRadius: BorderRadius.circular(16),
                            border:
                                Border.all(color: AppColors.border, width: 0.6),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: AppColors.indigoSoft,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  '課',
                                  style: AppFonts.zenMaruGothic(
                                    fontSize: 18,
                                    color: AppColors.indigo,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      lesson.title,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 14.5,
                                        color: AppColors.ink,
                                      ),
                                    ),
                                    if (lesson.description != null) ...[
                                      const SizedBox(height: 2),
                                      Text(
                                        lesson.description!,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 12.5,
                                          color: AppColors.inkSoft,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              const Icon(
                                Icons.chevron_right,
                                color: AppColors.inkFaint,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }
}
