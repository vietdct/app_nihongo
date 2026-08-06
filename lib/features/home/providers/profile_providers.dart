import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/supabase_providers.dart';
import '../../../domain/entities/profile.dart';

/// Hồ sơ người dùng thật lấy từ bảng `profiles` (display_name, xp, streak_count) —
/// dùng cho lời chào + thẻ chuỗi ngày học trên Home. Trả null nếu chưa đăng nhập.
final profileProvider = FutureProvider<Profile?>((ref) async {
  final supabase = ref.watch(supabaseProvider);
  final user = ref.watch(currentUserProvider);
  if (user == null) return null;

  final row = await supabase
      .from('profiles')
      .select(
        'display_name, avatar_url, xp, streak_count, longest_streak_count, country, created_at, last_study_date, last_quiz_completed_at, mission_xp_dates',
      )
      .eq('id', user.id)
      .single();

  final lastStudyDateStr = row['last_study_date'] as String?;
  final lastQuizCompletedAtStr = row['last_quiz_completed_at'] as String?;
  final missionXpDates = row['mission_xp_dates'];
  return Profile(
    displayName: row['display_name'] as String,
    avatarUrl: row['avatar_url'] as String?,
    xp: row['xp'] as int,
    streakCount: row['streak_count'] as int,
    longestStreakCount: row['longest_streak_count'] as int,
    country: row['country'] as String?,
    createdAt: DateTime.parse(row['created_at'] as String),
    lastStudyDate: lastStudyDateStr == null ? null : DateTime.parse(lastStudyDateStr),
    lastQuizCompletedAt:
        lastQuizCompletedAtStr == null ? null : DateTime.parse(lastQuizCompletedAtStr),
    missionXpDates: missionXpDates == null
        ? const {}
        : (missionXpDates as Map).cast<String, String>(),
  );
});
