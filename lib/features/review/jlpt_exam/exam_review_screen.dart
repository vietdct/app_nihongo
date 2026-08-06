import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import 'models/exam_review_answer.dart';

/// Màn "Xem lại bài làm" riêng — mở từ nút cùng tên ở `ExamResultScreen`
/// (Task 7.6, cập nhật theo yêu cầu tách khỏi màn Kết quả thay vì hiện
/// inline). Lưới ô đánh số câu theo từng phần thi, câu sai tô đỏ và bấm
/// được để mở [_ReviewDetailSheet]; câu đúng tô trung tính, không bấm được.
class ExamReviewScreen extends StatelessWidget {
  const ExamReviewScreen({required this.sections, super.key});

  final List<ExamReviewSection> sections;

  static const _sectionLabels = {
    'vocabulary': 'Từ vựng',
    'grammar': 'Ngữ pháp',
    'reading': 'Đọc hiểu',
    'listening': 'Nghe hiểu',
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(title: const Text('Xem lại bài làm')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            'Câu tô đỏ là câu trả lời sai — bấm vào để xem đáp án đúng.',
            style: TextStyle(fontSize: 12, color: AppColors.inkSoft),
          ),
          const SizedBox(height: 14),
          for (final section in sections) ...[
            _ReviewSectionBlock(
              label: _sectionLabels[section.type] ?? section.type,
              section: section,
            ),
            const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }
}

class _ReviewSectionBlock extends StatelessWidget {
  const _ReviewSectionBlock({required this.label, required this.section});

  final String label;
  final ExamReviewSection section;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (var i = 0; i < section.answers.length; i++)
                _ReviewChip(
                  number: i + 1,
                  wrong: !section.answers[i].isCorrect,
                  onTap: section.answers[i].isCorrect
                      ? null
                      : () => showModalBottomSheet<void>(
                            context: context,
                            backgroundColor: AppColors.card,
                            isScrollControlled: true,
                            shape: const RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.vertical(top: Radius.circular(24)),
                            ),
                            builder: (_) =>
                                _ReviewDetailSheet(answer: section.answers[i]),
                          ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ReviewChip extends StatelessWidget {
  const _ReviewChip({
    required this.number,
    required this.wrong,
    required this.onTap,
  });

  final int number;
  final bool wrong;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: wrong ? AppColors.dangerSoft : AppColors.chip,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: wrong ? AppColors.danger : AppColors.border,
          ),
        ),
        child: Text(
          '$number',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 13,
            color: wrong ? AppColors.danger : AppColors.inkSoft,
          ),
        ),
      ),
    );
  }
}

/// Chi tiết 1 câu trả lời sai — hiện lại ngữ cảnh câu hỏi (đoạn văn Đọc hiểu
/// / transcript Nghe hiểu / chữ Nhật lớn cho Vocab-Grammar, cùng logic 3
/// nhánh với `_ExamBodyState.build()`) + đáp án đã chọn (đỏ) và đáp án đúng
/// (xanh lá). KHÔNG có lời giải thích thêm — dữ liệu hiện tại chỉ có đáp án
/// đúng, không có văn bản giải thích (quyết định khi làm tính năng này).
class _ReviewDetailSheet extends StatelessWidget {
  const _ReviewDetailSheet({required this.answer});

  final ExamReviewAnswer answer;

  @override
  Widget build(BuildContext context) {
    final q = answer.question;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              if (answer.selectedIndex == null)
                const Padding(
                  padding: EdgeInsets.only(bottom: 10),
                  child: Text(
                    'Bạn đã bỏ trống, không trả lời câu này.',
                    style: TextStyle(fontSize: 12, color: AppColors.inkSoft),
                  ),
                ),
              if (q.readingPassageBodyJa != null) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.canvas,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if ((q.readingPassageTitle ?? '').isNotEmpty) ...[
                        Text(
                          q.readingPassageTitle!,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 13,
                            color: AppColors.indigo,
                          ),
                        ),
                        const SizedBox(height: 6),
                      ],
                      Text(
                        q.readingPassageBodyJa!,
                        style: AppFonts.zenMaruGothic(
                          fontSize: 15,
                          color: AppColors.ink,
                        ).copyWith(height: 1.7),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  q.promptVi,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
              ] else if (q.dialogueTurns != null) ...[
                Text(
                  q.promptVi,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.canvas,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (final turn in q.dialogueTurns!)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Text(
                            '${turn.speaker}: ${turn.jp}',
                            style: AppFonts.zenMaruGothic(
                              fontSize: 14,
                              color: AppColors.ink,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ] else ...[
                // Đề bài (VD "Từ này có nghĩa là gì?") — trước đây bị bỏ
                // qua, chỉ hiện mỗi từ/mẫu trần trụi khiến khó hiểu đang hỏi
                // gì khi xem lại (khác màn thi thật: cố ý không hiện đề bài
                // để giữ đúng cảm giác thi JLPT thật).
                Text(
                  q.promptVi,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.canvas,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Text(
                    q.displayJp,
                    textAlign: TextAlign.center,
                    style: q.displayIsJapanese
                        ? AppFonts.zenMaruGothic(
                            fontSize: 20,
                            color: AppColors.ink,
                          )
                        : const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                            color: AppColors.ink,
                          ),
                  ),
                ),
              ],
              const SizedBox(height: 16),
              for (var i = 0; i < q.options.length; i++)
                _ReviewOptionTile(
                  index: i,
                  label: q.options[i],
                  isCorrect: i == q.correctIndex,
                  isSelectedWrong:
                      i == answer.selectedIndex && i != q.correctIndex,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReviewOptionTile extends StatelessWidget {
  const _ReviewOptionTile({
    required this.index,
    required this.label,
    required this.isCorrect,
    required this.isSelectedWrong,
  });

  final int index;
  final String label;
  final bool isCorrect;
  final bool isSelectedWrong;

  @override
  Widget build(BuildContext context) {
    var bg = AppColors.canvas;
    var border = AppColors.border;
    String? tag;
    if (isCorrect) {
      bg = AppColors.mossSoft;
      border = AppColors.moss;
      tag = 'Đáp án đúng';
    } else if (isSelectedWrong) {
      bg = AppColors.dangerSoft;
      border = AppColors.danger;
      tag = 'Bạn đã chọn';
    }
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: border),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 13,
            backgroundColor: AppColors.card,
            child: Text(
              String.fromCharCode(65 + index),
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(label, style: const TextStyle(fontSize: 14)),
          ),
          if (tag != null)
            Text(
              tag,
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 11,
                color: border,
              ),
            ),
        ],
      ),
    );
  }
}
