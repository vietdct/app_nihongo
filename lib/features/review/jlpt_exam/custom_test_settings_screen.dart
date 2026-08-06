import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import 'models/custom_test_blueprint.dart';

class _SourceDef {
  const _SourceDef({
    required this.key,
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.label,
  });

  final String key;
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String label;
}

const _sourceDefs = [
  _SourceDef(
    key: 'vocabulary',
    icon: Icons.style_outlined,
    iconColor: AppColors.moss,
    iconBg: AppColors.mossSoft,
    label: 'Từ vựng',
  ),
  _SourceDef(
    key: 'grammar',
    icon: Icons.menu_book_outlined,
    iconColor: AppColors.plum,
    iconBg: AppColors.plumSoft,
    label: 'Ngữ pháp',
  ),
  _SourceDef(
    key: 'kanji',
    icon: Icons.brush_outlined,
    iconColor: AppColors.indigo,
    iconBg: AppColors.indigoSoft,
    label: 'Kanji',
  ),
  _SourceDef(
    key: 'reading',
    icon: Icons.article_outlined,
    iconColor: AppColors.teal,
    iconBg: AppColors.tealSoft,
    label: 'Đọc hiểu',
  ),
  _SourceDef(
    key: 'listening',
    icon: Icons.headphones_outlined,
    iconColor: AppColors.accentStrong,
    iconBg: AppColors.accentSoft,
    label: 'Nghe hiểu',
  ),
];

const _countOptions = [5, 10, 15, 20];

/// Màn cấu hình Custom Test (docs/JLPT_MOCK_EXAM_DESIGN.md §3) — chọn PHẦN
/// nào thi + SỐ CÂU MỖI PHẦN, khác Mini Test Settings Sheet (1 số câu
/// dùng chung cho mọi nguồn đã chọn). Chỉ dựng [CustomTestBlueprint] rồi
/// sinh đề qua [buildCustomTestRunSections] — không tự watch dữ liệu nội
/// dung ở đây, giữ màn này thuần UI cấu hình.
class CustomTestSettingsScreen extends ConsumerStatefulWidget {
  const CustomTestSettingsScreen({required this.levelId, super.key});

  final String levelId;

  @override
  ConsumerState<CustomTestSettingsScreen> createState() =>
      _CustomTestSettingsScreenState();
}

class _CustomTestSettingsScreenState
    extends ConsumerState<CustomTestSettingsScreen> {
  final Map<String, int> _counts = {'vocabulary': 10, 'grammar': 10};
  CustomTestTimerMode _timerMode = CustomTestTimerMode.unlimited;
  bool _starting = false;

  void _toggleSource(String key, bool enabled) {
    setState(() {
      if (enabled) {
        _counts[key] = 10;
      } else {
        _counts.remove(key);
      }
    });
  }

  void _setCount(String key, int count) {
    setState(() => _counts[key] = count);
  }

  Future<void> _start() async {
    if (_counts.isEmpty || _starting) return;
    setState(() => _starting = true);

    final blueprint = CustomTestBlueprint(
      levelId: widget.levelId,
      sourceCounts: Map.of(_counts),
      timerMode: _timerMode,
    );
    final sections = await buildCustomTestRunSections(ref, blueprint);

    if (!mounted) return;
    setState(() => _starting = false);

    if (sections.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Chưa đủ nội dung cho các phần đã chọn ở cấp độ này.'),
        ),
      );
      return;
    }

    context.push(
      '/review/jlpt-exam/${widget.levelId}/session/${CustomTestBlueprint.sessionMode}',
      extra: sections,
    );
  }

  @override
  Widget build(BuildContext context) {
    final canStart = _counts.isNotEmpty;
    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(title: const Text('Custom Test')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 100),
        children: [
          const Text(
            'Chọn phần muốn thi và số câu mỗi phần — mỗi phần làm riêng như Full Exam.',
            style: TextStyle(fontSize: 12.5, color: AppColors.inkSoft),
          ),
          const SizedBox(height: 16),
          for (final def in _sourceDefs) ...[
            _SourceCard(
              def: def,
              enabled: _counts.containsKey(def.key),
              count: _counts[def.key],
              onToggle: (v) => _toggleSource(def.key, v),
              onCountChanged: (c) => _setCount(def.key, c),
            ),
            const SizedBox(height: 10),
          ],
          if (!canStart)
            const Padding(
              padding: EdgeInsets.only(top: 6),
              child: Text(
                'Chọn ít nhất 1 phần để bắt đầu.',
                style: TextStyle(fontSize: 12, color: AppColors.danger),
              ),
            ),
          const SizedBox(height: 10),
          const Text(
            'ĐỒNG HỒ',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: AppColors.inkFaint,
              letterSpacing: 0.4,
            ),
          ),
          RadioListTile<CustomTestTimerMode>(
            contentPadding: EdgeInsets.zero,
            dense: true,
            title: const Text('Không giới hạn'),
            value: CustomTestTimerMode.unlimited,
            groupValue: _timerMode,
            onChanged: (v) => setState(() => _timerMode = v!),
          ),
          RadioListTile<CustomTestTimerMode>(
            contentPadding: EdgeInsets.zero,
            dense: true,
            title: const Text('Theo giờ JLPT'),
            value: CustomTestTimerMode.jlptTimed,
            groupValue: _timerMode,
            onChanged: (v) => setState(() => _timerMode = v!),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
          child: FilledButton(
            onPressed: canStart && !_starting ? _start : null,
            child: _starting
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Bắt đầu'),
          ),
        ),
      ),
    );
  }
}

class _SourceCard extends StatelessWidget {
  const _SourceCard({
    required this.def,
    required this.enabled,
    required this.count,
    required this.onToggle,
    required this.onCountChanged,
  });

  final _SourceDef def;
  final bool enabled;
  final int? count;
  final ValueChanged<bool> onToggle;
  final ValueChanged<int> onCountChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border, width: 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => onToggle(!enabled),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: def.iconBg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.center,
                  child: Icon(def.icon, color: def.iconColor, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    def.label,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                      color: AppColors.ink,
                    ),
                  ),
                ),
                Switch(
                  value: enabled,
                  onChanged: onToggle,
                  activeThumbColor: AppColors.accent,
                ),
              ],
            ),
          ),
          if (enabled) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              children: [
                for (final c in _countOptions)
                  ChoiceChip(
                    label: Text('$c câu'),
                    selected: count == c,
                    selectedColor: AppColors.accentSoft,
                    labelStyle: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: count == c
                          ? AppColors.accentStrong
                          : AppColors.inkSoft,
                    ),
                    onSelected: (_) => onCountChanged(c),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
