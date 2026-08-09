import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../home/providers/profile_providers.dart';
import '../../kaiwa/providers/kaiwa_conversation_providers.dart';
import '../../kanji/providers/kanji_progress_providers.dart';
import '../../vocabulary/providers/vocab_progress_providers.dart';

/// 1 huy hiệu — ngưỡng dựa 100% trên dữ liệu thật đã có (streak/XP/số mục
/// đã thuộc/có hội thoại Kaiwa). Dùng chung giữa `AchievementsScreen` (Thành
/// tích) và Home (thẻ tóm tắt), tránh lặp lại danh sách ngưỡng ở 2 nơi.
class AchievementDef {
  const AchievementDef({
    required this.earned,
    required this.icon,
    required this.label,
    required this.sub,
  });

  final bool earned;
  final IconData icon;
  final String label;
  final String sub;
}

final achievementsProvider = Provider.autoDispose<List<AchievementDef>>((ref) {
  final profile = ref.watch(profileProvider).valueOrNull;
  final vocabProgress = ref.watch(vocabProgressProvider).valueOrNull ?? const {};
  final kanjiProgress = ref.watch(kanjiProgressProvider).valueOrNull ?? const {};
  final kaiwaConversations =
      ref.watch(kaiwaConversationsProvider).valueOrNull ?? const [];

  // Dùng longestStreak (mốc cao nhất từng đạt), không phải streak hiện tại —
  // huy hiệu đã đạt phải là vĩnh viễn, không biến mất khi streak bị reset.
  final longestStreak = profile?.longestStreakCount ?? 0;
  final xp = profile?.xp ?? 0;
  final knownVocab = vocabProgress.values.where((p) => p.isKnown == true).length;
  final knownKanji = kanjiProgress.values.where((p) => p.isKnown == true).length;

  return [
    AchievementDef(
      earned: longestStreak >= 7,
      icon: Icons.local_fire_department_rounded,
      label: '7 ngày',
      sub: 'Chuỗi học',
    ),
    AchievementDef(
      earned: longestStreak >= 30,
      icon: Icons.emoji_events_rounded,
      label: '30 ngày',
      sub: 'Chuỗi học',
    ),
    AchievementDef(
      earned: knownVocab >= 50,
      icon: Icons.style_rounded,
      label: '50 từ',
      sub: 'Từ vựng',
    ),
    AchievementDef(
      earned: knownVocab >= 200,
      icon: Icons.style_rounded,
      label: '200 từ',
      sub: 'Từ vựng',
    ),
    AchievementDef(
      earned: knownKanji >= 10,
      icon: Icons.brush_rounded,
      label: '10 Kanji',
      sub: 'Kanji',
    ),
    AchievementDef(
      earned: knownKanji >= 50,
      icon: Icons.brush_rounded,
      label: '50 Kanji',
      sub: 'Kanji',
    ),
    AchievementDef(
      earned: kaiwaConversations.isNotEmpty,
      icon: Icons.forum_rounded,
      label: 'Kaiwa đầu',
      sub: 'Hội thoại',
    ),
    AchievementDef(
      earned: xp >= 500,
      icon: Icons.bolt_rounded,
      label: '500 XP',
      sub: 'Kinh nghiệm',
    ),
  ];
});
