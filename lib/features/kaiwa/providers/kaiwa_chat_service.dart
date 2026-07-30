import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/network/supabase_providers.dart';
import '../../../domain/entities/kaiwa_message.dart';
import '../../../domain/entities/kaiwa_persona.dart';
import '../../../domain/entities/kaiwa_scenario.dart';

final kaiwaChatServiceProvider = Provider.autoDispose<KaiwaChatService?>((ref) {
  final sb = ref.watch(supabaseProvider);
  final userId = ref.watch(currentUserProvider)?.id;
  if (userId == null) return null;
  return KaiwaChatService(sb, userId);
});

/// Toàn bộ tin nhắn thật của 1 hội thoại — dùng cho màn Tóm tắt (tính điểm
/// trung bình, số câu đã sửa...) và luồng resume ở Dashboard.
final kaiwaMessagesProvider =
    FutureProvider.autoDispose.family<List<KaiwaMessage>, String>((ref, conversationId) async {
  final service = ref.watch(kaiwaChatServiceProvider);
  if (service == null) return [];
  return service.loadMessages(conversationId);
});

/// Gọi Edge Function `ai-kaiwa-chat` (proxy tới Anthropic, giữ API key
/// server-side) rồi lưu lại lượt hội thoại vào Supabase. Mỗi lượt người học
/// gửi câu, feedback AI chấm được đính kèm ngay trên message role 'user' đó
/// (không phải message 'ai' — message ai chỉ chứa câu trả lời tiếp theo).
///
/// Chỉ gộp lịch sử ~10 lượt gần nhất khi gọi AI — hội thoại càng dài, gửi
/// nguyên toàn bộ lịch sử càng làm request nặng và AI trả lời càng chậm/tốn
/// hơn, trong khi vài lượt trước đã đủ ngữ cảnh cho một lượt hội thoại tự nhiên.
const _maxHistoryTurns = 10;

// AI đôi khi gắn furigana dạng "chữ(đọc)" cả cho những đoạn không có Hán tự
// (VD "です(です)"), gây trùng lặp/khó nhìn. Chỉ giữ lại phần đọc nếu đoạn chữ
// đứng trước dấu ngoặc có ít nhất 1 ký tự Hán (一-鿿).
final _furiganaPattern = RegExp(r'([^()]+?)\(([぀-ヿ]+)\)');
final _kanjiPattern = RegExp(r'[一-鿿]');

String? _sanitizeFurigana(String? input) {
  if (input == null) return null;
  return input.replaceAllMapped(_furiganaPattern, (m) {
    final base = m.group(1)!;
    return _kanjiPattern.hasMatch(base) ? m.group(0)! : base;
  });
}

final _uuidRng = Random.secure();

// id sinh ở client (UUIDv4) để hiện tin nhắn lên UI ngay khi AI trả lời,
// không phải đợi round-trip ghi Supabase xong mới có id — DB ghi nền phía
// sau bằng chính id này nên không lệch với những gì người dùng đã thấy.
String _generateMessageId() {
  final bytes = List<int>.generate(16, (_) => _uuidRng.nextInt(256));
  bytes[6] = (bytes[6] & 0x0f) | 0x40;
  bytes[8] = (bytes[8] & 0x3f) | 0x80;
  String hex(int start, int end) =>
      bytes.sublist(start, end).map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  return '${hex(0, 4)}-${hex(4, 6)}-${hex(6, 8)}-${hex(8, 10)}-${hex(10, 16)}';
}

class KaiwaChatService {
  KaiwaChatService(this._sb, this._userId);

  final SupabaseClient _sb;
  final String _userId;

  Future<({String conversationId, KaiwaMessage aiMessage})> startConversation({
    required KaiwaPersona persona,
    required KaiwaScenario scenario,
    required String levelCode,
    String? levelId,
    String? seedWord,
  }) async {
    // Tạo phiên hội thoại và gọi AI song song — hai việc này không phụ thuộc
    // nhau, chạy tuần tự chỉ cộng thêm độ trễ ghi DB vào độ trễ (lớn hơn nhiều)
    // của việc gọi AI một cách vô ích.
    final results = await Future.wait<dynamic>([
      _sb.from('kaiwa_conversations').insert({
        'user_id': _userId,
        'persona_id': persona.id,
        'scenario_id': scenario.id,
        if (levelId != null) 'level_id': levelId,
      }).select().single(),
      _callAi(
        persona: persona,
        scenario: scenario,
        levelCode: levelCode,
        history: const [],
        message: null,
        seedWord: seedWord,
      ),
    ]);
    final conversationId = (results[0] as Map<String, dynamic>)['id'] as String;
    final aiJson = results[1] as Map<String, dynamic>;

    final aiMessage = KaiwaMessage(
      id: _generateMessageId(),
      role: KaiwaMessageRole.ai,
      contentJp: aiJson['reply_jp'] as String,
      translationVi: aiJson['reply_translation_vi'] as String?,
      furigana: _sanitizeFurigana(aiJson['reply_furigana'] as String?),
      suggestedReplyJp: aiJson['suggested_reply_jp'] as String?,
      suggestedReplyVi: aiJson['suggested_reply_vi'] as String?,
    );

    // Ghi DB nền — id đã biết trước nên UI không cần đợi round-trip này.
    unawaited(
      _sb.from('kaiwa_messages').insert({
        'id': aiMessage.id,
        'conversation_id': conversationId,
        'user_id': _userId,
        'role': 'ai',
        'content_jp': aiMessage.contentJp,
        'translation_vi': aiMessage.translationVi,
        'furigana': aiMessage.furigana,
        'suggested_reply_jp': aiMessage.suggestedReplyJp,
        'suggested_reply_vi': aiMessage.suggestedReplyVi,
      }).catchError((Object e) {
        debugPrint('Kaiwa: lỗi lưu tin nhắn mở đầu: $e');
        return <String, dynamic>{};
      }),
    );

    return (conversationId: conversationId, aiMessage: aiMessage);
  }

  Future<({KaiwaMessage userMessage, KaiwaMessage aiMessage})> sendMessage({
    required String conversationId,
    required KaiwaPersona persona,
    required KaiwaScenario scenario,
    required String levelCode,
    required List<KaiwaMessage> history,
    required String text,
  }) async {
    final recentHistory =
        history.length > _maxHistoryTurns ? history.sublist(history.length - _maxHistoryTurns) : history;
    final historyPayload = [
      for (final m in recentHistory)
        {'role': m.role == KaiwaMessageRole.ai ? 'ai' : 'user', 'content': m.contentJp},
    ];

    final aiJson = await _callAi(
      persona: persona,
      scenario: scenario,
      levelCode: levelCode,
      history: historyPayload,
      message: text,
    );
    final feedbackJson = aiJson['feedback'] as Map<String, dynamic>?;
    final hasFeedback = feedbackJson != null && (feedbackJson['rating'] as int? ?? 0) > 0;

    final userMessage = KaiwaMessage(
      id: _generateMessageId(),
      role: KaiwaMessageRole.user,
      contentJp: text,
      feedback: hasFeedback ? KaiwaFeedback.fromJson(feedbackJson) : null,
    );
    final aiMessage = KaiwaMessage(
      id: _generateMessageId(),
      role: KaiwaMessageRole.ai,
      contentJp: aiJson['reply_jp'] as String,
      translationVi: aiJson['reply_translation_vi'] as String?,
      furigana: _sanitizeFurigana(aiJson['reply_furigana'] as String?),
      suggestedReplyJp: aiJson['suggested_reply_jp'] as String?,
      suggestedReplyVi: aiJson['suggested_reply_vi'] as String?,
    );

    // id đã biết trước từ client nên UI hiện ngay sau khi AI trả lời — 3 lượt
    // ghi DB chạy nền phía sau, không chặn người dùng đợi round-trip Supabase.
    unawaited(
      Future.wait<dynamic>([
        _sb.from('kaiwa_messages').insert({
          'id': userMessage.id,
          'conversation_id': conversationId,
          'user_id': _userId,
          'role': 'user',
          'content_jp': text,
          if (hasFeedback) 'feedback': feedbackJson,
        }),
        _sb.from('kaiwa_messages').insert({
          'id': aiMessage.id,
          'conversation_id': conversationId,
          'user_id': _userId,
          'role': 'ai',
          'content_jp': aiMessage.contentJp,
          'translation_vi': aiMessage.translationVi,
          'furigana': aiMessage.furigana,
          'suggested_reply_jp': aiMessage.suggestedReplyJp,
          'suggested_reply_vi': aiMessage.suggestedReplyVi,
        }),
        _sb.from('kaiwa_conversations').update({
          'last_message_at': DateTime.now().toUtc().toIso8601String(),
        }).eq('id', conversationId),
      ]).catchError((Object e) {
        debugPrint('Kaiwa: lỗi lưu tin nhắn: $e');
        return <dynamic>[];
      }),
    );

    return (userMessage: userMessage, aiMessage: aiMessage);
  }

  /// Nạp lại toàn bộ lịch sử tin nhắn thật của 1 hội thoại đã có — dùng khi
  /// người dùng bấm "Tiếp tục hội thoại" từ Dashboard thay vì bắt đầu mới.
  /// Không gọi AI, chỉ đọc dữ liệu đã lưu.
  Future<List<KaiwaMessage>> loadMessages(String conversationId) async {
    final rows = await _sb
        .from('kaiwa_messages')
        .select()
        .eq('conversation_id', conversationId)
        .order('created_at', ascending: true);

    return [
      for (final r in rows)
        KaiwaMessage(
          id: r['id'] as String,
          role: r['role'] == 'ai' ? KaiwaMessageRole.ai : KaiwaMessageRole.user,
          contentJp: r['content_jp'] as String,
          translationVi: r['translation_vi'] as String?,
          furigana: _sanitizeFurigana(r['furigana'] as String?),
          feedback: r['feedback'] == null
              ? null
              : KaiwaFeedback.fromJson((r['feedback'] as Map).cast<String, dynamic>()),
          suggestedReplyJp: r['suggested_reply_jp'] as String?,
          suggestedReplyVi: r['suggested_reply_vi'] as String?,
        ),
    ];
  }

  Future<Map<String, dynamic>> _callAi({
    required KaiwaPersona persona,
    required KaiwaScenario scenario,
    required String levelCode,
    required List<Map<String, String>> history,
    String? message,
    String? seedWord,
  }) async {
    // Không có timeout thì nếu mạng chậm hoặc Anthropic/Gemini phản hồi lâu
    // (edge function còn thử fallback tuần tự 2 lượt), màn hình sẽ đứng chờ
    // vô thời hạn ở spinner "đang mở hội thoại" — không báo lỗi, không có
    // cách nào thoát ra ngoài trừ thoát hẳn màn hình.
    final res = await _sb.functions
        .invoke(
          'ai-kaiwa-chat',
          body: {
            'personaName': persona.name,
            'personaRole': persona.role,
            'personaPersonality': persona.personality,
            'politenessLevel': persona.politenessLevel,
            'scenarioTitle': scenario.title,
            'scenarioContext': scenario.systemContext,
            'jlptLevel': levelCode,
            'history': history,
            'message': message,
            if (seedWord != null) 'seedWord': seedWord,
          },
        )
        .timeout(
          const Duration(seconds: 30),
          onTimeout: () => throw Exception('AI phản hồi quá lâu, vui lòng thử lại.'),
        );
    final data = res.data;
    if (res.status != 200 || data is! Map) {
      final err = data is Map ? data['error'] as String? : null;
      throw Exception(err ?? 'Lỗi gọi AI, vui lòng thử lại.');
    }
    return data.cast<String, dynamic>();
  }
}
