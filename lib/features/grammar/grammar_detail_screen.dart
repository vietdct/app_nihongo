import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../../domain/entities/grammar_point.dart';
import '../lesson/providers/content_providers.dart';
import 'providers/grammar_comparison_providers.dart';
import 'providers/grammar_progress_providers.dart';
import 'widgets/grammar_content_sections.dart';
import '../../shared/jp_example_text.dart';

/// Trang tra cứu TĨNH cho 1 điểm ngữ pháp — khác `GrammarFlashcardScreen`
/// (bộ thẻ vuốt qua dùng để luyện tập): đây là nơi xem/đánh dấu lại một mẫu
/// cụ thể, mở từ Grammar Home hoặc danh sách, không có gesture vuốt sang thẻ
/// khác. Tìm điểm ngữ pháp trong danh sách của cấp độ JLPT đang chọn — nếu
/// mở nhầm từ 1 cấp độ khác (id không thuộc cấp độ hiện tại) thì báo rõ thay
/// vì crash, vì `grammarListProvider` luôn lọc theo cấp độ.
class GrammarDetailScreen extends ConsumerWidget {
  const GrammarDetailScreen({super.key, required this.grammarId});

  final String grammarId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final grammarAsync = ref.watch(grammarListProvider);
    final progressAsync = ref.watch(grammarProgressProvider);
    final controller = ref.watch(grammarProgressControllerProvider);
    final comparisonPairs =
        ref.watch(grammarComparisonPairsProvider).valueOrNull ?? const [];

    GrammarPoint? findGrammar(List<GrammarPoint> all) {
      for (final g in all) {
        if (g.id == grammarId) return g;
      }
      return null;
    }

    Future<void> toggleStarred(GrammarPoint grammar, bool current) async {
      await controller?.setStarred(grammar.id, !current);
      ref.invalidate(grammarProgressProvider);
    }

    Future<void> toggleKnown(GrammarPoint grammar, bool current) async {
      await controller?.setKnown(grammar.id, !current);
      ref.invalidate(grammarProgressProvider);
    }

    final grammar = grammarAsync.valueOrNull != null
        ? findGrammar(grammarAsync.valueOrNull!)
        : null;
    final starred = grammar == null
        ? false
        : progressAsync.valueOrNull?[grammar.id]?.starred ?? false;

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        title: const Text('Ngữ pháp'),
        actions: [
          if (grammar != null)
            IconButton(
              tooltip: starred ? 'Bỏ lưu' : 'Lưu lại',
              icon: Icon(
                starred ? Icons.star_rounded : Icons.star_border_rounded,
                color: starred ? AppColors.accent : null,
              ),
              onPressed: () => toggleStarred(grammar, starred),
            ),
        ],
      ),
      body: grammarAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Lỗi: $e')),
        data: (all) {
          final grammar = findGrammar(all);
          if (grammar == null) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Không tìm thấy điểm ngữ pháp này ở cấp độ JLPT đang chọn.\nThử đổi cấp độ rồi quay lại.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.inkSoft),
                ),
              ),
            );
          }
          final known = progressAsync.valueOrNull?[grammar.id]?.isKnown == true;

          final partnerIds = <String>{
            for (final p in comparisonPairs)
              if (p.grammarIdA == grammar.id) p.grammarIdB,
            for (final p in comparisonPairs)
              if (p.grammarIdB == grammar.id) p.grammarIdA,
          };
          final partners = [
            for (final g in all)
              if (partnerIds.contains(g.id)) g,
          ];

          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [AppColors.plum, Color(0xFF8A3B70)],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.plum.withValues(alpha: 0.25),
                        blurRadius: 16,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Text(
                    grammar.title,
                    textAlign: TextAlign.center,
                    style: AppFonts.zenMaruGothic(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                if (grammar.meanings.isNotEmpty)
                  GrammarSection(
                    color: AppColors.plum,
                    label: 'Ý NGHĨA',
                    child: Column(
                      children: [
                        for (final (i, meaning) in grammar.meanings.indexed)
                          Padding(
                            padding: EdgeInsets.only(
                              bottom:
                                  i == grammar.meanings.length - 1 ? 0 : 10,
                            ),
                            child: GrammarMeaningCard(
                              index: i + 1,
                              meaning: meaning,
                            ),
                          ),
                      ],
                    ),
                  )
                else
                  GrammarSection(
                    color: AppColors.plum,
                    label: 'Ý NGHĨA',
                    child: GrammarInfoBox(
                      child: Text(
                        grammar.explanation,
                        style: const TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.ink,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ),
                if (grammar.meanings.isEmpty && grammar.exampleJp != null) ...[
                  const SizedBox(height: 14),
                  GrammarSection(
                    color: AppColors.indigo,
                    label: 'VÍ DỤ',
                    child: GrammarInfoBox(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          for (final (i, example) in [
                            (grammar.exampleJp!, grammar.exampleVi),
                            for (var j = 0; j < grammar.extraExamplesJp.length; j++)
                              (
                                grammar.extraExamplesJp[j],
                                j < grammar.extraExamplesVi.length
                                    ? grammar.extraExamplesVi[j]
                                    : null,
                              ),
                          ].indexed) ...[
                            if (i > 0) const SizedBox(height: 12),
                            if (i > 0)
                              const Divider(
                                height: 1,
                                color: AppColors.canvas,
                              ),
                            if (i > 0) const SizedBox(height: 12),
                            JpExampleText(
                              example.$1,
                              style: AppFonts.zenMaruGothic(
                                fontSize: 15,
                                fontWeight: FontWeight.w400,
                                color: AppColors.ink,
                              ),
                            ),
                            if (example.$2 != null) ...[
                              const SizedBox(height: 5),
                              Text(
                                example.$2!,
                                style: const TextStyle(
                                  fontSize: 11.5,
                                  color: AppColors.inkSoft,
                                ),
                              ),
                            ],
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
                if (grammar.memoryTip != null) ...[
                  const SizedBox(height: 14),
                  GrammarSection(
                    color: AppColors.moss,
                    label: 'MẸO GHI NHỚ',
                    child: GrammarInfoBox(
                      background: AppColors.chip,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.lightbulb_rounded,
                            color: AppColors.accent,
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              grammar.memoryTip!,
                              style: const TextStyle(
                                fontSize: 12.5,
                                color: AppColors.ink,
                                height: 1.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
                if (grammar.comparisonNote != null) ...[
                  const SizedBox(height: 14),
                  GrammarSection(
                    color: AppColors.plum,
                    label: 'SO SÁNH',
                    child: GrammarInfoBox(
                      background: AppColors.plumSoft,
                      child: Text(
                        grammar.comparisonNote!,
                        style: const TextStyle(
                          fontSize: 12.5,
                          color: AppColors.ink,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ),
                ],
                if (grammar.commonMistake != null) ...[
                  const SizedBox(height: 14),
                  GrammarSection(
                    color: AppColors.danger,
                    label: 'LỖI THƯỜNG GẶP',
                    child: GrammarInfoBox(
                      background: AppColors.dangerSoft,
                      child: Text(
                        grammar.commonMistake!,
                        style: const TextStyle(
                          fontSize: 12.5,
                          color: AppColors.danger,
                          height: 1.4,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
                if (partners.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  GrammarSection(
                    color: AppColors.indigo,
                    label: 'SO SÁNH VỚI',
                    child: Column(
                      children: [
                        for (final partner in partners)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(14),
                              onTap: () => context.push(
                                '/grammar-compare/${grammar.id}/${partner.id}',
                              ),
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.indigoSoft,
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.compare_arrows_rounded,
                                      color: AppColors.indigo,
                                      size: 18,
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        partner.title,
                                        style: AppFonts.zenMaruGothic(
                                          fontSize: 13.5,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.indigo,
                                        ),
                                      ),
                                    ),
                                    const Icon(
                                      Icons.chevron_right_rounded,
                                      color: AppColors.indigo,
                                      size: 18,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 14),
                Align(
                  alignment: Alignment.centerLeft,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(100),
                    onTap: () => context.push('/grammar/${grammar.id}/tutor'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 9,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.tealSoft,
                        borderRadius: BorderRadius.circular(100),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.auto_awesome_rounded,
                            size: 15,
                            color: AppColors.teal,
                          ),
                          SizedBox(width: 5),
                          Text(
                            'Hỏi AI',
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 12,
                              color: AppColors.teal,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton(
                        onPressed: () => context.push('/quiz/grammar'),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.plum,
                        ),
                        child: const Text('Quiz ngữ pháp'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: known
                          ? FilledButton.icon(
                              onPressed: () => toggleKnown(grammar, known),
                              style: FilledButton.styleFrom(
                                backgroundColor: AppColors.moss,
                              ),
                              icon: const Icon(
                                Icons.check_circle_rounded,
                                size: 18,
                              ),
                              label: const Text('Đã thuộc'),
                            )
                          : OutlinedButton.icon(
                              onPressed: () => toggleKnown(grammar, known),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.plum,
                                side: const BorderSide(
                                  color: AppColors.plum,
                                  width: 2,
                                ),
                              ),
                              icon: const Icon(Icons.check_rounded, size: 18),
                              label: const Text('Đánh dấu đã thuộc'),
                            ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
