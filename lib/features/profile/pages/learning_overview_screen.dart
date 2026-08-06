import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../grammar/providers/grammar_progress_providers.dart';
import '../../kaiwa/providers/kaiwa_conversation_providers.dart';
import '../../kanji/providers/kanji_progress_providers.dart';
import '../../vocabulary/providers/vocab_progress_providers.dart';
import '../providers/jlpt_progress_providers.dart';
import '../widgets/profile_collection_row.dart';
import '../widgets/profile_section_label.dart';
import '../widgets/profile_stat_tile.dart';

/// Nhóm "Học tập" — tổng quan tiến độ + chi tiết theo từng cấp JLPT + lối
/// vào Bookmarks/Lịch sử. Chỉ hiển thị số liệu tính được thật từ dữ liệu đã
/// có (`vocab_progress`, `kanji_progress`, `grammar_progress`, hội thoại
/// Kaiwa) — không có Reading/Listening/Writing/Speaking riêng vì app chưa
/// tách track theo kỹ năng đó.
class LearningOverviewScreen extends ConsumerWidget {
  const LearningOverviewScreen({super.key});

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
    final levelProgressAsync = ref.watch(jlptLevelProgressProvider);

    final knownVocab =
        vocabProgress.values.where((p) => p.isKnown == true).length;
    final knownKanji =
        kanjiProgress.values.where((p) => p.isKnown == true).length;
    final knownGrammar =
        grammarProgress.values.where((p) => p.isKnown == true).length;
    final starredVocab = vocabProgress.values.where((p) => p.starred).length;
    final starredGrammar =
        grammarProgress.values.where((p) => p.starred).length;

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        backgroundColor: AppColors.canvas,
        title: const Text('Học tập'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        children: [
          const ProfileSectionLabel('Tổng quan'),
          const SizedBox(height: 10),
          Row(
            children: [
              ProfileStatTile(
                value: '$knownVocab',
                label: 'Từ vựng',
                color: AppColors.moss,
              ),
              const SizedBox(width: 8),
              ProfileStatTile(
                value: '$knownKanji',
                label: 'Kanji',
                color: AppColors.indigo,
              ),
              const SizedBox(width: 8),
              ProfileStatTile(
                value: '$knownGrammar',
                label: 'Ngữ pháp',
                color: AppColors.plum,
              ),
              const SizedBox(width: 8),
              ProfileStatTile(
                value: '${kaiwaConversations.length}',
                label: 'Kaiwa',
                color: AppColors.accent,
              ),
            ],
          ),
          const SizedBox(height: 22),
          const ProfileSectionLabel('Tiến độ theo cấp JLPT'),
          const SizedBox(height: 10),
          levelProgressAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            ),
            error: (e, _) => Text('Lỗi tải tiến độ: $e'),
            data: (levels) => Column(
              children: [
                for (final lp in levels) ...[
                  _LevelProgressRow(progress: lp),
                  const SizedBox(height: 8),
                ],
              ],
            ),
          ),
          const SizedBox(height: 22),
          const ProfileSectionLabel('Bộ sưu tập & lịch sử'),
          const SizedBox(height: 10),
          ProfileCollectionRow(
            emoji: '⭐',
            title: 'Đã đánh dấu',
            count: '${starredVocab + starredGrammar} mục',
            onTap: () => context.push('/profile/bookmarks'),
          ),
          const SizedBox(height: 8),
          ProfileCollectionRow(
            emoji: '📜',
            title: 'Lịch sử học tập',
            count: '${kaiwaConversations.length} buổi Kaiwa · thi thử JLPT',
            onTap: () => context.push('/profile/history'),
          ),
        ],
      ),
    );
  }
}

class _LevelProgressRow extends StatelessWidget {
  const _LevelProgressRow({required this.progress});

  final LevelProgress progress;

  @override
  Widget build(BuildContext context) {
    final pct = (progress.ratio * 100).round();
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border, width: 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                progress.level.code,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                  color: AppColors.ink,
                ),
              ),
              Text(
                '${progress.known}/${progress.total} · $pct%',
                style: const TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.inkSoft,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress.ratio,
              minHeight: 6,
              backgroundColor: AppColors.border,
              valueColor: const AlwaysStoppedAnimation(AppColors.accent),
            ),
          ),
        ],
      ),
    );
  }
}
