import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/network/supabase_providers.dart';
import '../../../domain/services/daily_mission.dart';
import '../../../domain/services/study_day_log.dart';
import '../../kaiwa/providers/kaiwa_conversation_providers.dart';
import 'profile_providers.dart';

const _emptyMissionStatus = DailyMissionStatus(
  vocabDone: false,
  kanjiDone: false,
  quizDone: false,
  kaiwaDone: false,
);

/// Trạng thái thật của "Today's Mission" — tính từ `user_vocab_progress`/
/// `user_kanji_progress` (updated_at hôm nay), hội thoại Kaiwa hôm nay, và
/// `profiles.last_quiz_completed_at`. Cũng thưởng XP 1 lần cho mỗi mission
/// mới hoàn thành hôm nay (xem [DailyMissionXpController]) — gọi đúng 1 lần
/// khi provider này được watch, idempotent nhờ `profiles.mission_xp_dates`.
final dailyMissionStatusProvider =
    FutureProvider.autoDispose<DailyMissionStatus>((ref) async {
  final sb = ref.watch(supabaseProvider);
  final userId = ref.watch(currentUserProvider)?.id;
  if (userId == null) return _emptyMissionStatus;

  final profile = await ref.watch(profileProvider.future);
  if (profile == null) return _emptyMissionStatus;

  final vocabRows = await sb
      .from('user_vocab_progress')
      .select('updated_at')
      .eq('user_id', userId);
  final kanjiRows = await sb
      .from('user_kanji_progress')
      .select('updated_at')
      .eq('user_id', userId);
  final conversations = await ref.watch(kaiwaConversationsProvider.future);

  final status = computeDailyMissionStatus(
    vocabActivityTimestamps: [
      for (final r in vocabRows) DateTime.parse(r['updated_at'] as String),
    ],
    kanjiActivityTimestamps: [
      for (final r in kanjiRows) DateTime.parse(r['updated_at'] as String),
    ],
    kaiwaActivityTimestamps: [for (final c in conversations) c.lastMessageAt],
    lastQuizCompletedAt: profile.lastQuizCompletedAt,
  );

  final awarded = await DailyMissionXpController(sb, userId)
      .awardIfNeeded(status, profile.missionXpDates);
  if (awarded) ref.invalidate(profileProvider);

  if (status.vocabDone ||
      status.kanjiDone ||
      status.quizDone ||
      status.kaiwaDone) {
    await markStudyDayToday(sb, userId);
  }

  return status;
});

/// Cộng XP thật vào `profiles.xp` cho mỗi mission MỚI hoàn thành hôm nay —
/// khác `QuizXpController` (cộng theo từng câu trả lời đúng): đây là XP
/// thưởng thêm 1 lần/ngày/mission khi đạt ngưỡng, không lặp lại trong ngày.
class DailyMissionXpController {
  DailyMissionXpController(this._sb, this._userId);

  final SupabaseClient _sb;
  final String _userId;

  static const _missionXp = {
    'vocab': 10,
    'kanji': 10,
    'quiz': 15,
    'kaiwa': 15,
  };

  Future<bool> awardIfNeeded(
    DailyMissionStatus status,
    Map<String, String> missionXpDates,
  ) async {
    final today = _todayKey();
    final doneMap = {
      'vocab': status.vocabDone,
      'kanji': status.kanjiDone,
      'quiz': status.quizDone,
      'kaiwa': status.kaiwaDone,
    };

    var totalDelta = 0;
    final updatedDates = Map<String, String>.from(missionXpDates);
    for (final entry in doneMap.entries) {
      if (entry.value && missionXpDates[entry.key] != today) {
        totalDelta += _missionXp[entry.key]!;
        updatedDates[entry.key] = today;
      }
    }
    if (totalDelta == 0) return false;

    final row =
        await _sb.from('profiles').select('xp').eq('id', _userId).single();
    final currentXp = (row['xp'] as num?)?.toInt() ?? 0;
    await _sb.from('profiles').update({
      'xp': currentXp + totalDelta,
      'mission_xp_dates': updatedDates,
    }).eq('id', _userId);
    return true;
  }

  String _todayKey() {
    final now = DateTime.now();
    final m = now.month.toString().padLeft(2, '0');
    final d = now.day.toString().padLeft(2, '0');
    return '${now.year}-$m-$d';
  }
}
