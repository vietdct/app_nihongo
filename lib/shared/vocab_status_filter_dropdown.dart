import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';

/// 4 trạng thái học SRS có thể lọc ở màn danh sách từ vựng — xem cách tính ở
/// `vocabulary_list_screen.dart` (dùng trực tiếp field trên `VocabProgress`,
/// không cần entity riêng).
enum VocabStatusFilter {
  mastered,
  dueForReview,
  hardest,
  mostForgotten;

  String get label => switch (this) {
        VocabStatusFilter.mastered => 'Đã thuộc',
        VocabStatusFilter.dueForReview => 'Cần ôn',
        VocabStatusFilter.hardest => 'Khó nhất',
        VocabStatusFilter.mostForgotten => 'Hay quên nhất',
      };
}

/// Huy hiệu chọn trạng thái học (SRS) để lọc Từ vựng — cùng kiểu tương tác
/// với [VocabCategoryFilterDropdown]/`LessonFilterDropdown` (chạm mở bottom
/// sheet chọn 1), nhưng danh sách lựa chọn cố định thay vì rút từ dữ liệu.
class VocabStatusFilterDropdown extends StatelessWidget {
  const VocabStatusFilterDropdown({
    super.key,
    required this.selected,
    required this.onSelected,
    required this.accentColor,
  });

  final VocabStatusFilter? selected;
  final ValueChanged<VocabStatusFilter?> onSelected;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: InkWell(
        borderRadius: BorderRadius.circular(100),
        onTap: () => _showPicker(context),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            color: accentColor,
            borderRadius: BorderRadius.circular(100),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                selected?.label ?? 'Trạng thái học',
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 13.5,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 4),
              const Icon(Icons.expand_more, size: 18, color: Colors.white),
            ],
          ),
        ),
      ),
    );
  }

  void _showPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      backgroundColor: AppColors.card,
      builder: (_) => _StatusPickerSheet(
        selected: selected,
        onSelected: onSelected,
        accentColor: accentColor,
      ),
    );
  }
}

class _StatusPickerSheet extends StatelessWidget {
  const _StatusPickerSheet({
    required this.selected,
    required this.onSelected,
    required this.accentColor,
  });

  final VocabStatusFilter? selected;
  final ValueChanged<VocabStatusFilter?> onSelected;
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
            child: Text(
              'Chọn trạng thái học',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: AppColors.ink,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
            child: Column(
              children: [
                _Row(
                  label: 'Tất cả trạng thái',
                  isSelected: selected == null,
                  color: accentColor,
                  onTap: () {
                    onSelected(null);
                    Navigator.of(context).pop();
                  },
                ),
                for (final status in VocabStatusFilter.values)
                  _Row(
                    label: status.label,
                    isSelected: selected == status,
                    color: accentColor,
                    onTap: () {
                      onSelected(status);
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
    required this.isSelected,
    required this.color,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(
        label,
        style: const TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 14.5,
          color: AppColors.ink,
        ),
      ),
      trailing: isSelected ? Icon(Icons.check_circle, color: color) : null,
      onTap: onTap,
    );
  }
}
