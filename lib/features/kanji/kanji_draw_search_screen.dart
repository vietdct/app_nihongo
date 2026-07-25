import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../../shared/kanji_draw_canvas.dart';
import '../../shared/kanji_stroke_matcher.dart';
import '../lesson/providers/content_providers.dart';

/// Tìm kanji bằng cách vẽ nét — vẽ đúng thứ tự viết, kết quả thu hẹp dần
/// sau mỗi nét thay vì phải vẽ xong cả chữ mới ra gợi ý.
class KanjiDrawSearchScreen extends ConsumerStatefulWidget {
  const KanjiDrawSearchScreen({super.key});

  @override
  ConsumerState<KanjiDrawSearchScreen> createState() => _KanjiDrawSearchScreenState();
}

class _KanjiDrawSearchScreenState extends ConsumerState<KanjiDrawSearchScreen> {
  final _canvasKey = GlobalKey<KanjiDrawCanvasState>();
  List<KanjiDrawMatch> _matches = const [];
  bool _hasStrokes = false;

  void _onAllStrokesChanged(List<List<Offset>> strokes) {
    final all = ref.read(kanjiListProvider).valueOrNull ?? const [];
    setState(() {
      _hasStrokes = strokes.isNotEmpty;
      _matches = strokes.isEmpty ? const [] : matchKanjiByStrokes(drawnStrokes: strokes, candidates: all);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Vẽ để tìm kanji'),
        actions: [
          IconButton(
            tooltip: 'Xoá nét vừa vẽ',
            icon: const Icon(Icons.undo_rounded),
            onPressed: () => _canvasKey.currentState?.undoStroke(),
          ),
          IconButton(
            tooltip: 'Xoá hết',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => _canvasKey.currentState?.clear(),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(24, 12, 24, 0),
              child: Text(
                'Vẽ từng nét theo đúng thứ tự viết — kết quả hiện dần theo mỗi nét bạn vẽ.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12.5, color: AppColors.inkSoft),
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: KanjiDrawCanvas(key: _canvasKey, onStrokesChanged: _onAllStrokesChanged),
            ),
            const SizedBox(height: 20),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text('Gợi ý', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.inkSoft)),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: !_hasStrokes
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: Text(
                          'Bắt đầu vẽ nét đầu tiên của chữ Hán ở khung phía trên.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: AppColors.inkSoft),
                        ),
                      ),
                    )
                  : _matches.isEmpty
                      ? const Center(
                          child: Padding(
                            padding: EdgeInsets.all(24),
                            child: Text(
                              'Chưa tìm thấy chữ nào khớp. Thử vẽ lại nét vừa rồi cho rõ hơn.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: AppColors.inkSoft),
                            ),
                          ),
                        )
                      : GridView.builder(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 5,
                            mainAxisSpacing: 10,
                            crossAxisSpacing: 10,
                            childAspectRatio: 0.85,
                          ),
                          itemCount: _matches.length,
                          itemBuilder: (context, i) {
                            final match = _matches[i];
                            return InkWell(
                              borderRadius: BorderRadius.circular(14),
                              onTap: () => context.push('/kanji/${match.kanji.id}'),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: AppColors.card,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: AppColors.border, width: 0.6),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(match.kanji.character, style: AppFonts.zenMaruGothic(fontSize: 22, color: AppColors.ink)),
                                    const SizedBox(height: 3),
                                    Text(
                                      match.kanji.primaryMeaning,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(fontSize: 9.5, color: AppColors.inkSoft),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
