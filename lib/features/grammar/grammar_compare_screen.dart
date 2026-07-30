import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../../domain/entities/grammar_point.dart';
import '../lesson/providers/content_providers.dart';
import 'widgets/grammar_content_sections.dart';

/// Đối chiếu 2 điểm ngữ pháp hay bị nhầm với nhau, xếp dọc (không side-by-
/// side vì màn hình điện thoại hẹp). Toàn bộ nội dung mỗi bên lấy nguyên từ
/// [GrammarPoint] của bên đó — không sinh thêm câu chữ so sánh mới, kể cả
/// mục SO SÁNH cũng là `comparisonNote` đã có sẵn trên từng bên.
class GrammarCompareScreen extends ConsumerWidget {
  const GrammarCompareScreen({super.key, required this.idA, required this.idB});

  final String idA;
  final String idB;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final grammarAsync = ref.watch(grammarListProvider);

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(title: const Text('So sánh ngữ pháp')),
      body: grammarAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Lỗi: $e')),
        data: (all) {
          GrammarPoint? find(String id) {
            for (final g in all) {
              if (g.id == id) return g;
            }
            return null;
          }

          final a = find(idA);
          final b = find(idB);
          if (a == null || b == null) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Không tìm thấy đủ 2 điểm ngữ pháp này ở cấp độ JLPT đang chọn.\nThử đổi cấp độ rồi quay lại.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.inkSoft),
                ),
              ),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _CompareCard(grammar: a, accent: AppColors.indigo),
                const SizedBox(height: 4),
                const _VsDivider(),
                const SizedBox(height: 4),
                _CompareCard(grammar: b, accent: AppColors.plum),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _VsDivider extends StatelessWidget {
  const _VsDivider();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Expanded(child: Divider(color: AppColors.border)),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 10),
          child: Text(
            'VS',
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 13,
              color: AppColors.inkFaint,
              letterSpacing: 1,
            ),
          ),
        ),
        Expanded(child: Divider(color: AppColors.border)),
      ],
    );
  }
}

class _CompareCard extends StatelessWidget {
  const _CompareCard({required this.grammar, required this.accent});

  final GrammarPoint grammar;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => context.push('/grammar/${grammar.id}'),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 18),
            decoration: BoxDecoration(
              color: accent,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    grammar.title,
                    style: AppFonts.zenMaruGothic(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
                const Icon(Icons.chevron_right_rounded,
                    color: Colors.white, size: 22,),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        GrammarSection(
          color: accent,
          label: 'Ý NGHĨA',
          child: GrammarInfoBox(
            child: Text(
              grammar.explanation,
              style: const TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                color: AppColors.ink,
                height: 1.4,
              ),
            ),
          ),
        ),
        if (grammar.exampleJp != null) ...[
          const SizedBox(height: 12),
          GrammarSection(
            color: accent,
            label: 'VÍ DỤ',
            child: GrammarInfoBox(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    grammar.exampleJp!,
                    style: AppFonts.zenMaruGothic(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: AppColors.ink,
                    ),
                  ),
                  if (grammar.exampleVi != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      grammar.exampleVi!,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.inkSoft,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
        if (grammar.comparisonNote != null) ...[
          const SizedBox(height: 12),
          GrammarSection(
            color: accent,
            label: 'ĐIỂM KHÁC BIỆT',
            child: GrammarInfoBox(
              background: AppColors.plumSoft,
              child: Text(
                grammar.comparisonNote!,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.ink,
                  height: 1.4,
                ),
              ),
            ),
          ),
        ],
        if (grammar.commonMistake != null) ...[
          const SizedBox(height: 12),
          GrammarSection(
            color: AppColors.danger,
            label: 'LỖI THƯỜNG GẶP',
            child: GrammarInfoBox(
              background: AppColors.dangerSoft,
              child: Text(
                grammar.commonMistake!,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.danger,
                  height: 1.4,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
