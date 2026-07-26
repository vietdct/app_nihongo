import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

/// Node tròn cho "đường dẫn kỹ năng" dạng zigzag trên Home (theo mockup) —
/// thay cho lưới ô vuông cũ. Không phân biệt trạng thái đã học/đang học/khoá
/// vì app chưa có dữ liệu tiến độ theo từng mục — tất cả node hiện cùng 1
/// kiểu "sẵn sàng mở", căn trái/phải xen kẽ do widget cha (Home) quyết định.
class SkillPathNode extends StatelessWidget {
  const SkillPathNode({
    super.key,
    required this.glyph,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final String glyph;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(100),
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 84,
            height: 84,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 4),
              boxShadow: [
                BoxShadow(color: color.withValues(alpha: 0.35), blurRadius: 16, offset: const Offset(0, 6)),
              ],
            ),
            alignment: Alignment.center,
            child: Text(glyph, style: AppFonts.zenMaruGothic(fontSize: 28, color: Colors.white)),
          ),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.ink)),
        ],
      ),
    );
  }
}
