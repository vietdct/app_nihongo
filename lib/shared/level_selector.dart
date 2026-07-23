import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/lesson/providers/level_providers.dart';

/// Bộ chọn cấp độ JLPT dùng chung cho Home/Lesson/Vocabulary/Kanji.
/// Đổi lựa chọn ở đây tự động làm mới nội dung ở mọi màn hình đang mở,
/// vì tất cả cùng watch [selectedLevelCodeProvider].
class LevelSelector extends ConsumerWidget {
  const LevelSelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final levelsAsync = ref.watch(jlptLevelsProvider);
    final selected = ref.watch(selectedLevelCodeProvider);

    return levelsAsync.when(
      loading: () => const SizedBox(
        height: 40,
        child: Center(child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))),
      ),
      error: (e, _) => const SizedBox.shrink(),
      data: (levels) {
        if (levels.isEmpty) return const SizedBox.shrink();
        return SizedBox(
          height: 40,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: levels.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, i) {
              final level = levels[i];
              final isSelected = level.code == selected;
              return ChoiceChip(
                label: Text(level.code, style: const TextStyle(fontWeight: FontWeight.w700)),
                selected: isSelected,
                onSelected: (_) => ref.read(selectedLevelCodeProvider.notifier).state = level.code,
              );
            },
          ),
        );
      },
    );
  }
}
