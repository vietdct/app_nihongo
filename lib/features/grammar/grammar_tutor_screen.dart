import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../domain/entities/grammar_point.dart';
import '../lesson/providers/content_providers.dart';
import 'providers/grammar_comparison_providers.dart';
import 'providers/grammar_tutor_service.dart';

class _ChatTurn {
  const _ChatTurn({required this.fromUser, required this.text});

  final bool fromUser;
  final String text;
}

const _starterQuestions = [
  'Cho ví dụ câu khác dùng mẫu này',
  'Người mới hay dùng sai chỗ nào?',
  'Mẫu này khác gì mẫu dễ nhầm?',
];

/// Hỏi-đáp nhanh với AI về 1 mẫu ngữ pháp cụ thể — chat tự do + chip gợi ý,
/// KHÔNG lưu lịch sử (khác AI Kaiwa: đây là hỏi nhanh, không phải hội thoại
/// cần xem lại). Port trực tiếp từ `KanjiTutorScreen` — AI luôn được ép chỉ
/// dùng đúng dữ liệu thật của mẫu ngữ pháp này (xem
/// `grammar_tutor_service.dart` + Edge Function `ai-grammar-tutor`).
class GrammarTutorScreen extends ConsumerStatefulWidget {
  const GrammarTutorScreen({super.key, required this.grammarId});

  final String grammarId;

  @override
  ConsumerState<GrammarTutorScreen> createState() => _GrammarTutorScreenState();
}

class _GrammarTutorScreenState extends ConsumerState<GrammarTutorScreen> {
  final _textController = TextEditingController();
  final _scrollController = ScrollController();
  final List<_ChatTurn> _turns = [];
  List<String> _suggestions = _starterQuestions;
  bool _sending = false;
  String? _error;

  @override
  void dispose() {
    _textController.dispose();
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

  Future<void> _send(GrammarPoint grammar, String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty || _sending) return;

    final service = ref.read(grammarTutorServiceProvider);
    if (service == null) return;

    final allGrammar = ref.read(grammarListProvider).valueOrNull ?? const [];
    final comparisonPairs =
        ref.read(grammarComparisonPairsProvider).valueOrNull ?? const [];
    final partnerIds = <String>{
      for (final p in comparisonPairs)
        if (p.grammarIdA == grammar.id) p.grammarIdB,
      for (final p in comparisonPairs)
        if (p.grammarIdB == grammar.id) p.grammarIdA,
    };
    final comparedWith = [
      for (final g in allGrammar)
        if (partnerIds.contains(g.id)) g,
    ];

    final history = [
      for (final t in _turns)
        {'role': t.fromUser ? 'user' : 'ai', 'content': t.text},
    ];

    setState(() {
      _turns.add(_ChatTurn(fromUser: true, text: trimmed));
      _textController.clear();
      _sending = true;
      _error = null;
    });
    _scrollToBottom();

    try {
      final reply = await service.ask(
        grammar: grammar,
        comparedWith: comparedWith,
        history: history,
        message: trimmed,
      );
      if (!mounted) return;
      setState(() {
        _turns.add(_ChatTurn(fromUser: false, text: reply.reply));
        _suggestions = reply.suggestedQuestions.isEmpty
            ? _starterQuestions
            : reply.suggestedQuestions;
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
    final grammarAsync = ref.watch(grammarListProvider);

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(title: const Text('Hỏi AI về ngữ pháp')),
      body: grammarAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Lỗi: $e')),
        data: (all) {
          GrammarPoint? grammar;
          for (final g in all) {
            if (g.id == widget.grammarId) {
              grammar = g;
              break;
            }
          }
          if (grammar == null) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Không tìm thấy điểm ngữ pháp này ở cấp độ đang chọn.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.inkSoft),
                ),
              ),
            );
          }

          return SafeArea(
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  color: AppColors.tealSoft,
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          grammar.title,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                            color: AppColors.teal,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.fromLTRB(20, 8, 20, 0),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Hỏi bất cứ điều gì về mẫu này — ví dụ, lỗi thường gặp, so sánh...',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: AppColors.inkSoft,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
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
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.danger,
                      ),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final q in _suggestions)
                        ActionChip(
                          label: Text(q, style: const TextStyle(fontSize: 12)),
                          backgroundColor: AppColors.tealSoft,
                          side: BorderSide.none,
                          onPressed: _sending ? null : () => _send(grammar!, q),
                        ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _textController,
                          enabled: !_sending,
                          decoration: const InputDecoration(
                            hintText: 'Nhập câu hỏi...',
                            isDense: true,
                          ),
                          onSubmitted: (v) => _send(grammar!, v),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton.filled(
                        style: IconButton.styleFrom(
                          backgroundColor: AppColors.teal,
                        ),
                        onPressed: _sending
                            ? null
                            : () => _send(grammar!, _textController.text),
                        icon: const Icon(Icons.send_rounded),
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

  final _ChatTurn turn;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: turn.fromUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: const BoxConstraints(maxWidth: 300),
        decoration: BoxDecoration(
          color: turn.fromUser ? AppColors.plum : AppColors.card,
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
