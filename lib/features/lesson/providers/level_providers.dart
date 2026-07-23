import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/supabase_providers.dart';

/// jlpt_levels là bảng tham chiếu rất nhỏ, hiếm đổi — không cần qua Drift,
/// fetch thẳng từ Supabase là đủ (khác với vocabulary/kanji/lessons vốn
/// nhiều và cần offline).
final currentLevelIdProvider = FutureProvider<String>((ref) async {
  final supabase = ref.watch(supabaseProvider);
  final row = await supabase.from('jlpt_levels').select('id').eq('code', 'N5').single();
  return row['id'] as String;
});
