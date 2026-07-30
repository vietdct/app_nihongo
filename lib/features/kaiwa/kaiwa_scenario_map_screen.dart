import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../../domain/entities/kaiwa_scenario.dart';
import 'providers/kaiwa_content_providers.dart';

/// Màu theo category thật trong bảng `kaiwa_scenarios` — mỗi "vùng địa điểm"
/// một màu, giống chú giải trên bản đồ. Category lạ (nếu sau này thêm mới
/// chưa map màu) rơi về teal (màu gốc của AI Kaiwa), không vỡ layout.
const _categoryColors = <String, Color>{
  'Cơ bản': AppColors.teal,
  'Tự do': AppColors.accent,
  'Đời sống': AppColors.moss,
  'Du lịch': AppColors.indigo,
  'Công việc': AppColors.plum,
};

Color _colorForCategory(String category) => _categoryColors[category] ?? AppColors.teal;

/// Chọn tình huống hội thoại — trình bày như "bản đồ địa điểm" thay vì danh
/// sách phẳng: mỗi category thật (Cơ bản/Tự do/Đời sống/Du lịch/Công việc)
/// là một vùng riêng, mỗi tình huống là một "địa điểm" với glyph + cấp độ
/// khuyến nghị lấy thẳng từ dữ liệu thật, không có địa điểm nào là bịa thêm
/// ngoài các scenario đã có trong Supabase.
class KaiwaScenarioMapScreen extends ConsumerWidget {
  const KaiwaScenarioMapScreen({super.key, this.seedWord});

  /// Từ vựng muốn luyện dùng trong hội thoại — chuyển tiếp từ thẻ "Từ vựng
  /// hôm nay" (VocabularyHomeScreen), truyền tiếp qua roleplay tới chat.
  final String? seedWord;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scenariosAsync = ref.watch(kaiwaScenariosProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Chọn tình huống')),
      body: scenariosAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Lỗi tải tình huống: $e')),
        data: (scenarios) {
          final byCategory = <String, List<KaiwaScenario>>{};
          for (final s in scenarios) {
            (byCategory[s.category] ??= []).add(s);
          }
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            children: [
              if (seedWord != null) ...[
                _SeedWordBanner(word: seedWord!),
                const SizedBox(height: 18),
              ],
              for (final entry in byCategory.entries) ...[
                _CategorySection(
                  category: entry.key,
                  scenarios: entry.value,
                  onTap: (s) => context.push(
                    '/kaiwa/topics/${s.id}/roleplay',
                    extra: seedWord,
                  ),
                ),
                const SizedBox(height: 22),
              ],
            ],
          );
        },
      ),
    );
  }
}

/// Nhắc lại từ vựng sẽ gợi ý AI dùng trong hội thoại — hiện ngay ở bước chọn
/// tình huống đầu tiên để người dùng biết vì sao lại tới đây từ thẻ "Từ vựng
/// hôm nay" thay vì im lặng chuyển màn (xem `seedWord` ở `kaiwa_chat_service.dart`).
class _SeedWordBanner extends StatelessWidget {
  const _SeedWordBanner({required this.word});

  final String word;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(color: AppColors.mossSoft, borderRadius: BorderRadius.circular(14)),
      child: Row(
        children: [
          const Icon(Icons.lightbulb_outline_rounded, size: 16, color: AppColors.moss),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Chọn 1 tình huống để luyện dùng từ "$word" trong hội thoại',
              style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.moss),
            ),
          ),
        ],
      ),
    );
  }
}

class _CategorySection extends StatelessWidget {
  const _CategorySection({required this.category, required this.scenarios, required this.onTap});

  final String category;
  final List<KaiwaScenario> scenarios;
  final ValueChanged<KaiwaScenario> onTap;

  @override
  Widget build(BuildContext context) {
    final color = _colorForCategory(category);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 8),
            Text(
              category.toUpperCase(),
              style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: color, letterSpacing: 0.6),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (final s in scenarios) _PlaceCard(scenario: s, color: color, onTap: () => onTap(s)),
          ],
        ),
      ],
    );
  }
}

class _PlaceCard extends StatelessWidget {
  const _PlaceCard({required this.scenario, required this.color, required this.onTap});

  final KaiwaScenario scenario;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Container(
        width: 156,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.border, width: 0.8),
          boxShadow: [BoxShadow(color: color.withValues(alpha: 0.10), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(color: color.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(12)),
              alignment: Alignment.center,
              child: Text(scenario.glyph, style: AppFonts.zenMaruGothic(fontSize: 18, color: color, fontWeight: FontWeight.w700)),
            ),
            const SizedBox(height: 10),
            Text(
              scenario.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: AppColors.ink, height: 1.25),
            ),
            const SizedBox(height: 4),
            Text(
              scenario.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 11, color: AppColors.inkSoft, height: 1.3),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(color: AppColors.chip, borderRadius: BorderRadius.circular(100)),
              child: Text(scenario.levelMin, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.inkSoft)),
            ),
          ],
        ),
      ),
    );
  }
}
