import 'dart:async';

import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';

/// TextField tra cứu, cô lập khỏi rebuild của widget cha (ConsumerWidget theo
/// dõi chính provider mà field này ghi vào). Nếu không cô lập, mỗi phím gõ sẽ
/// rebuild lại toàn bộ danh sách bên dưới ngay trong cùng khung hình — đủ
/// giật để làm gãy composing của bộ gõ tiếng Việt (dấu nhảy lung tung khi gõ
/// Telex/VNI). [onChanged] chỉ được gọi sau khi ngừng gõ [debounce].
class DebouncedSearchField extends StatefulWidget {
  const DebouncedSearchField({
    super.key,
    required this.hintText,
    required this.onChanged,
    this.debounce = const Duration(milliseconds: 250),
  });

  final String hintText;
  final ValueChanged<String> onChanged;
  final Duration debounce;

  @override
  State<DebouncedSearchField> createState() => _DebouncedSearchFieldState();
}

class _DebouncedSearchFieldState extends State<DebouncedSearchField> {
  final _controller = TextEditingController();
  Timer? _debounceTimer;

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _handleChanged(String value) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(widget.debounce, () => widget.onChanged(value));
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      style: const TextStyle(color: AppColors.ink, fontSize: 15),
      decoration: InputDecoration(
        prefixIcon: const Icon(Icons.search, color: AppColors.inkFaint),
        hintText: widget.hintText,
        hintStyle: const TextStyle(color: AppColors.inkFaint, fontSize: 14.5),
        isDense: true,
      ),
      onChanged: _handleChanged,
    );
  }
}
