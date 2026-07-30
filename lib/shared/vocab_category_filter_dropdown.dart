import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';

/// Huy hiệu chọn chủ đề (category) để lọc Từ vựng — cùng kiểu tương tác với
/// [LessonFilterDropdown] (chạm mở bottom sheet chọn), nhưng nguồn dữ liệu là
/// danh sách chuỗi category rút ra trực tiếp từ Vocabulary, không cần entity
/// riêng như Lesson.
class VocabCategoryFilterDropdown extends StatelessWidget {
  const VocabCategoryFilterDropdown({
    super.key,
    required this.categories,
    required this.selected,
    required this.hasUncategorized,
    required this.onSelected,
    required this.accentColor,
  });

  final List<String> categories;
  final String? selected;
  final bool hasUncategorized;
  final ValueChanged<String?> onSelected;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    if (categories.isEmpty) return const SizedBox.shrink();
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
                selected ?? 'Tất cả chủ đề',
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
      builder: (_) => _CategoryPickerSheet(
        categories: categories,
        selected: selected,
        hasUncategorized: hasUncategorized,
        onSelected: onSelected,
        accentColor: accentColor,
      ),
    );
  }
}

class _CategoryPickerSheet extends StatelessWidget {
  const _CategoryPickerSheet({
    required this.categories,
    required this.selected,
    required this.hasUncategorized,
    required this.onSelected,
    required this.accentColor,
  });

  final List<String> categories;
  final String? selected;
  final bool hasUncategorized;
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
            child: Text(
              'Chọn chủ đề',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: AppColors.ink,
              ),
            ),
          ),
          Flexible(
            child: ListView(
              shrinkWrap: true,
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              children: [
                _Row(
                  label: 'Tất cả chủ đề',
                  isSelected: selected == null,
                  color: accentColor,
                  onTap: () {
                    onSelected(null);
                    Navigator.of(context).pop();
                  },
                ),
                for (final category in categories)
                  _Row(
                    label: category,
                    isSelected: selected == category,
                    color: accentColor,
                    onTap: () {
                      onSelected(category);
                      Navigator.of(context).pop();
                    },
                  ),
                if (hasUncategorized)
                  _Row(
                    label: 'Chưa phân loại',
                    isSelected: selected == uncategorizedFilter,
                    color: accentColor,
                    onTap: () {
                      onSelected(uncategorizedFilter);
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

/// Sentinel cho "chưa có category" — khác `null` (nghĩa là "tất cả").
const String uncategorizedFilter = '';

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
