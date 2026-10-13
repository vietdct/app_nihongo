import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import '../domain/entities/lesson.dart';
import 'filter_pill_button.dart';

/// null = "Tất cả", chuỗi rỗng '' = "Chưa xếp bài" (chưa gắn vào bài nào).
const String unassignedLessonFilter = '';

/// Huy hiệu chọn bài học để giới hạn Vocabulary/Kanji theo đúng 1 bài —
/// cùng kiểu tương tác với [LevelBadge] (chạm mở bottom sheet chọn), giúp
/// người học biết chính xác nên bắt đầu học phần nào.
class LessonFilterDropdown extends StatelessWidget {
  const LessonFilterDropdown({
    super.key,
    required this.lessons,
    required this.selected,
    required this.hasUnassigned,
    required this.onSelected,
    required this.accentColor,
    this.fillWidth = false,
  });

  final List<Lesson> lessons;
  final String? selected;
  final bool hasUnassigned;
  final ValueChanged<String?> onSelected;
  final Color accentColor;

  /// true = kéo giãn hết chiều ngang được cấp (dùng khi xếp nhiều badge
  /// thành hàng ngang, ví dụ [Expanded] trong `vocabulary_list_screen.dart`).
  /// false (mặc định) = ôm sát nội dung, căn trái — dùng khi đứng một mình.
  final bool fillWidth;

  @override
  Widget build(BuildContext context) {
    if (lessons.isEmpty) return const SizedBox.shrink();
    return FilterPillButton(
      label: _label(),
      accentColor: accentColor,
      fillWidth: fillWidth,
      onTap: () => _showPicker(context),
    );
  }

  String _label() {
    if (selected == null) return 'Tất cả các bài';
    if (selected == unassignedLessonFilter) return 'Chưa xếp bài';
    for (final lesson in lessons) {
      if (lesson.id == selected) return _shortTitle(lesson.title);
    }
    return 'Tất cả các bài';
  }

  static String _shortTitle(String title) {
    final dashIndex = title.indexOf('—');
    return dashIndex == -1 ? title : title.substring(0, dashIndex).trim();
  }

  void _showPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      backgroundColor: AppColors.card,
      builder: (_) => _LessonPickerSheet(
        lessons: lessons,
        selected: selected,
        hasUnassigned: hasUnassigned,
        onSelected: onSelected,
        accentColor: accentColor,
      ),
    );
  }
}

class _LessonPickerSheet extends StatelessWidget {
  const _LessonPickerSheet({
    required this.lessons,
    required this.selected,
    required this.hasUnassigned,
    required this.onSelected,
    required this.accentColor,
  });

  final List<Lesson> lessons;
  final String? selected;
  final bool hasUnassigned;
  final ValueChanged<String?> onSelected;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 0, 20, 8),
            child: Text('Chọn bài học', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AppColors.ink)),
          ),
          Flexible(
            child: ListView(
              shrinkWrap: true,
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              children: [
                _Row(
                  label: 'Tất cả các bài',
                  description: 'Xem toàn bộ, không giới hạn theo bài',
                  leading: '∗',
                  isSelected: selected == null,
                  color: accentColor,
                  onTap: () {
                    onSelected(null);
                    Navigator.of(context).pop();
                  },
                ),
                for (final lesson in lessons)
                  _Row(
                    label: lesson.title,
                    description: lesson.description,
                    leading: '${lesson.orderIndex}',
                    isSelected: selected == lesson.id,
                    color: accentColor,
                    onTap: () {
                      onSelected(lesson.id);
                      Navigator.of(context).pop();
                    },
                  ),
                if (hasUnassigned)
                  _Row(
                    label: 'Chưa xếp bài',
                    description: 'Từ/kanji chưa gắn vào bài học nào',
                    leading: '?',
                    isSelected: selected == unassignedLessonFilter,
                    color: accentColor,
                    onTap: () {
                      onSelected(unassignedLessonFilter);
                      Navigator.of(context).pop();
                    },
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({
    required this.label,
    required this.description,
    required this.leading,
    required this.isSelected,
    required this.color,
    required this.onTap,
  });

  final String label;
  final String? description;
  final String leading;
  final bool isSelected;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundColor: isSelected ? color : AppColors.chip,
        foregroundColor: isSelected ? Colors.white : AppColors.inkSoft,
        child: Text(leading, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
      ),
      title: Text(label, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5, color: AppColors.ink)),
      subtitle: description == null
          ? null
          : Text(description!, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, color: AppColors.inkSoft)),
      trailing: isSelected ? Icon(Icons.check_circle, color: color) : null,
      onTap: onTap,
    );
  }
}
