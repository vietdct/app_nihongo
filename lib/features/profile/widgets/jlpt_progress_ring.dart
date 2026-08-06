import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../providers/jlpt_progress_providers.dart';

class JlptProgressRing extends StatelessWidget {
  const JlptProgressRing({super.key, required this.progress});

  final LevelProgress progress;

  @override
  Widget build(BuildContext context) {
    final pct = (progress.ratio * 100).round();
    return Column(
      children: [
        SizedBox(
          width: 42,
          height: 42,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CircularProgressIndicator(
                value: progress.ratio,
                strokeWidth: 4,
                backgroundColor: AppColors.border,
                valueColor: const AlwaysStoppedAnimation(AppColors.accent),
              ),
              Text(
                '$pct%',
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 9,
                  color: AppColors.ink,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          progress.level.code,
          style: const TextStyle(
            fontSize: 8.5,
            fontWeight: FontWeight.w700,
            color: AppColors.inkSoft,
          ),
        ),
      ],
    );
  }
}
