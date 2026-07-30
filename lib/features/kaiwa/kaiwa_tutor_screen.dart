import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../domain/entities/kaiwa_feedback_context.dart';
import 'providers/kaiwa_tutor_service.dart';

class _ChatTurn {
  const _ChatTurn({required this.fromUser, required this.text});

  final bool fromUser;
  final String text;
}

const _starterQuestions = [
  'Vì sao câu của tôi chưa tự nhiên?',
  'Cho ví dụ câu khác dùng cách nói này',
  'Cách nói này có lịch sự hơn không?',
];

/// Hỏi-đáp nhanh với AI về 1 câu người học đã nói trong buổi Kaiwa + feedback
/// đã chấm — KHÔNG lưu lịch sử (giống `KanjiTutorScreen`/`GrammarTutorScreen`,
/// khác hội thoại nhập vai chính: đây chỉ để đào sâu 1 lượt nói cụ thể).
class KaiwaTutorScreen extends ConsumerStatefulWidget {
  const KaiwaTutorScreen({super.key, required this.turn});

  final KaiwaFeedbackContext turn;

  @override
  ConsumerState<KaiwaTutorScreen> createState() => _KaiwaTutorScreenState();
}

class _KaiwaTutorScreenState extends ConsumerState<KaiwaTutorScreen> {
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

  Future<void> _send(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty || _sending) return;

    final service = ref.read(kaiwaTutorServiceProvider);
    if (service == null) return;

    final history = [
      for (final t in _turns) {'role': t.fromUser ? 'user' : 'ai', 'content': t.text},
    ];

    setState(() {
      _turns.add(_ChatTurn(fromUser: true, text: trimmed));
      _textController.clear();
      _sending = true;
      _error = null;
    });
    _scrollToBottom();

    try {
      final reply = await service.ask(turn: widget.turn, history: history, message: trimmed);
      if (!mounted) return;
      setState(() {
        _turns.add(_ChatTurn(fromUser: false, text: reply.reply));
        _suggestions = reply.suggestedQuestions.isEmpty ? _starterQuestions : reply.suggestedQuestions;
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
    final turn = widget.turn;
    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(title: const Text('Hỏi AI về câu này')),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              color: AppColors.tealSoft,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    turn.originalSentence,
                    style: AppFonts.zenMaruGothic(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.ink),
                  ),
                  if ((turn.betterPhrasing ?? '').trim().isNotEmpty &&
                      turn.betterPhrasing!.trim() != turn.originalSentence.trim()) ...[
                    const SizedBox(height: 4),
                    Text(
                      turn.betterPhrasing!,
                      style: AppFonts.zenMaruGothic(fontSize: 13.5, color: AppColors.moss, fontWeight: FontWeight.w600),
                    ),
                  ],
                ],
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
                      child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
                    );
                  }
                  return _Bubble(turn: _turns[i]);
                },
              ),
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(_error!, style: const TextStyle(fontSize: 12, color: AppColors.danger)),
              ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final q in _suggestions)
                    ActionChip(
                      label: Text(q, style: const TextStyle(fontSize: 12)),
                      backgroundColor: AppColors.tealSoft,
                      side: BorderSide.none,
                      onPressed: _sending ? null : () => _send(q),
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
                      decoration: const InputDecoration(hintText: 'Nhập câu hỏi...', isDense: true),
                      onSubmitted: _send,
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    style: IconButton.styleFrom(backgroundColor: AppColors.teal),
                    onPressed: _sending ? null : () => _send(_textController.text),
                    icon: const Icon(Icons.send_rounded),
                  ),
                ],
              ),
            ),
          ],
        ),
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
          color: turn.fromUser ? AppColors.teal : AppColors.card,
          borderRadius: BorderRadius.circular(16),
          border: turn.fromUser ? null : Border.all(color: AppColors.border),
        ),
        child: Text(
          turn.text,
          style: TextStyle(fontSize: 13.5, color: turn.fromUser ? Colors.white : AppColors.ink),
        ),
      ),
    );
  }
}
