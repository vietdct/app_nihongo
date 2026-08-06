import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../grammar/providers/grammar_progress_providers.dart';
import '../home/providers/profile_providers.dart';
import '../kanji/providers/kanji_progress_providers.dart';
import '../vocabulary/providers/vocab_progress_providers.dart';

/// Tab "Ôn tập" — điểm vào ôn lại nội dung đã học, theo mockup "Nihongo App
/// Redesign" nhưng phụ đề luôn lấy số liệu thật (số từ/kanji đã thuộc, số
/// mẫu ngữ pháp đã đánh dấu sao), không bịa như nội dung tĩnh trong mockup
/// gốc. Không có dòng "AI Kaiwa" — trùng đích đến với tab Kaiwa ở footer
/// (cùng `/kaiwa` → `KaiwaHomeScreen`), đã bỏ theo yêu cầu người dùng
/// (2026-08-06) để đỡ trùng lặp.
class ReviewScreen extends ConsumerWidget {
  const ReviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vocabProgress =
        ref.watch(vocabProgressProvider).valueOrNull ?? const {};
    final kanjiProgress =
        ref.watch(kanjiProgressProvider).valueOrNull ?? const {};
    final grammarProgress =
        ref.watch(grammarProgressProvider).valueOrNull ?? const {};
    final profile = ref.watch(profileProvider).valueOrNull;

    final knownKanji =
        kanjiProgress.values.where((p) => p.isKnown == true).length;
    final starredGrammar =
        grammarProgress.values.where((p) => p.starred).length;

    // "Đến hạn" chỉ tính mục đã từng ôn qua SRS ít nhất 1 lần (reviewCount >
    // 0) và nay đã tới/qua hạn — mục chưa từng ôn không tính là "đến hạn".
    final dueVocab = vocabProgress.values
        .where((p) => p.reviewCount > 0 && p.isDueNow)
        .length;
    final dueKanji = kanjiProgress.values
        .where((p) => p.reviewCount > 0 && p.isDueNow)
        .length;
    final dueGrammar = grammarProgress.values
        .where((p) => p.reviewCount > 0 && p.isDueNow)
        .length;
    final totalDue = dueVocab + dueKanji + dueGrammar;

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(title: const Text('Ôn tập')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
        children: [
          Row(
            children: [
              Expanded(
                child: _StatTile(
                  icon: Icons.event_available_outlined,
                  iconColor: AppColors.accent,
                  value: '$totalDue',
                  label: 'Đến hạn hôm nay',
                  onTap: () => context.push('/review/today'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _StatTile(
                  icon: Icons.local_fire_department_outlined,
                  iconColor: AppColors.accentStrong,
                  value: '${profile?.streakCount ?? 0}',
                  label: 'Chuỗi ngày',
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _ReviewRow(
            icon: Icons.auto_awesome_outlined,
            iconBg: AppColors.accentSoft,
            iconColor: AppColors.accentStrong,
            title: 'Smart Review',
            subtitle: 'Để AI chọn mục cần ôn hôm nay',
            onTap: () => context.push('/review/smart'),
          ),
          const SizedBox(height: 10),
          _ReviewRow(
            icon: Icons.brush_outlined,
            iconBg: AppColors.indigoSoft,
            iconColor: AppColors.indigo,
            title: 'Flashcard Kanji',
            subtitle: dueKanji > 0
                ? '$dueKanji chữ đến hạn ôn · $knownKanji chữ đã thuộc'
                : '$knownKanji chữ đã thuộc · Nét viết + Hán Việt',
            onTap: () => context.push('/kanji'),
          ),
          const SizedBox(height: 10),
          _ReviewRow(
            icon: Icons.menu_book_outlined,
            iconBg: AppColors.plumSoft,
            iconColor: AppColors.plum,
            title: 'Ngữ pháp',
            subtitle: dueGrammar > 0
                ? '$dueGrammar mẫu đến hạn ôn · $starredGrammar mẫu đã đánh dấu'
                : '$starredGrammar mẫu đã đánh dấu · Xem lại mẫu câu',
            onTap: () => context.push('/grammar'),
          ),
          const SizedBox(height: 10),
          _ReviewRow(
            icon: Icons.trending_down_outlined,
            iconBg: AppColors.chip,
            iconColor: AppColors.accentStrong,
            title: 'Điểm yếu',
            subtitle: 'Từ/chữ/mẫu bạn hay quên nhất',
            onTap: () => context.push('/review/weak-points'),
          ),
          const SizedBox(height: 10),
          _ReviewRow(
            icon: Icons.sticky_note_2_outlined,
            iconBg: AppColors.chip,
            iconColor: AppColors.danger,
            title: 'Sổ tay lỗi',
            subtitle: 'Xem lại các lỗi đã ghi nhận',
            onTap: () => context.push('/review/mistakes'),
          ),
          const SizedBox(height: 10),
          _ReviewRow(
            icon: Icons.bar_chart_outlined,
            iconBg: AppColors.chip,
            iconColor: AppColors.indigo,
            title: 'Thống kê ôn tập',
            subtitle: 'Độ thành thục, lỗi theo module và theo ngày',
            onTap: () => context.push('/review/statistics'),
          ),
          const SizedBox(height: 10),
          _ReviewRow(
            icon: Icons.quiz_outlined,
            iconBg: AppColors.chip,
            iconColor: AppColors.plum,
            title: 'Quiz tổng hợp',
            subtitle: 'Trắc nghiệm trộn Từ vựng/Kanji/Ngữ pháp đã học',
            onTap: () => context.push('/review/mixed-quiz'),
          ),
          const SizedBox(height: 10),
          _ReviewRow(
            icon: Icons.emoji_events_outlined,
            iconBg: AppColors.indigoSoft,
            iconColor: AppColors.indigo,
            title: 'Thi thử JLPT',
            subtitle: 'Mô phỏng đề thi N5–N1 theo nhiều chế độ',
            onTap: () => context.push('/review/jlpt-exam'),
          ),
        ],
      ),
    );
  }
}

class _ReviewRow extends StatelessWidget {
  const _ReviewRow({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final disabled = onTap == null;
    return Opacity(
      opacity: disabled ? 0.55 : 1,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.border, width: 1.0),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(14),
                ),
                alignment: Alignment.center,
                child: Icon(icon, color: iconColor, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.inkSoft,
                      ),
                    ),
                  ],
                ),
              ),
              if (!disabled)
                const Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.inkFaint,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.icon,
    required this.iconColor,
    required this.value,
    required this.label,
    this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final String value;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.border, width: 1.0),
        ),
        child: Row(
          children: [
            Icon(icon, color: iconColor, size: 22),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                    color: AppColors.ink,
                  ),
                ),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.inkSoft,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
