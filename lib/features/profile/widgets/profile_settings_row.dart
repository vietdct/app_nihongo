import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

class ProfileSettingsRow extends StatelessWidget {
  const ProfileSettingsRow({
    super.key,
    required this.icon,
    required this.label,
    this.trailingText,
    this.labelColor,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final String? trailingText;
  final Color? labelColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        child: Row(
          children: [
            Icon(icon, size: 18, color: labelColor ?? AppColors.inkSoft),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: labelColor ?? AppColors.ink,
                ),
              ),
            ),
            if (trailingText != null)
              Text(
                trailingText!,
                style: const TextStyle(fontSize: 12, color: AppColors.inkSoft),
              ),
            if (onTap != null) ...[
              const SizedBox(width: 4),
              const Icon(
                Icons.chevron_right_rounded,
                size: 16,
                color: AppColors.inkFaint,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
