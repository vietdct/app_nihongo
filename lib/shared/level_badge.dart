import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/entities/jlpt_level.dart';
import '../features/lesson/providers/level_providers.dart';

/// Huy hiệu cấp độ gọn ở header — bấm mở bottom sheet chọn cấp N5–N1.
/// Thay cho dải chip nằm ngang chiếm nhiều chỗ dọc trên Home.
class LevelBadge extends ConsumerWidget {
  const LevelBadge({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(selectedLevelCodeProvider);
    final scheme = Theme.of(context).colorScheme;

    return InkWell(
      borderRadius: BorderRadius.circular(100),
      onTap: () => _showLevelPicker(context, ref),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: scheme.onPrimary.withValues(alpha: 0.16),
          borderRadius: BorderRadius.circular(100),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(selected, style: const TextStyle(fontWeight: FontWeight.w800, color: Colors.white)),
            const SizedBox(width: 4),
            const Icon(Icons.expand_more, size: 18, color: Colors.white),
          ],
        ),
      ),
    );
  }

  void _showLevelPicker(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (_) => const _LevelPickerSheet(),
    );
  }
}

class _LevelPickerSheet extends ConsumerWidget {
  const _LevelPickerSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final levelsAsync = ref.watch(jlptLevelsProvider);
    final selected = ref.watch(selectedLevelCodeProvider);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Chọn cấp độ', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            levelsAsync.when(
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (e, _) => Text('Lỗi: $e'),
              data: (levels) => Column(
                mainAxisSize: MainAxisSize.min,
                children: [for (final level in levels) _LevelRow(level: level, isSelected: level.code == selected)],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LevelRow extends ConsumerWidget {
  const _LevelRow({required this.level, required this.isSelected});

  final JlptLevel level;
  final bool isSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundColor: isSelected ? scheme.primary : scheme.surfaceContainerHighest,
        foregroundColor: isSelected ? scheme.onPrimary : scheme.onSurfaceVariant,
        child: Text(level.code, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
      ),
      title: Text(level.title),
      trailing: isSelected ? Icon(Icons.check_circle, color: scheme.primary) : null,
      onTap: () {
        ref.read(selectedLevelCodeProvider.notifier).state = level.code;
        Navigator.of(context).pop();
      },
    );
  }
}
