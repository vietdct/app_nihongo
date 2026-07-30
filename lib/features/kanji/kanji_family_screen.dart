import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../../domain/entities/kanji.dart';
import '../lesson/providers/content_providers.dart';
import 'providers/kanji_family_providers.dart';

/// Cây quan hệ ghép-bộ của 1 kanji — chữ cha (được ghép từ) phía trên, chữ
/// hiện tại nổi bật ở giữa, chữ con (dùng chữ này làm bộ) phía dưới. Dữ liệu
/// từ `computeKanjiFamily` (IDS thật, xem `kanji_family_providers.dart`).
class KanjiFamilyScreen extends ConsumerWidget {
  const KanjiFamilyScreen({super.key, required this.kanjiId});

  final String kanjiId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final kanjiAsync = ref.watch(kanjiListProvider);
    final familyAsync = ref.watch(kanjiFamilyProvider(kanjiId));

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(title: const Text('Gia đình Kanji')),
      body: kanjiAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Lỗi: $e')),
        data: (all) {
          Kanji? target;
          for (final k in all) {
            if (k.id == kanjiId) {
              target = k;
              break;
            }
          }
          final resolvedTarget = target;
          if (resolvedTarget == null) {
            return const _EmptyMessage(
              text: 'Không tìm thấy chữ Kanji này ở cấp độ đang chọn.',
            );
          }

          return familyAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Lỗi: $e')),
            data: (family) {
              if (family.isEmpty) {
                return const _EmptyMessage(
                  text:
                      'Chữ này chưa tìm thấy quan hệ ghép-bộ thật với chữ khác trong app.',
                );
              }
              return SafeArea(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
                  child: Column(
                    children: [
                      if (family.parents.isNotEmpty) ...[
                        const _SectionLabel('GHÉP TỪ'),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          alignment: WrapAlignment.center,
                          children: [
                            for (final p in family.parents)
                              _MemberCard(kanji: p),
                          ],
                        ),
                        const SizedBox(height: 8),
                        const Icon(Icons.arrow_downward_rounded,
                            color: AppColors.inkFaint,),
                        const SizedBox(height: 8),
                      ],
                      _CenterCard(kanji: resolvedTarget),
                      if (family.children.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        const Icon(Icons.arrow_downward_rounded,
                            color: AppColors.inkFaint,),
                        const SizedBox(height: 8),
                        const _SectionLabel('CÁC CHỮ DÙNG BỘ NÀY'),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          alignment: WrapAlignment.center,
                          children: [
                            for (final c in family.children)
                              _MemberCard(kanji: c),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _EmptyMessage extends StatelessWidget {
  const _EmptyMessage({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppColors.inkSoft),
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
      text,
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w800,
        color: AppColors.inkFaint,
        letterSpacing: 0.5,
      ),
    );
  }
}

class _CenterCard extends StatelessWidget {
  const _CenterCard({required this.kanji});

  final Kanji kanji;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 160,
      height: 160,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.indigo, Color(0xFF7B61FF)],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.indigo.withValues(alpha: 0.35),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            kanji.character,
            style: AppFonts.zenMaruGothic(
              fontSize: 52,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          if (kanji.hanViet.isNotEmpty)
            Text(
              kanji.hanViet.join(' · ').toUpperCase(),
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                letterSpacing: 0.5,
              ),
            ),
        ],
      ),
    );
  }
}

class _MemberCard extends StatelessWidget {
  const _MemberCard({required this.kanji});

  final Kanji kanji;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => context.push('/kanji/${kanji.id}'),
      child: Container(
        width: 84,
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              kanji.character,
              style: AppFonts.zenMaruGothic(
                fontSize: 26,
                fontWeight: FontWeight.w700,
                color: AppColors.ink,
              ),
            ),
            if (kanji.hanViet.isNotEmpty)
              Text(
                kanji.hanViet.first.toUpperCase(),
                style: const TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.indigo,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
