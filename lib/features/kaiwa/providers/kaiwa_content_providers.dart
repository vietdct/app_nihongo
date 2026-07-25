import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/supabase_providers.dart';
import '../../../domain/entities/kaiwa_persona.dart';
import '../../../domain/entities/kaiwa_scenario.dart';

/// Nhân vật AI + tình huống hội thoại là dữ liệu tham chiếu nhỏ, dùng chung
/// cho mọi cấp độ — fetch thẳng từ Supabase, không cần cache Drift
/// (giống jlptLevelsProvider), vì AI Kaiwa vốn đã cần mạng để hoạt động.
final kaiwaPersonasProvider = FutureProvider<List<KaiwaPersona>>((ref) async {
  final sb = ref.watch(supabaseProvider);
  final rows = await sb.from('kaiwa_personas').select().eq('is_active', true).order('order_index', ascending: true);
  return [
    for (final r in rows)
      KaiwaPersona(
        id: r['id'] as String,
        name: r['name'] as String,
        glyph: r['glyph'] as String,
        role: r['role'] as String,
        gender: r['gender'] as String,
        personality: r['personality'] as String,
        politenessLevel: r['politeness_level'] as String,
        description: r['description'] as String,
        orderIndex: r['order_index'] as int,
        voiceStyle: r['voice_style'] as String,
      ),
  ];
});

final kaiwaScenariosProvider = FutureProvider<List<KaiwaScenario>>((ref) async {
  final sb = ref.watch(supabaseProvider);
  final rows = await sb.from('kaiwa_scenarios').select().order('order_index', ascending: true);
  return [
    for (final r in rows)
      KaiwaScenario(
        id: r['id'] as String,
        title: r['title'] as String,
        glyph: r['glyph'] as String,
        category: r['category'] as String,
        description: r['description'] as String,
        levelMin: r['level_min'] as String,
        systemContext: r['system_context'] as String,
        orderIndex: r['order_index'] as int,
      ),
  ];
});
