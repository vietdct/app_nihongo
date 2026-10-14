import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/supabase_providers.dart';
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

  /// Định danh ổn định giữa các lần tính lại (nhãn + nhóm là duy nhất).
  String get id => '$sub:$label';
}

/// Bảng huy hiệu từ số liệu thật — hàm thuần để cả giao diện lẫn bộ theo dõi
/// mở khóa dùng chung đúng một bộ ngưỡng.
List<AchievementDef> buildAchievements({
  required int longestStreak,
  required int xp,
  required int knownVocab,
  required int knownKanji,
  required bool hasKaiwa,
}) {
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
      earned: hasKaiwa,
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
}

final achievementsProvider = Provider.autoDispose<List<AchievementDef>>((ref) {
  final profile = ref.watch(profileProvider).valueOrNull;
  final vocabProgress = ref.watch(vocabProgressProvider).valueOrNull ?? const {};
  final kanjiProgress = ref.watch(kanjiProgressProvider).valueOrNull ?? const {};
  final kaiwaConversations =
      ref.watch(kaiwaConversationsProvider).valueOrNull ?? const [];

  // Dùng longestStreak (mốc cao nhất từng đạt), không phải streak hiện tại —
  // huy hiệu đã đạt phải là vĩnh viễn, không biến mất khi streak bị reset.
  return buildAchievements(
    longestStreak: profile?.longestStreakCount ?? 0,
    xp: profile?.xp ?? 0,
    knownVocab: vocabProgress.values.where((p) => p.isKnown == true).length,
    knownKanji: kanjiProgress.values.where((p) => p.isKnown == true).length,
    hasKaiwa: kaiwaConversations.isNotEmpty,
  );
});

/// Bảng huy hiệu CHỈ khi cả 4 nguồn dữ liệu đã tải xong (null = còn đang tải /
/// chưa đăng nhập). Khác [achievementsProvider]: không biến "chưa tải" thành
/// "chưa đạt", nên chuyển tải-xong KHÔNG bị nhầm là vừa mở khóa.
final loadedAchievementsProvider =
    Provider.autoDispose<List<AchievementDef>?>((ref) {
  final profile = ref.watch(profileProvider).valueOrNull;
  final vocab = ref.watch(vocabProgressProvider).valueOrNull;
  final kanji = ref.watch(kanjiProgressProvider).valueOrNull;
  final kaiwa = ref.watch(kaiwaConversationsProvider).valueOrNull;
  if (profile == null || vocab == null || kanji == null || kaiwa == null) {
    return null;
  }
  return buildAchievements(
    longestStreak: profile.longestStreakCount,
    xp: profile.xp,
    knownVocab: vocab.values.where((p) => p.isKnown == true).length,
    knownKanji: kanji.values.where((p) => p.isKnown == true).length,
    hasKaiwa: kaiwa.isNotEmpty,
  );
});

/// Theo dõi huy hiệu VỪA mở khóa trong phiên mở app hiện tại — hoàn toàn
/// trong bộ nhớ, không ghi Supabase/Drift, không đổi điều kiện mở khóa.
///
/// Quy tắc an toàn: lần tải đầy đủ đầu tiên chỉ lập mốc (huy hiệu đã đạt từ
/// trước KHÔNG bao giờ bị coi là mới). Một huy hiệu chỉ "vừa mở khóa" khi nó
/// chưa có trong mốc rồi xuất hiện ở một lần tải đầy đủ sau đó; mốc chỉ tăng
/// (không giảm) nên dữ liệu tụt rồi lên lại không báo lặp. Đổi tài khoản thì
/// lập mốc lại. Huy hiệu đạt lúc app đóng/ở thiết bị khác không có hiệu ứng
/// (chọn không hiện còn hơn hiện sai). State = id các huy hiệu mới chưa được
/// người dùng xem; xem xong thì gọi [consume] để không phát lại.
class AchievementUnlockTracker extends Notifier<Set<String>> {
  Set<String>? _baseline;

  @override
  Set<String> build() {
    ref.watch(currentUserProvider.select((u) => u?.id));
    _baseline = null;
    ref.listen(
      loadedAchievementsProvider,
      (_, next) {
        if (next != null) _onSnapshot(next);
      },
      fireImmediately: true,
    );
    return const {};
  }

  void _onSnapshot(List<AchievementDef> snapshot) {
    final earned = {for (final a in snapshot) if (a.earned) a.id};
    final baseline = _baseline;
    if (baseline == null) {
      _baseline = earned;
      return;
    }
    final fresh = earned.difference(baseline);
    _baseline = {...baseline, ...earned};
    if (fresh.isNotEmpty) state = {...state, ...fresh};
  }

  /// Người dùng đã thấy hiệu ứng của các huy hiệu [ids] → bỏ khỏi hàng chờ.
  void consume(Iterable<String> ids) {
    final remaining = {...state}..removeAll(ids);
    if (remaining.length != state.length) state = remaining;
  }
}

final achievementUnlockTrackerProvider =
    NotifierProvider<AchievementUnlockTracker, Set<String>>(
  AchievementUnlockTracker.new,
);
