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
      .select('display_name, xp, streak_count, last_study_date')
      .eq('id', user.id)
      .single();

  final lastStudyDateStr = row['last_study_date'] as String?;
  return Profile(
    displayName: row['display_name'] as String,
    xp: row['xp'] as int,
    streakCount: row['streak_count'] as int,
    lastStudyDate: lastStudyDateStr == null ? null : DateTime.parse(lastStudyDateStr),
  );
});
