import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import 'jp_speak_button.dart';

/// Câu ví dụ tiếng Nhật kèm nút loa nhỏ bên phải (audio cloud tạo sẵn, không có
/// thì dùng TTS máy — xem [JpSpeakButton]). Dùng thay `Text` cho câu ví dụ.
class JpExampleText extends StatelessWidget {
  const JpExampleText(this.text, {super.key, this.style});

  final String text;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: Text(text, style: style)),
        JpSpeakButton(
          text: text,
          color: AppColors.inkSoft,
          size: 20,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints.tightFor(width: 32, height: 28),
        ),
      ],
    );
  }
}
