import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/network/supabase_providers.dart';

final kaiwaPronunciationServiceProvider = Provider.autoDispose<KaiwaPronunciationService?>((ref) {
  final sb = ref.watch(supabaseProvider);
  final userId = ref.watch(currentUserProvider)?.id;
  if (userId == null) return null;
  return KaiwaPronunciationService(sb);
});

/// Cảm nhận CHỦ QUAN của AI về mức độ giống câu mẫu — không phải điểm đo
/// phoneme/ngữ điệu khoa học (app chưa tích hợp dịch vụ chấm phát âm chuyên
/// dụng). Xem `ai-pronunciation-feedback` edge function.
enum PronunciationImpression { ratTot, khaTot, canLuyenThem, chuaRo }

PronunciationImpression _parseImpression(String? raw) {
  switch (raw) {
    case 'rat_tot':
      return PronunciationImpression.ratTot;
    case 'kha_tot':
      return PronunciationImpression.khaTot;
    case 'can_luyen_them':
      return PronunciationImpression.canLuyenThem;
    default:
      return PronunciationImpression.chuaRo;
  }
}

class PronunciationFeedback {
  const PronunciationFeedback({
    required this.heardText,
    required this.impression,
    required this.comment,
    this.isLocalOnly = false,
  });

  final String heardText;
  final PronunciationImpression impression;
  final String comment;

  /// true nếu kết quả này được chặn cục bộ trên máy (VD phát hiện im lặng
  /// qua `analyzeWavSilence`) và KHÔNG gọi AI — không tốn phí, nhưng cũng
  /// không phải "AI đã nghe và nhận xét" nên UI cần ghi rõ khác đi.
  final bool isLocalOnly;
}

/// Gọi Edge Function `ai-pronunciation-feedback` — gửi audio ghi âm thật của
/// người học (khác `computeShadowingScore` trong `shadowing_scorer.dart`
/// vốn chỉ so khớp văn bản STT, miễn phí). Đây là tính năng AI trả phí, chỉ
/// gọi khi người học chủ động bấm "Xin AI nhận xét" (opt-in).
class KaiwaPronunciationService {
  KaiwaPronunciationService(this._sb);

  final SupabaseClient _sb;

  Future<PronunciationFeedback> assess({
    required String targetJp,
    required Uint8List audioBytes,
    required String mimeType,
  }) async {
    final res = await _sb.functions.invoke(
      'ai-pronunciation-feedback',
      body: {
        'targetJp': targetJp,
        'audioBase64': base64Encode(audioBytes),
        'mimeType': mimeType,
      },
    ).timeout(
      const Duration(seconds: 30),
      onTimeout: () => throw Exception('AI phản hồi quá lâu, vui lòng thử lại.'),
    );

    final data = res.data;
    if (res.status != 200 || data is! Map) {
      final err = data is Map ? data['error'] as String? : null;
      throw Exception(err ?? 'Lỗi gọi AI, vui lòng thử lại.');
    }
    return PronunciationFeedback(
      heardText: data['heardText'] as String? ?? '',
      impression: _parseImpression(data['impression'] as String?),
      comment: data['comment'] as String? ?? '',
    );
  }
}
