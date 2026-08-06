import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/network/supabase_providers.dart';

final miniTestXpControllerProvider =
    Provider.autoDispose<MiniTestXpController?>((ref) {
  final sb = ref.watch(supabaseProvider);
  final userId = ref.watch(currentUserProvider)?.id;
  if (userId == null) return null;
  return MiniTestXpController(sb, userId);
});

/// Kết quả cộng thưởng khi hoàn thành 1 Mini Test — dùng để Result Screen
/// hiển thị đúng số đã cộng thật (không phải số dự đoán), vì thưởng
/// [MiniTestXpController.dailyBonusXp] và tăng streak chỉ xảy ra 1 lần/ngày.
class MiniTestCompletionResult {
  const MiniTestCompletionResult({
    required this.dailyBonusAwarded,
    required this.streakCount,
  });

  final bool dailyBonusAwarded;
  final int streakCount;
}

/// Cộng XP + cập nhật streak toàn app cho Mini Test
/// (docs/JLPT_MINI_TEST_DESIGN.md §5, §21 — quyết định 2026-08-06: dùng
/// chung `profiles.streak_count`/`last_study_date`, không tạo bảng streak
/// riêng; XP tái dùng `profiles.xp`, không có Coin).
class MiniTestXpController {
  MiniTestXpController(this._sb, this._userId);

  final SupabaseClient _sb;
  final String _userId;

  /// Thưởng thêm khi hoàn thành 1 Mini Test/ngày (bất kỳ biến thể) — cùng
  /// mức với mission "Hoàn thành 1 bài Quiz" (`DailyMissionXpController`).
  static const dailyBonusXp = 15;

  /// Cộng XP theo từng câu trả lời đúng — cùng pattern `QuizXpController`.
  Future<void> addXp(int delta) async {
    final row =
        await _sb.from('profiles').select('xp').eq('id', _userId).single();
    final current = (row['xp'] as num?)?.toInt() ?? 0;
    await _sb.from('profiles').update({'xp': current + delta}).eq('id', _userId);
  }

  /// Gọi đúng 1 lần khi nộp xong 1 Mini Test — chặn trùng ngày qua
  /// `mission_xp_dates['mini_test']` (cùng cột JSON `DailyMissionXpController`
  /// đang dùng, không thêm cột mới). Streak: +1 nếu `last_study_date` là hôm
  /// qua, reset về 1 nếu bỏ lỡ ngày, giữ nguyên nếu hôm nay đã học rồi.
  Future<MiniTestCompletionResult> completeMiniTestToday() async {
    final today = _todayKey();
    final row = await _sb
        .from('profiles')
        .select('xp, streak_count, last_study_date, mission_xp_dates')
        .eq('id', _userId)
        .single();

    final currentXp = (row['xp'] as num?)?.toInt() ?? 0;
    final currentStreak = (row['streak_count'] as num?)?.toInt() ?? 0;
    final lastStudyDateStr = row['last_study_date'] as String?;
    final missionXpDates = row['mission_xp_dates'] == null
        ? <String, String>{}
        : Map<String, String>.from(row['mission_xp_dates'] as Map);

    final update = <String, Object?>{};
    var effectiveStreak = currentStreak;

    if (lastStudyDateStr != today) {
      final lastStudyDate =
          lastStudyDateStr == null ? null : DateTime.parse(lastStudyDateStr);
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      final isConsecutive = lastStudyDate != null &&
          lastStudyDate.year == yesterday.year &&
          lastStudyDate.month == yesterday.month &&
          lastStudyDate.day == yesterday.day;
      effectiveStreak = isConsecutive ? currentStreak + 1 : 1;
      update['streak_count'] = effectiveStreak;
      update['last_study_date'] = today;
    }

    final dailyBonusAwarded = missionXpDates['mini_test'] != today;
    if (dailyBonusAwarded) {
      update['xp'] = currentXp + dailyBonusXp;
      update['mission_xp_dates'] = {...missionXpDates, 'mini_test': today};
    }

    if (update.isNotEmpty) {
      await _sb.from('profiles').update(update).eq('id', _userId);
    }
    return MiniTestCompletionResult(
      dailyBonusAwarded: dailyBonusAwarded,
      streakCount: effectiveStreak,
    );
  }

  String _todayKey() {
    final now = DateTime.now();
    final m = now.month.toString().padLeft(2, '0');
    final d = now.day.toString().padLeft(2, '0');
    return '${now.year}-$m-$d';
  }
}
