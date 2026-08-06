import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../kaiwa/providers/kaiwa_conversation_providers.dart';
import '../providers/exam_history_providers.dart';
import '../widgets/profile_section_label.dart';

/// Nhóm "Học tập" › Lịch sử — các lượt Thi thử JLPT đã nộp (bảng
/// `jlpt_exam_sessions`, trước đây không có màn nào liệt kê lại) + số buổi
/// AI Kaiwa với lối vào màn lịch sử Kaiwa đầy đủ đã có sẵn. Không mở lại
/// bài review chi tiết từ đây vì `ExamReviewScreen` cần dữ liệu snapshot
/// đầy đủ chỉ có ngay sau khi nộp bài (qua `state.extra`), không dựng lại
/// được chỉ từ `session id` lưu trong DB.
class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final examHistoryAsync = ref.watch(examSessionHistoryProvider);
    final kaiwaConversations =
        ref.watch(kaiwaConversationsProvider).valueOrNull ?? const [];

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        backgroundColor: AppColors.canvas,
        title: const Text('Lịch sử'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        children: [
          const ProfileSectionLabel('Thi thử JLPT'),
          const SizedBox(height: 10),
          examHistoryAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            ),
            error: (e, _) => Text('Lỗi tải lịch sử: $e'),
            data: (sessions) => sessions.isEmpty
                ? const _EmptyHint(text: 'Chưa có lượt thi thử nào đã nộp.')
                : Container(
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius: BorderRadius.circular(16),
                      border:
                          Border.all(color: AppColors.border, width: 1.0),
                    ),
                    child: Column(
                      children: [
                        for (var i = 0; i < sessions.length; i++) ...[
                          if (i > 0)
                            const Divider(
                              height: 1,
                              color: AppColors.border,
                            ),
                          _ExamHistoryRow(session: sessions[i]),
                        ],
                      ],
                    ),
                  ),
          ),
          const SizedBox(height: 22),
          const ProfileSectionLabel('AI Kaiwa'),
          const SizedBox(height: 10),
          InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () => context.push('/kaiwa/history'),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border, width: 1.0),
              ),
              child: Row(
                children: [
                  const Text('💬', style: TextStyle(fontSize: 20)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      '${kaiwaConversations.length} buổi hội thoại',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: AppColors.ink,
                      ),
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right_rounded,
                    size: 18,
                    color: AppColors.inkFaint,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ExamHistoryRow extends StatelessWidget {
  const _ExamHistoryRow({required this.session});

  final ExamSessionSummary session;

  @override
  Widget build(BuildContext context) {
    final score = session.totalScore;
    final d = session.submittedAt;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${examModeLabels[session.mode] ?? session.mode} · ${session.levelCode}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${d.day}/${d.month}/${d.year}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.inkSoft,
                  ),
                ),
              ],
            ),
          ),
          if (score != null)
            Text(
              '${score.$1}/${score.$2}',
              style: const TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 14,
                color: AppColors.accentStrong,
              ),
            ),
        ],
      ),
    );
  }
}

class _EmptyHint extends StatelessWidget {
  const _EmptyHint({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border, width: 1.0),
      ),
      child: Text(
        text,
        style: const TextStyle(fontSize: 12.5, color: AppColors.inkSoft),
      ),
    );
  }
}
