import 'package:flutter/material.dart';

/// Badge bấm-để-mở-bottom-sheet dùng chung cho các bộ lọc (bài học, chủ đề,
/// trạng thái học...) — tách ra để 3 badge trên màn Từ vựng có thể xếp thành
/// hàng ngang đều nhau ([fillWidth]) mà vẫn giữ đúng kiểu dáng khi đứng một
/// mình (ví dụ [LessonFilterDropdown] trên màn Ngữ pháp/Kanji).
class FilterPillButton extends StatelessWidget {
  const FilterPillButton({
    super.key,
    required this.label,
    required this.accentColor,
    required this.onTap,
    this.fillWidth = false,
  });

  final String label;
  final Color accentColor;
  final VoidCallback onTap;
  final bool fillWidth;

  @override
  Widget build(BuildContext context) {
    final pill = Material(
      color: accentColor,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          height: 42,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          alignment: Alignment.center,
          child: Row(
            mainAxisSize: fillWidth ? MainAxisSize.max : MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 12.5,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 2),
              const Icon(Icons.expand_more_rounded, size: 17, color: Colors.white),
            ],
          ),
        ),
      ),
    );

    if (fillWidth) return pill;
    return Align(alignment: Alignment.centerLeft, child: pill);
  }
}
