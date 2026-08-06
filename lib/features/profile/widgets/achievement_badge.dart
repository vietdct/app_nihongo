import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

class AchievementBadge extends StatelessWidget {
  const AchievementBadge({
    super.key,
    required this.earned,
    required this.icon,
    required this.label,
    required this.sub,
  });

  final bool earned;
  final IconData icon;
  final String label;
  final String sub;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 72,
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: earned ? AppColors.accentSoft : AppColors.chip,
              borderRadius: BorderRadius.circular(16),
              border: earned
                  ? null
                  : Border.all(
                      color: AppColors.border,
                      width: 2,
                      style: BorderStyle.solid,
                    ),
            ),
            alignment: Alignment.center,
            child: Icon(
              icon,
              size: 22,
              color: earned ? AppColors.accentStrong : AppColors.inkFaint,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 1,
            style: const TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              color: AppColors.ink,
            ),
          ),
          Text(
            sub,
            textAlign: TextAlign.center,
            maxLines: 1,
            style: const TextStyle(fontSize: 8, color: AppColors.inkSoft),
          ),
        ],
      ),
    );
  }
}
