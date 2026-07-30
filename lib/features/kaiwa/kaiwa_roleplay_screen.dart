import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../domain/entities/kaiwa_persona.dart';
import '../../domain/entities/kaiwa_scenario.dart';
import 'kaiwa_chat_screen.dart';
import 'providers/kaiwa_content_providers.dart';

/// Chọn nhân vật AI để đóng vai sau khi đã chọn tình huống ở Scenario Map —
/// tách "địa điểm" (tình huống) và "ai mình sẽ nói chuyện cùng" (nhân vật)
/// thành 2 bước riêng thay vì gộp chung 1 màn như trước, đúng luồng
/// Topic Selection → Role Play trong thiết kế.
class KaiwaRoleplayScreen extends ConsumerStatefulWidget {
  const KaiwaRoleplayScreen({super.key, required this.scenarioId, this.seedWord});

  final String scenarioId;

  /// Từ vựng muốn luyện dùng trong hội thoại — chuyển tiếp từ Scenario Map,
  /// truyền tiếp cho `KaiwaChatScreen` khi bắt đầu hội thoại.
  final String? seedWord;

  @override
  ConsumerState<KaiwaRoleplayScreen> createState() => _KaiwaRoleplayScreenState();
}

class _KaiwaRoleplayScreenState extends ConsumerState<KaiwaRoleplayScreen> {
  String? _personaId;

  @override
  Widget build(BuildContext context) {
    final scenariosAsync = ref.watch(kaiwaScenariosProvider);
    final personasAsync = ref.watch(kaiwaPersonasProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Chọn nhân vật')),
      body: scenariosAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Lỗi tải tình huống: $e')),
        data: (scenarios) {
          KaiwaScenario? scenario;
          for (final s in scenarios) {
            if (s.id == widget.scenarioId) {
              scenario = s;
              break;
            }
          }
          if (scenario == null) {
            return const Center(child: Text('Không tìm thấy tình huống này.'));
          }
          final resolvedScenario = scenario;

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
                child: Column(
                  children: [
                    _ScenarioRecap(scenario: resolvedScenario),
                    if (widget.seedWord != null) ...[
                      const SizedBox(height: 8),
                      _SeedWordChip(word: widget.seedWord!),
                    ],
                  ],
                ),
              ),
              Expanded(
                child: personasAsync.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(child: Text('Lỗi tải nhân vật: $e')),
                  data: (personas) => GridView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 10,
                      crossAxisSpacing: 10,
                      childAspectRatio: 0.92,
                    ),
                    itemCount: personas.length,
                    itemBuilder: (context, i) {
                      final p = personas[i];
                      return _PersonaTile(
                        persona: p,
                        selected: p.id == _personaId,
                        onTap: () => setState(() => _personaId = p.id),
                      );
                    },
                  ),
                ),
              ),
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                  child: FilledButton(
                    style: FilledButton.styleFrom(backgroundColor: AppColors.teal, minimumSize: const Size.fromHeight(52)),
                    onPressed: _personaId == null
                        ? null
                        : () {
                            final persona = personasAsync.valueOrNull!.firstWhere((p) => p.id == _personaId);
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => KaiwaChatScreen(
                                  persona: persona,
                                  scenario: resolvedScenario,
                                  seedWord: widget.seedWord,
                                ),
                              ),
                            );
                          },
                    child: const Text('Bắt đầu hội thoại'),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Nhắc lại từ vựng sẽ gợi ý AI dùng trong hội thoại (xem `seedWord` ở
/// `KaiwaChatScreen`/`ai-kaiwa-chat`) — để người dùng biết vì sao lại tới đây
/// từ thẻ "Từ vựng hôm nay" thay vì im lặng chuyển màn.
class _SeedWordChip extends StatelessWidget {
  const _SeedWordChip({required this.word});

  final String word;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(color: AppColors.mossSoft, borderRadius: BorderRadius.circular(100)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.lightbulb_outline_rounded, size: 14, color: AppColors.moss),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              'Sẽ gợi ý dùng từ "$word" trong hội thoại',
              style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: AppColors.moss),
            ),
          ),
        ],
      ),
    );
  }
}

class _ScenarioRecap extends StatelessWidget {
  const _ScenarioRecap({required this.scenario});

  final KaiwaScenario scenario;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: AppColors.tealSoft, borderRadius: BorderRadius.circular(16)),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(color: AppColors.teal, borderRadius: BorderRadius.circular(12)),
            alignment: Alignment.center,
            child: Text(scenario.glyph, style: AppFonts.zenMaruGothic(fontSize: 17, color: Colors.white)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(scenario.title, style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700, color: AppColors.ink)),
                const SizedBox(height: 2),
                Text(
                  scenario.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 11.5, color: AppColors.inkSoft, height: 1.3),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PersonaTile extends StatelessWidget {
  const _PersonaTile({required this.persona, required this.selected, required this.onTap});

  final KaiwaPersona persona;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: selected ? AppColors.tealSoft : AppColors.card,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: selected ? AppColors.teal : AppColors.border, width: selected ? 1.4 : 0.8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: selected ? AppColors.teal : AppColors.chip,
                  child: Text(
                    persona.glyph,
                    style: AppFonts.zenMaruGothic(fontSize: 16, color: selected ? Colors.white : AppColors.inkSoft),
                  ),
                ),
                const Spacer(),
                if (selected) const Icon(Icons.check_circle, color: AppColors.teal, size: 18),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              persona.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.ink),
            ),
            Text(
              persona.role,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.inkSoft),
            ),
            const SizedBox(height: 4),
            Expanded(
              child: Text(
                persona.personality,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 10.5, color: AppColors.inkFaint, height: 1.3),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
