import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../providers/ai_insights_providers.dart';

/// Gợi ý ôn tập rule-based — chọn kỹ năng yếu nhất từ [weakAreaCountsProvider]
/// (ease factor SM-2 thật, không gọi LLM nên không tốn quota AI). Dùng
/// chung giữa AI Insights (Profile) và Home ("AI Recommendation" rút gọn).
class WeakAreaSuggestionCard extends StatelessWidget {
  const WeakAreaSuggestionCard({super.key, required this.weak});

  final WeakAreaCounts weak;

  @override
  Widget build(BuildContext context) {
    final String label;
    final String route;
    if (weak.grammar >= weak.vocab && weak.grammar >= weak.kanji) {
      label = 'Ngữ pháp';
      route = '/grammar';
    } else if (weak.kanji >= weak.vocab) {
      label = 'Kanji';
      route = '/kanji/review';
    } else {
      label = 'Từ vựng';
      route = '/vocabulary/review';
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF4C7EF0), Color(0xFF6C5CE7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 26),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$label đang là điểm yếu nhất của bạn',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 13.5,
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  'Ôn lại ngay để không quên thêm',
                  style: TextStyle(color: Colors.white70, fontSize: 11.5),
                ),
              ],
            ),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.card,
              foregroundColor: AppColors.indigo,
              padding: const EdgeInsets.symmetric(horizontal: 14),
            ),
            onPressed: () => context.push(route),
            child: const Text('Ôn ngay'),
          ),
        ],
      ),
    );
  }
}
