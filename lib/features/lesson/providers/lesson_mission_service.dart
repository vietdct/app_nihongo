import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/network/supabase_providers.dart';
import '../../../domain/entities/kaiwa_message.dart';
import '../../../domain/services/lesson_mission_generator.dart';

final lessonMissionServiceProvider = Provider.autoDispose<LessonMissionService?>((ref) {
  final sb = ref.watch(supabaseProvider);
  final userId = ref.watch(currentUserProvider)?.id;
  if (userId == null) return null;
  return LessonMissionService(sb);
});

// AI đôi khi gắn furigana dạng "chữ(đọc)" cả cho những đoạn không có Hán tự
// (VD "です(です)") — chỉ giữ phần đọc nếu đoạn trước ngoặc có ít nhất 1 chữ Hán.
final _furiganaPattern = RegExp(r'([^()]+?)\(([぀-ヿ]+)\)');
final _kanjiPattern = RegExp(r'[一-鿿]');

String? _sanitizeFurigana(String? input) {
  if (input == null) return null;
  return input.replaceAllMapped(_furiganaPattern, (m) {
    final base = m.group(1)!;
    return _kanjiPattern.hasMatch(base) ? m.group(0)! : base;
  });
}

int _idCounter = 0;

// Mission Challenge không ghi DB (xem lớp doc bên dưới) nên id chỉ cần duy
// nhất trong phiên hiện tại để làm key danh sách UI — không cần UUID thật.
String _generateMessageId() => 'mission-${DateTime.now().microsecondsSinceEpoch}-${_idCounter++}';

/// Kết quả 1 lượt gọi AI — [usedVocabJp]/[usedGrammarTitles] là mục tiêu
/// người học vừa dùng đúng TRONG LƯỢT NÀY (không cộng dồn; cộng dồn tiến độ
/// thuộc về `LessonMissionController`, service chỉ trả dữ liệu thô).
class LessonMissionTurnResult {
  const LessonMissionTurnResult({
    required this.userMessage,
    required this.aiMessage,
    required this.usedVocabJp,
    required this.usedGrammarTitles,
  });

  final KaiwaMessage? userMessage;
  final KaiwaMessage aiMessage;
  final List<String> usedVocabJp;
  final List<String> usedGrammarTitles;
}

/// Gọi Edge Function `ai-lesson-mission`. Không lưu Supabase — phiên Mission
/// gắn với 1 lượt chạy `LessonRunnerScreen`, vốn cũng không lưu tiến trình dở
/// dang giữa các phiên (autoDispose, xem `lesson_runner_providers.dart`), nên
/// không cần bảng hội thoại riêng như Kaiwa (vốn có màn Lịch sử/Ôn tập SRS
/// cần dữ liệu bền — Mission Challenge không có các màn đó).
class LessonMissionService {
  LessonMissionService(this._sb);

  final SupabaseClient _sb;

  Future<LessonMissionTurnResult> start({
    required LessonMission mission,
    required String jlptLevel,
  }) async {
    final aiJson = await _callAi(mission: mission, jlptLevel: jlptLevel, history: const [], message: null);
    return LessonMissionTurnResult(
      userMessage: null,
      aiMessage: _aiMessageFrom(aiJson),
      usedVocabJp: const [],
      usedGrammarTitles: const [],
    );
  }

  Future<LessonMissionTurnResult> send({
    required LessonMission mission,
    required String jlptLevel,
    required List<KaiwaMessage> history,
    required String text,
  }) async {
    final historyPayload = [
      for (final m in history)
        {'role': m.role == KaiwaMessageRole.ai ? 'ai' : 'user', 'content': m.contentJp},
    ];

    final aiJson = await _callAi(mission: mission, jlptLevel: jlptLevel, history: historyPayload, message: text);
    final feedbackJson = aiJson['feedback'] as Map<String, dynamic>?;
    final hasFeedback = feedbackJson != null && (feedbackJson['rating'] as int? ?? 0) > 0;

    final userMessage = KaiwaMessage(
      id: _generateMessageId(),
      role: KaiwaMessageRole.user,
      contentJp: text,
      feedback: hasFeedback ? KaiwaFeedback.fromJson(feedbackJson) : null,
    );

    return LessonMissionTurnResult(
      userMessage: userMessage,
      aiMessage: _aiMessageFrom(aiJson),
      usedVocabJp: (aiJson['used_vocab'] as List?)?.cast<String>() ?? const [],
      usedGrammarTitles: (aiJson['used_grammar'] as List?)?.cast<String>() ?? const [],
    );
  }

  KaiwaMessage _aiMessageFrom(Map<String, dynamic> aiJson) => KaiwaMessage(
        id: _generateMessageId(),
        role: KaiwaMessageRole.ai,
        contentJp: aiJson['reply_jp'] as String,
        translationVi: aiJson['reply_translation_vi'] as String?,
        furigana: _sanitizeFurigana(aiJson['reply_furigana'] as String?),
        suggestedReplyJp: aiJson['suggested_reply_jp'] as String?,
        suggestedReplyVi: aiJson['suggested_reply_vi'] as String?,
      );

  Future<Map<String, dynamic>> _callAi({
    required LessonMission mission,
    required String jlptLevel,
    required List<Map<String, String>> history,
    String? message,
  }) async {
    final res = await _sb.functions
        .invoke(
          'ai-lesson-mission',
          body: {
            'lessonTitle': mission.lessonTitle,
            'jlptLevel': jlptLevel,
            'targetVocab': [
              for (final v in mission.targetVocab) {'jp': v.word, 'meaningVi': v.primaryMeaning},
            ],
            'targetGrammar': [
              for (final g in mission.targetGrammar) {'title': g.title, 'meaningVi': g.explanation},
            ],
            'history': history,
            'message': message,
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
