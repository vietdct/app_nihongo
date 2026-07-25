import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../domain/entities/kaiwa_persona.dart';
import '../../domain/entities/kaiwa_scenario.dart';
import 'kaiwa_chat_screen.dart';
import 'providers/kaiwa_content_providers.dart';

/// Chọn nhân vật AI + tình huống trước khi vào hội thoại. Cả hai đều bắt
/// buộc chọn — AI cần biết đóng vai gì và bối cảnh gì để phản hồi đúng.
class KaiwaHomeScreen extends ConsumerStatefulWidget {
  const KaiwaHomeScreen({super.key});

  @override
  ConsumerState<KaiwaHomeScreen> createState() => _KaiwaHomeScreenState();
}

class _KaiwaHomeScreenState extends ConsumerState<KaiwaHomeScreen> {
  String? _personaId;
  String? _scenarioId;

  @override
  Widget build(BuildContext context) {
    final personasAsync = ref.watch(kaiwaPersonasProvider);
    final scenariosAsync = ref.watch(kaiwaScenariosProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('AI Kaiwa')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: AppColors.tealSoft, borderRadius: BorderRadius.circular(18)),
            child: const Row(
              children: [
                Text('話', style: TextStyle(fontFamily: 'ZenMaruGothic', fontSize: 32, color: AppColors.teal, fontWeight: FontWeight.w700)),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Chọn một nhân vật và tình huống, AI sẽ nói chuyện hoàn toàn bằng tiếng Nhật và chấm câu của bạn sau mỗi lượt.',
                    style: TextStyle(fontSize: 13, color: AppColors.ink, fontWeight: FontWeight.w600, height: 1.4),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const _SectionLabel('Chọn nhân vật'),
          const SizedBox(height: 12),
          personasAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, _) => Text('Lỗi tải nhân vật: $e'),
            data: (personas) => SizedBox(
              height: 108,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: personas.length,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (context, i) {
                  final p = personas[i];
                  return _PersonaCard(
                    persona: p,
                    selected: p.id == _personaId,
                    onTap: () => setState(() => _personaId = p.id),
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 24),
          const _SectionLabel('Chọn tình huống'),
          const SizedBox(height: 12),
          scenariosAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, _) => Text('Lỗi tải tình huống: $e'),
            data: (scenarios) => Column(
              children: [
                for (final s in scenarios) ...[
                  _ScenarioTile(
                    scenario: s,
                    selected: s.id == _scenarioId,
                    onTap: () => setState(() => _scenarioId = s.id),
                  ),
                  const SizedBox(height: 8),
                ],
              ],
            ),
          ),
          const SizedBox(height: 12),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.teal, minimumSize: const Size.fromHeight(52)),
            onPressed: (_personaId == null || _scenarioId == null)
                ? null
                : () {
                    final persona = personasAsync.valueOrNull!.firstWhere((p) => p.id == _personaId);
                    final scenario = scenariosAsync.valueOrNull!.firstWhere((s) => s.id == _scenarioId);
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => KaiwaChatScreen(persona: persona, scenario: scenario),
                      ),
                    );
                  },
            child: const Text('Bắt đầu hội thoại'),
          ),
        ],
      ),
    );
  }
}

class _PersonaCard extends StatelessWidget {
  const _PersonaCard({required this.persona, required this.selected, required this.onTap});

  final KaiwaPersona persona;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        width: 84,
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.tealSoft : AppColors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: selected ? AppColors.teal : AppColors.border, width: selected ? 1.4 : 0.6),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: selected ? AppColors.teal : AppColors.chip,
              child: Text(
                persona.glyph,
                style: AppFonts.zenMaruGothic(fontSize: 18, color: selected ? Colors.white : AppColors.inkSoft),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              persona.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: AppColors.ink),
            ),
            Text(
              persona.role,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 9.5, color: AppColors.inkSoft),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScenarioTile extends StatelessWidget {
  const _ScenarioTile({required this.scenario, required this.selected, required this.onTap});

  final KaiwaScenario scenario;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: selected ? AppColors.tealSoft : AppColors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: selected ? AppColors.teal : AppColors.border, width: selected ? 1.4 : 0.6),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(color: selected ? AppColors.teal : AppColors.chip, borderRadius: BorderRadius.circular(12)),
              alignment: Alignment.center,
              child: Text(scenario.glyph, style: AppFonts.zenMaruGothic(fontSize: 17, color: selected ? Colors.white : AppColors.inkSoft)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(scenario.title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.ink)),
                  const SizedBox(height: 2),
                  Text(
                    scenario.description,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12, color: AppColors.inkSoft),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(color: AppColors.chip, borderRadius: BorderRadius.circular(100)),
              child: Text(scenario.levelMin, style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: AppColors.inkSoft)),
            ),
            if (selected) ...[
              const SizedBox(width: 8),
              const Icon(Icons.check_circle, color: AppColors.teal, size: 20),
            ],
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.inkFaint, letterSpacing: 0.6),
    );
  }
}
