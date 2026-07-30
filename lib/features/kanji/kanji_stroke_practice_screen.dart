import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../domain/entities/kanji.dart';
import '../../shared/kanji_draw_canvas.dart';
import '../../shared/kanji_stroke_canvas.dart';
import '../../shared/kanji_stroke_matcher.dart';
import '../lesson/providers/content_providers.dart';

/// Luyện viết 1 chữ Hán đã biết — khác `KanjiDrawSearchScreen` (vẽ để TÌM
/// chữ chưa biết trong nhiều ứng viên): ở đây biết trước đúng 1 chữ mục
/// tiêu, canvas hiện nét mẫu mờ làm nền, sau khi vẽ đủ số nét thì chấm điểm
/// độ khớp bằng `scoreKanjiPractice` (tái dùng thuật toán so khớp đã có ở
/// `kanji_stroke_matcher.dart`, không viết thuật toán mới).
class KanjiStrokePracticeScreen extends ConsumerStatefulWidget {
  const KanjiStrokePracticeScreen({super.key, required this.kanjiId});

  final String kanjiId;

  @override
  ConsumerState<KanjiStrokePracticeScreen> createState() =>
      _KanjiStrokePracticeScreenState();
}

class _KanjiStrokePracticeScreenState
    extends ConsumerState<KanjiStrokePracticeScreen> {
  final _canvasKey = GlobalKey<KanjiDrawCanvasState>();
  List<List<Offset>> _strokes = const [];
  KanjiPracticeResult? _result;

  void _onStrokesChanged(List<List<Offset>> strokes, Kanji kanji) {
    final data = KanjiStrokeData.tryParse(kanji.strokeData);
    setState(() {
      _strokes = strokes;
      _result = (data != null && strokes.length >= data.strokes.length)
          ? scoreKanjiPractice(drawnStrokes: strokes, target: kanji)
          : null;
    });
  }

  void _reset() {
    _canvasKey.currentState?.clear();
    setState(() {
      _strokes = const [];
      _result = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final kanjiAsync = ref.watch(kanjiListProvider);

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        title: const Text('Luyện viết Kanji'),
        actions: [
          IconButton(
            tooltip: 'Xoá nét vừa vẽ',
            icon: const Icon(Icons.undo_rounded),
            onPressed: () => _canvasKey.currentState?.undoStroke(),
          ),
          IconButton(
            tooltip: 'Xoá hết',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _reset,
          ),
        ],
      ),
      body: kanjiAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Lỗi: $e')),
        data: (all) {
          Kanji? kanji;
          for (final k in all) {
            if (k.id == widget.kanjiId) {
              kanji = k;
              break;
            }
          }
          if (kanji == null) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Không tìm thấy chữ Kanji này ở cấp độ JLPT đang chọn.\nThử đổi cấp độ rồi quay lại.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.inkSoft),
                ),
              ),
            );
          }

          final data = KanjiStrokeData.tryParse(kanji.strokeData);
          if (data == null) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Chữ này chưa có dữ liệu nét để luyện tập.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.inkSoft),
                ),
              ),
            );
          }

          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        kanji.character,
                        style: AppFonts.zenMaruGothic(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: AppColors.ink,
                        ),
                      ),
                      if (kanji.hanViet.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        Text(
                          kanji.hanViet.join(' · ').toUpperCase(),
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.indigo,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Vẽ theo đúng thứ tự nét — nét mẫu mờ hiện làm nền.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12.5, color: AppColors.inkSoft),
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: KanjiDrawCanvas(
                      key: _canvasKey,
                      guideData: data,
                      onStrokesChanged: (s) => _onStrokesChanged(s, kanji!),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Nét ${_strokes.length}/${data.strokes.length}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: AppColors.inkSoft,
                    ),
                  ),
                  if (_result != null) ...[
                    const SizedBox(height: 16),
                    _ResultPanel(result: _result!, onRetry: _reset),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ResultPanel extends StatelessWidget {
  const _ResultPanel({required this.result, required this.onRetry});

  final KanjiPracticeResult result;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final pct = (result.accuracy * 100).round();
    final color = pct >= 70
        ? AppColors.moss
        : pct >= 40
            ? AppColors.accent
            : AppColors.danger;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          const Text(
            'Độ khớp nét vẽ',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.inkFaint,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '$pct%',
            style: TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            result.strokeCountMatches
                ? 'Đúng số nét'
                : 'Số nét chưa khớp với chữ chuẩn',
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: result.strokeCountMatches
                  ? AppColors.moss
                  : AppColors.accentStrong,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Chỉ số hình học so với nét chuẩn KanjiVG — mang tính tham khảo, không phải chấm điểm bằng AI.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 10.5, color: AppColors.inkFaint),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: onRetry,
              style: FilledButton.styleFrom(backgroundColor: AppColors.indigo),
              child: const Text('Luyện lại'),
            ),
          ),
        ],
      ),
    );
  }
}
