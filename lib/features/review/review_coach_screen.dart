import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../domain/entities/review_mistake.dart';
import 'providers/review_coach_service.dart';
import 'providers/review_mistakes_providers.dart';

class _CoachTurn {
  const _CoachTurn({required this.fromUser, required this.text});

  final bool fromUser;
  final String text;
}

/// AI Review Coach — hỏi-đáp về các lỗi đã ghi nhận qua 5 câu hỏi mẫu cố
/// định (MVP theo `docs/REVIEW_DESIGN.md` §12/§16, chưa hỗ trợ chat tự do).
/// Tái dùng hạ tầng AI Kaiwa (Gemini + Anthropic, quota/token tracking) qua
/// Edge Function `ai-review-coach` — xem `providers/review_coach_service.dart`.
class ReviewCoachScreen extends ConsumerStatefulWidget {
  const ReviewCoachScreen({super.key});

  @override
  ConsumerState<ReviewCoachScreen> createState() => _ReviewCoachScreenState();
}

class _ReviewCoachScreenState extends ConsumerState<ReviewCoachScreen> {
  final _scrollController = ScrollController();
  final List<_CoachTurn> _turns = [];
  bool _sending = false;
  String? _error;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _ask(ReviewCoachQuestion q, List<ReviewMistake> mistakes) async {
    if (_sending) return;
    final service = ref.read(reviewCoachServiceProvider);
    if (service == null) return;

    setState(() {
      _turns.add(_CoachTurn(fromUser: true, text: q.label));
      _sending = true;
      _error = null;
    });
    _scrollToBottom();

    try {
      final reply = await service.ask(q, mistakes);
      if (!mounted) return;
      setState(() {
        _turns.add(_CoachTurn(fromUser: false, text: reply));
        _sending = false;
      });
      _scrollToBottom();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _sending = false;
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final mistakesAsync = ref.watch(reviewMistakesProvider);

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(title: const Text('AI Review Coach')),
      body: mistakesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Lỗi: $e')),
        data: (mistakes) {
          if (mistakes.isEmpty && _turns.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.auto_awesome_outlined,
                      size: 40,
                      color: AppColors.inkFaint,
                    ),
                    SizedBox(height: 12),
                    Text(
                      'Chưa có lỗi nào để AI phân tích.\nLàm vài lượt ôn tập rồi quay lại đây nhé!',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.inkSoft, fontSize: 13),
                    ),
                  ],
                ),
              ),
            );
          }

          return SafeArea(
            child: Column(
              children: [
                const Padding(
                  padding: EdgeInsets.fromLTRB(20, 8, 20, 0),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Chọn 1 câu hỏi — AI trả lời dựa đúng trên các lỗi bạn đã ghi nhận.',
                      style: TextStyle(fontSize: 11.5, color: AppColors.inkSoft),
                    ),
                  ),
                ),
                Expanded(
                  child: _turns.isEmpty
                      ? const Center(
                          child: Padding(
                            padding: EdgeInsets.all(24),
                            child: Text(
                              'Bấm 1 câu hỏi bên dưới để bắt đầu.',
                              style: TextStyle(
                                color: AppColors.inkFaint,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        )
                      : ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.all(16),
                          itemCount: _turns.length + (_sending ? 1 : 0),
                          itemBuilder: (context, i) {
                            if (i >= _turns.length) {
                              return const Padding(
                                padding: EdgeInsets.symmetric(vertical: 8),
                                child: SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                ),
                              );
                            }
                            return _Bubble(turn: _turns[i]);
                          },
                        ),
                ),
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      _error!,
                      style: const TextStyle(fontSize: 12, color: AppColors.danger),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final q in ReviewCoachQuestion.values)
                        ActionChip(
                          label: Text(q.label, style: const TextStyle(fontSize: 12)),
                          backgroundColor: AppColors.accentSoft,
                          side: BorderSide.none,
                          onPressed: _sending || mistakes.isEmpty
                              ? null
                              : () => _ask(q, mistakes),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.turn});

  final _CoachTurn turn;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: turn.fromUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: const BoxConstraints(maxWidth: 300),
        decoration: BoxDecoration(
          color: turn.fromUser ? AppColors.accentStrong : AppColors.card,
          borderRadius: BorderRadius.circular(16),
          border: turn.fromUser ? null : Border.all(color: AppColors.border),
        ),
        child: Text(
          turn.text,
          style: TextStyle(
            fontSize: 13.5,
            color: turn.fromUser ? Colors.white : AppColors.ink,
          ),
        ),
      ),
    );
  }
}
