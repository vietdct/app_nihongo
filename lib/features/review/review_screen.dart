import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../grammar/providers/grammar_progress_providers.dart';
import '../kaiwa/providers/kaiwa_conversation_providers.dart';
import '../kanji/providers/kanji_progress_providers.dart';
import '../vocabulary/providers/vocab_progress_providers.dart';

/// Tab "Ôn tập" — điểm vào ôn lại nội dung đã học, theo mockup "Nihongo App
/// Redesign" nhưng phụ đề luôn lấy số liệu thật (số từ/kanji đã thuộc, số
/// mẫu ngữ pháp đã đánh dấu sao, số buổi Kaiwa đã hội thoại), không bịa như
/// nội dung tĩnh trong mockup gốc.
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
    final kaiwaConversations =
        ref.watch(kaiwaConversationsProvider).valueOrNull ?? const [];

    final knownVocab =
        vocabProgress.values.where((p) => p.isKnown == true).length;
    final knownKanji =
        kanjiProgress.values.where((p) => p.isKnown == true).length;
    final starredGrammar =
        grammarProgress.values.where((p) => p.starred).length;

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(title: const Text('Ôn tập')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
        children: [
          _ReviewRow(
            icon: Icons.style_outlined,
            iconBg: AppColors.mossSoft,
            iconColor: AppColors.moss,
            title: 'Flashcard Từ vựng',
            subtitle: '$knownVocab từ đã thuộc · Lật thẻ ôn lại',
            onTap: () => context.push('/vocabulary/flashcards'),
          ),
          const SizedBox(height: 10),
          _ReviewRow(
            icon: Icons.brush_outlined,
            iconBg: AppColors.indigoSoft,
            iconColor: AppColors.indigo,
            title: 'Flashcard Kanji',
            subtitle: '$knownKanji chữ đã thuộc · Nét viết + Hán Việt',
            onTap: () => context.push('/kanji'),
          ),
          const SizedBox(height: 10),
          _ReviewRow(
            icon: Icons.menu_book_outlined,
            iconBg: AppColors.plumSoft,
            iconColor: AppColors.plum,
            title: 'Ngữ pháp',
            subtitle: '$starredGrammar mẫu đã đánh dấu · Xem lại mẫu câu',
            onTap: () => context.push('/grammar'),
          ),
          const SizedBox(height: 10),
          _ReviewRow(
            icon: Icons.forum_outlined,
            iconBg: AppColors.tealSoft,
            iconColor: AppColors.teal,
            title: 'AI Kaiwa',
            subtitle: '${kaiwaConversations.length} buổi hội thoại đã lưu',
            onTap: () => context.push('/kaiwa'),
          ),
          const SizedBox(height: 10),
          const _ReviewRow(
            icon: Icons.quiz_outlined,
            iconBg: AppColors.chip,
            iconColor: AppColors.inkFaint,
            title: 'Quiz tổng hợp',
            subtitle: 'Sắp ra mắt',
            onTap: null,
          ),
          const SizedBox(height: 10),
          const _ReviewRow(
            icon: Icons.fact_check_outlined,
            iconBg: AppColors.chip,
            iconColor: AppColors.inkFaint,
            title: 'Thi thử JLPT',
            subtitle: 'Sắp ra mắt',
            onTap: null,
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
