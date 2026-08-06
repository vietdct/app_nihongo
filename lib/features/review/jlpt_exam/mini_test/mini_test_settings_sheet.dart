import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import 'models/mini_test_variant.dart';

/// docs/JLPT_MINI_TEST_DESIGN.md §4 — "Đồng hồ": Không giới hạn (mặc định)
/// hoặc Theo giờ JLPT (ước lượng theo tỉ lệ số câu, xem
/// `mini_test_blueprint.dart#_resolveTimerMinutes`).
enum MiniTestTimerMode { unlimited, jlptTimed }

class MiniTestSettings {
  const MiniTestSettings({
    required this.questionCount,
    required this.sources,
    required this.timerMode,
  });

  final int questionCount;
  final List<String> sources;
  final MiniTestTimerMode timerMode;
}

/// Bottom sheet cấu hình dùng chung Daily/Weak Point Mini Test — Quick 5
/// bỏ qua bước này (docs §4). KHÔNG có bộ chọn "Độ khó" như mock gốc:
/// `quiz_generator.dart` chưa có cơ chế lọc câu hỏi theo độ khó/Adaptive nào
/// (đã kiểm tra codebase, không có rule tương đương REVIEW_DESIGN.md §4 nào
/// được triển khai) — thêm 1 lựa chọn UI không có tác dụng thật sẽ đánh lừa
/// người dùng, để trống chờ khi có engine độ khó thật thay vì giả vờ hoạt động.
class MiniTestSettingsSheet extends StatefulWidget {
  const MiniTestSettingsSheet({required this.variant, super.key});

  final MiniTestVariant variant;

  @override
  State<MiniTestSettingsSheet> createState() => _MiniTestSettingsSheetState();
}

class _MiniTestSettingsSheetState extends State<MiniTestSettingsSheet> {
  int _questionCount = 10;
  final Set<String> _sources = {'vocabulary', 'grammar'};
  MiniTestTimerMode _timerMode = MiniTestTimerMode.unlimited;

  static const _questionCountOptions = [5, 10, 15, 20];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Cấu hình ${widget.variant.label}',
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
            ),
            const SizedBox(height: 20),
            const Text('Số câu', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              children: [
                for (final n in _questionCountOptions)
                  ChoiceChip(
                    label: Text('$n'),
                    selected: _questionCount == n,
                    selectedColor: AppColors.indigoSoft,
                    onSelected: (_) => setState(() => _questionCount = n),
                  ),
              ],
            ),
            const SizedBox(height: 18),
            const Text('Nguồn câu', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
            _SourceCheckbox(
              label: 'Từ vựng',
              value: _sources.contains('vocabulary'),
              onChanged: (v) =>
                  setState(() => v ? _sources.add('vocabulary') : _sources.remove('vocabulary')),
            ),
            _SourceCheckbox(
              label: 'Ngữ pháp',
              value: _sources.contains('grammar'),
              onChanged: (v) =>
                  setState(() => v ? _sources.add('grammar') : _sources.remove('grammar')),
            ),
            _SourceCheckbox(
              label: 'Kanji',
              value: _sources.contains('kanji'),
              onChanged: (v) => setState(() => v ? _sources.add('kanji') : _sources.remove('kanji')),
            ),
            _SourceCheckbox(
              label: 'Đọc hiểu',
              value: _sources.contains('reading'),
              onChanged: (v) =>
                  setState(() => v ? _sources.add('reading') : _sources.remove('reading')),
              disabledReason: widget.variant == MiniTestVariant.weakPoint
                  ? 'Chưa có dữ liệu điểm yếu riêng — câu sẽ chọn ngẫu nhiên'
                  : null,
            ),
            _SourceCheckbox(
              label: 'Nghe hiểu',
              value: _sources.contains('listening'),
              onChanged: (v) =>
                  setState(() => v ? _sources.add('listening') : _sources.remove('listening')),
              disabledReason: widget.variant == MiniTestVariant.weakPoint
                  ? 'Chưa có dữ liệu điểm yếu riêng — câu sẽ chọn ngẫu nhiên'
                  : null,
            ),
            const SizedBox(height: 10),
            const Text('Đồng hồ', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
            RadioListTile<MiniTestTimerMode>(
              contentPadding: EdgeInsets.zero,
              dense: true,
              title: const Text('Không giới hạn'),
              value: MiniTestTimerMode.unlimited,
              groupValue: _timerMode,
              onChanged: (v) => setState(() => _timerMode = v!),
            ),
            RadioListTile<MiniTestTimerMode>(
              contentPadding: EdgeInsets.zero,
              dense: true,
              title: const Text('Theo giờ JLPT'),
              value: MiniTestTimerMode.jlptTimed,
              groupValue: _timerMode,
              onChanged: (v) => setState(() => _timerMode = v!),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _sources.isEmpty
                    ? null
                    : () => Navigator.of(context).pop(
                          MiniTestSettings(
                            questionCount: _questionCount,
                            sources: _sources.toList(),
                            timerMode: _timerMode,
                          ),
                        ),
                child: const Text('Bắt đầu'),
              ),
            ),
            if (_sources.isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text(
                  'Chọn ít nhất 1 nguồn câu',
                  style: TextStyle(color: AppColors.inkSoft, fontSize: 12),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _SourceCheckbox extends StatelessWidget {
  const _SourceCheckbox({
    required this.label,
    required this.value,
    required this.onChanged,
    this.disabledReason,
  });

  final String label;
  final bool value;
  final ValueChanged<bool>? onChanged;
  final String? disabledReason;

  @override
  Widget build(BuildContext context) {
    return CheckboxListTile(
      contentPadding: EdgeInsets.zero,
      dense: true,
      controlAffinity: ListTileControlAffinity.leading,
      title: Text(label),
      subtitle: disabledReason == null
          ? null
          : Text(disabledReason!, style: const TextStyle(fontSize: 11, color: AppColors.inkSoft)),
      value: value,
      onChanged: onChanged == null ? null : (v) => onChanged!(v ?? false),
    );
  }
}
