import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import 'providers/mixed_quiz_providers.dart';

const _sourceLabels = {
  MixedQuizSource.multipleChoice: 'Trắc nghiệm (nghĩa / chữ / cách đọc)',
  MixedQuizSource.fillBlank: 'Điền từ — Ngữ pháp',
  MixedQuizSource.typing: 'Gõ đáp án — cách đọc',
  MixedQuizSource.translation: 'Gõ đáp án — dịch nghĩa',
  MixedQuizSource.sentenceOrdering: 'Ghép câu — Ngữ pháp',
  MixedQuizSource.grammarSelection: 'Chọn mẫu ngữ pháp',
  MixedQuizSource.particleSelection: 'Chọn trợ từ',
  MixedQuizSource.errorCorrection: 'Sửa lỗi — Sổ tay lỗi + AI Kaiwa',
  MixedQuizSource.conversationCompletion: 'Hoàn thành hội thoại — AI Kaiwa',
};

const _counts = [5, 10, 15, 20, 30, 50];

/// Màn cấu hình Quiz Tuỳ chỉnh (Task 7 §4 `docs/MIXED_QUIZ_DESIGN.md`) —
/// chọn nhóm câu hỏi + số câu + Timed/Survival, khác `ReviewMixedQuizScreen`
/// (chỉ chọn nhanh số câu, luôn bật đủ mọi nhóm). Không tự watch dữ liệu
/// nội dung — chỉ dựng [MixedQuizConfig] rồi đẩy qua route
/// `/review/mixed-quiz/custom/play`, nơi mới thật sự sinh câu hỏi.
class ReviewMixedQuizCustomScreen extends StatefulWidget {
  const ReviewMixedQuizCustomScreen({super.key});

  @override
  State<ReviewMixedQuizCustomScreen> createState() =>
      _ReviewMixedQuizCustomScreenState();
}

class _ReviewMixedQuizCustomScreenState
    extends State<ReviewMixedQuizCustomScreen> {
  final Set<MixedQuizSource> _selected = {...MixedQuizSource.values};
  int _count = 10;
  bool _timedMode = false;
  bool _survivalMode = false;

  void _toggleSource(MixedQuizSource source, bool value) {
    setState(() {
      if (value) {
        _selected.add(source);
      } else {
        _selected.remove(source);
      }
    });
  }

  void _start() {
    context.push(
      '/review/mixed-quiz/custom/play',
      extra: MixedQuizConfig(
        questionCount: _count,
        enabledSources: _selected,
        timedMode: _timedMode,
        survivalMode: _survivalMode,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final canStart = _selected.isNotEmpty;
    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(title: const Text('Quiz Tuỳ chỉnh')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 100),
        children: [
          const _SectionLabel('Loại câu hỏi'),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.border, width: 1.0),
            ),
            child: Column(
              children: [
                for (final source in MixedQuizSource.values) ...[
                  if (source != MixedQuizSource.values.first)
                    const Divider(height: 1, color: AppColors.border),
                  CheckboxListTile(
                    value: _selected.contains(source),
                    onChanged: (v) => _toggleSource(source, v ?? false),
                    title: Text(
                      _sourceLabels[source]!,
                      style: const TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.ink,),
                    ),
                    controlAffinity: ListTileControlAffinity.leading,
                    activeColor: AppColors.accent,
                    dense: true,
                  ),
                ],
              ],
            ),
          ),
          if (!canStart) ...[
            const SizedBox(height: 8),
            const Text(
              'Chọn ít nhất 1 loại câu hỏi để bắt đầu.',
              style: TextStyle(fontSize: 12, color: AppColors.danger),
            ),
          ],
          const SizedBox(height: 20),
          const _SectionLabel('Số câu'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final c in _counts)
                ChoiceChip(
                  label: Text('$c câu'),
                  selected: _count == c,
                  onSelected: (_) => setState(() => _count = c),
                  selectedColor: AppColors.accentSoft,
                  labelStyle: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: _count == c
                          ? AppColors.accentStrong
                          : AppColors.inkSoft,),
                ),
            ],
          ),
          const SizedBox(height: 20),
          const _SectionLabel('Chế độ chơi'),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.border, width: 1.0),
            ),
            child: Column(
              children: [
                SwitchListTile(
                  value: _timedMode,
                  onChanged: (v) => setState(() => _timedMode = v),
                  title: const Text('Tính giờ toàn bài',
                      style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.ink,),),
                  subtitle: const Text(
                    'Thêm đồng hồ đếm ngược cho cả bài, hết giờ là dừng ngay.',
                    style: TextStyle(fontSize: 11.5, color: AppColors.inkSoft),
                  ),
                  activeThumbColor: AppColors.accent,
                  dense: true,
                ),
                const Divider(height: 1, color: AppColors.border),
                SwitchListTile(
                  value: _survivalMode,
                  onChanged: (v) => setState(() => _survivalMode = v),
                  title: const Text('Chế độ sinh tồn',
                      style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.ink,),),
                  subtitle: const Text(
                    'Sai (hoặc hết giờ) 1 câu là dừng bài luôn, không đợi hết tim.',
                    style: TextStyle(fontSize: 11.5, color: AppColors.inkSoft),
                  ),
                  activeThumbColor: AppColors.accent,
                  dense: true,
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
          child: FilledButton(
            onPressed: canStart ? _start : null,
            child: const Text('Bắt đầu'),
          ),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: AppColors.inkFaint,
          letterSpacing: 0.4,),
    );
  }
}
