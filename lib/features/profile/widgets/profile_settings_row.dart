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
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final muted = isDark ? colors.onSurfaceVariant : AppColors.inkSoft;
    final title = isDark ? colors.onSurface : AppColors.ink;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        child: Row(
          children: [
            Icon(icon, size: 18, color: labelColor ?? muted),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: labelColor ?? title,
                ),
              ),
            ),
            if (trailingText != null)
              Text(
                trailingText!,
                style: TextStyle(fontSize: 12, color: muted),
              ),
            if (onTap != null) ...[
              const SizedBox(width: 4),
              Icon(
                Icons.chevron_right_rounded,
                size: 16,
                color: isDark ? colors.outline : AppColors.inkFaint,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
