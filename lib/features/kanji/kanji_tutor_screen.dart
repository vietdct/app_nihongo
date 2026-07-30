import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../domain/entities/kanji.dart';
import '../lesson/providers/content_providers.dart';
import 'providers/kanji_family_providers.dart';
import 'providers/kanji_tutor_service.dart';

class _ChatTurn {
  const _ChatTurn({required this.fromUser, required this.text});

  final bool fromUser;
  final String text;
}

const _starterQuestions = [
  'Còn mẹo nhớ nào khác không?',
  'Cho ví dụ câu khác dùng chữ này',
  'Chữ này dễ nhầm với chữ nào?',
];

/// Hỏi-đáp nhanh với AI về 1 chữ Hán cụ thể — chat tự do + chip gợi ý, KHÔNG
/// lưu lịch sử (khác AI Kaiwa: đây là hỏi nhanh, không phải hội thoại cần
/// xem lại). AI luôn được ép chỉ dùng đúng dữ liệu thật của chữ này (xem
/// `kanji_tutor_service.dart` + Edge Function `ai-kanji-tutor`).
class KanjiTutorScreen extends ConsumerStatefulWidget {
  const KanjiTutorScreen({super.key, required this.kanjiId});

  final String kanjiId;

  @override
  ConsumerState<KanjiTutorScreen> createState() => _KanjiTutorScreenState();
}

class _KanjiTutorScreenState extends ConsumerState<KanjiTutorScreen> {
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

  Future<void> _send(Kanji kanji, String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty || _sending) return;

    final service = ref.read(kanjiTutorServiceProvider);
    if (service == null) return;

    final vocabList = ref.read(vocabularyListProvider).valueOrNull ?? const [];
    final relatedVocab = [
      for (final v in vocabList)
        if (v.word.contains(kanji.character)) v,
    ].take(5).toList();
    final family = ref.read(kanjiFamilyProvider(widget.kanjiId)).valueOrNull;

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
        kanji: kanji,
        relatedVocab: relatedVocab,
        familyParents: family?.parents ?? const [],
        familyChildren: family?.children ?? const [],
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
    final kanjiAsync = ref.watch(kanjiListProvider);

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(title: const Text('Hỏi AI về Kanji')),
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
                  'Không tìm thấy chữ Kanji này ở cấp độ đang chọn.',
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
                      Text(
                        kanji.character,
                        style: AppFonts.zenMaruGothic(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: AppColors.teal,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Hỏi bất cứ điều gì về chữ này — mẹo nhớ, từ ví dụ, so sánh...',
                          style: TextStyle(
                            fontSize: 11.5,
                            color: AppColors.inkSoft,
                          ),
                        ),
                      ),
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
                          onPressed: _sending ? null : () => _send(kanji!, q),
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
                          onSubmitted: (v) => _send(kanji!, v),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton.filled(
                        style: IconButton.styleFrom(
                          backgroundColor: AppColors.teal,
                        ),
                        onPressed: _sending
                            ? null
                            : () => _send(kanji!, _textController.text),
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
          color: turn.fromUser ? AppColors.indigo : AppColors.card,
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
