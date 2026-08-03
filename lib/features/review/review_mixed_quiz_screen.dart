import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import 'providers/mixed_quiz_providers.dart';

/// Màn chọn số câu cho Quiz tổng hợp — trộn Từ vựng/Kanji/Ngữ pháp ĐÃ HỌC
/// (có progress thật) ở cấp độ hiện tại thành 1 bài trắc nghiệm duy nhất,
/// khác `/quiz/:category` (dùng toàn bộ nội dung cấp độ, tách riêng từng
/// mảng, không lọc theo đã học). Câu hỏi/chấm điểm dùng lại nguyên
/// `QuizGenerator`/`QuizScreen` đã có ở module Quiz — xem
/// `docs/MIXED_QUIZ_DESIGN.md` Task 1.
class ReviewMixedQuizScreen extends ConsumerWidget {
  const ReviewMixedQuizScreen({super.key});

  static const _counts = [5, 10, 20, 50];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final studiedCount = ref.watch(mixedQuizStudiedCountProvider);
    final weakCount = ref.watch(weakPointMixedQuizAvailableCountProvider);

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(title: const Text('Quiz tổng hợp')),
      body: studiedCount == 0
          ? const _EmptyMixedQuizState()
          : ListView(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
              children: [
                if (weakCount > 0) ...[
                  _WeakPointChallengeCard(
                    count: weakCount,
                    onTap: () {
                      final playCount = weakCount > 20 ? 20 : weakCount;
                      context
                          .push('/review/mixed-quiz/weak-points/$playCount');
                    },
                  ),
                  const SizedBox(height: 16),
                ],
                Text(
                  'Trộn ngẫu nhiên $studiedCount mục Từ vựng/Kanji/Ngữ pháp bạn đã học ở cấp độ hiện tại. Chọn số câu:',
                  style: const TextStyle(fontSize: 13, color: AppColors.inkSoft),
                ),
                const SizedBox(height: 16),
                for (final count in _counts) ...[
                  _CountRow(
                    count: count,
                    available: studiedCount,
                    onTap: () => context.push('/review/mixed-quiz/$count'),
                  ),
                  const SizedBox(height: 10),
                ],
                const SizedBox(height: 6),
                OutlinedButton.icon(
                  onPressed: () => context.push('/review/mixed-quiz/custom'),
                  icon: const Icon(Icons.tune_rounded, size: 18),
                  label: const Text('Quiz Tuỳ chỉnh — chọn loại câu hỏi/số câu/chế độ chơi'),
                ),
              ],
            ),
    );
  }
}

/// Entry point "Thử thách điểm yếu" (Task 8) — AI chọn thay bạn mục đến hạn
/// hoặc đang yếu (`isSmartPick`, xem `mixed_quiz_providers.dart`), giới hạn
/// tối đa 20 câu/lượt (đủ 1 phiên ôn tập trung, không bắt làm hết mọi mục
/// yếu cùng lúc) — không hiện số liệu giả, [count] luôn là số mục yếu thật.
class _WeakPointChallengeCard extends StatelessWidget {
  const _WeakPointChallengeCard({required this.count, required this.onTap});

  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: AppColors.dangerSoft,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.danger, width: 1.0),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: const BoxDecoration(
                color: AppColors.danger,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: const Icon(Icons.local_fire_department_rounded,
                  color: Colors.white, size: 24,),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Thử thách điểm yếu',
                    style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                        color: AppColors.ink,),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'AI chọn $count mục bạn đang yếu/đến hạn ôn',
                    style:
                        const TextStyle(fontSize: 11.5, color: AppColors.inkSoft),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: AppColors.danger),
          ],
        ),
      ),
    );
  }
}

class _EmptyMixedQuizState extends StatelessWidget {
  const _EmptyMixedQuizState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.quiz_outlined, size: 48, color: AppColors.accent),
            SizedBox(height: 12),
            Text(
              'Chưa có mục nào đã học',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 16,
                color: AppColors.ink,
              ),
            ),
            SizedBox(height: 6),
            Text(
              'Học qua ít nhất 1 từ vựng, Kanji hoặc ngữ pháp ở cấp độ hiện tại để bắt đầu Quiz tổng hợp.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: AppColors.inkSoft),
            ),
          ],
        ),
      ),
    );
  }
}

class _CountRow extends StatelessWidget {
  const _CountRow({
    required this.count,
    required this.available,
    required this.onTap,
  });

  final int count;
  final int available;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final actual = count > available ? available : count;
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
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.chip,
                borderRadius: BorderRadius.circular(14),
              ),
              alignment: Alignment.center,
              child: Text(
                '$actual',
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                  color: AppColors.ink,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$count câu',
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                      color: AppColors.ink,
                    ),
                  ),
                  if (actual < count) ...[
                    const SizedBox(height: 2),
                    Text(
                      'Chỉ đủ dữ liệu cho $actual câu',
                      style:
                          const TextStyle(fontSize: 11, color: AppColors.inkSoft),
                    ),
                  ],
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: AppColors.inkFaint),
          ],
        ),
      ),
    );
  }
}
