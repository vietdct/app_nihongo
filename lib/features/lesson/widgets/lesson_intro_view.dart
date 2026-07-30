import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../domain/entities/lesson.dart';
import '../../../domain/services/lesson_objectives.dart';

/// Màn mở đầu 1 phiên học — minh hoạ nguyên bản (gradient + hình khối mềm,
/// không dùng asset ảnh ngoài) kèm số liệu thật của bài (không có "XP
/// Reward" hiển thị trước — XP thật chỉ chốt ở Lesson Summary, xem bản
/// thiết kế mục 0.2 "honest progress").
class LessonIntroView extends StatelessWidget {
  const LessonIntroView({
    super.key,
    required this.lesson,
    required this.items,
    required this.levelLabel,
    required this.onStart,
  });

  final Lesson lesson;
  final List<LessonContentItem> items;

  /// Mã cấp độ hiển thị (VD "N5") — KHÔNG dùng `lesson.levelId` trực tiếp,
  /// đó là uuid nội bộ của bảng jlpt_levels, không phải chuỗi hiển thị được.
  final String levelLabel;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final minutes = estimateLessonMinutes(items);
    final difficulty = deriveLessonDifficulty(items);
    final vocabCount = items.where((i) => i.type == LessonItemType.vocabulary).length;
    final kanjiCount = items.where((i) => i.type == LessonItemType.kanji).length;
    final grammarCount = items.where((i) => i.type == LessonItemType.grammar).length;

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _IllustrationBanner(levelLabel: levelLabel),
                const SizedBox(height: 20),
                Text(
                  lesson.title,
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.ink),
                ),
                if (lesson.description != null && lesson.description!.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    lesson.description!,
                    style: const TextStyle(fontSize: 14, color: AppColors.inkSoft, height: 1.4),
                  ),
                ],
                const SizedBox(height: 20),
                _StatsGrid(
                  minutes: minutes,
                  vocabCount: vocabCount,
                  kanjiCount: kanjiCount,
                  grammarCount: grammarCount,
                  difficulty: difficulty,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: FilledButton(onPressed: onStart, child: const Text('Bắt đầu học')),
        ),
      ],
    );
  }
}

class _IllustrationBanner extends StatelessWidget {
  const _IllustrationBanner({required this.levelLabel});

  final String levelLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 180,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.heroGradientStart, AppColors.heroGradientEnd],
        ),
      ),
      child: Stack(
        children: [
          Positioned(right: -30, top: -30, child: _softCircle(130)),
          Positioned(left: -24, bottom: -46, child: _softCircle(110)),
          Positioned(right: 34, bottom: 18, child: _softCircle(46)),
          Center(
            child: Text(
              '課',
              style: AppFonts.zenMaruGothic(fontSize: 72, color: Colors.white.withValues(alpha: 0.92)),
            ),
          ),
          Positioned(
            left: 16,
            top: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.22),
                borderRadius: BorderRadius.circular(100),
              ),
              child: Text(
                levelLabel,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _softCircle(double size) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: 0.14)),
      );
}

class _StatsGrid extends StatelessWidget {
  const _StatsGrid({
    required this.minutes,
    required this.vocabCount,
    required this.kanjiCount,
    required this.grammarCount,
    required this.difficulty,
  });

  final int minutes;
  final int vocabCount;
  final int kanjiCount;
  final int grammarCount;
  final LessonPaceDifficulty difficulty;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        _StatChip(icon: Icons.timer_outlined, label: '$minutes phút'),
        if (vocabCount > 0) _StatChip(icon: Icons.menu_book_outlined, label: '$vocabCount từ vựng'),
        if (kanjiCount > 0) _StatChip(icon: Icons.brush_outlined, label: '$kanjiCount Kanji'),
        if (grammarCount > 0) _StatChip(icon: Icons.rule_outlined, label: '$grammarCount ngữ pháp'),
        _StatChip(icon: Icons.speed_outlined, label: _difficultyLabel(difficulty)),
      ],
    );
  }

  String _difficultyLabel(LessonPaceDifficulty d) => switch (d) {
        LessonPaceDifficulty.easy => 'Dễ',
        LessonPaceDifficulty.medium => 'Vừa',
        LessonPaceDifficulty.hard => 'Khó',
      };
}

class _StatChip extends StatelessWidget {
  const _StatChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(color: AppColors.chip, borderRadius: BorderRadius.circular(100)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: AppColors.inkSoft),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.ink)),
        ],
      ),
    );
  }
}
