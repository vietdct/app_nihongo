import 'package:supabase_flutter/supabase_flutter.dart';

/// Lỗi do Edge Function AI trả về có cấu trúc rõ ràng (quota, rate limit,
/// validation...) — [message] luôn là câu tiếng Việt server đã soạn sẵn cho
/// người dùng, UI chỉ cần hiển thị thẳng, không cần tự đoán hay ghép chữ.
class AiException implements Exception {
  const AiException(this.message, {required this.code, this.retryAfter});

  final String message;
  final String code;
  final DateTime? retryAfter;

  bool get isRateLimited => code == 'AI_RATE_LIMIT_EXCEEDED';
  bool get isDailyQuotaExceeded => code == 'AI_DAILY_QUOTA_EXCEEDED';

  @override
  String toString() => message;
}

/// supabase-js/dart ném [FunctionException] (không trả response) cho MỌI
/// status khác 2xx — nghĩa là các nhánh `if (res.status != 200)` sau lệnh
/// `invoke` trước đây không bao giờ chạy tới. Phải bắt [FunctionException]
/// ngay tại chỗ gọi và "dịch" `details` (body JSON `{error, code, ...}` mà
/// các Edge Function AI trả về) thành [AiException], nếu không thông báo lỗi
/// quota/validation sẽ không bao giờ tới được UI — người dùng chỉ thấy
/// `FunctionException(status: ..., details: ...)` thô.
AiException mapAiFunctionException(FunctionException e) {
  final details = e.details;
  if (details is Map) {
    final message = details['error'];
    final code = details['code'];
    if (message is String && code is String) {
      final retryAfterRaw = details['retryAfter'];
      return AiException(
        message,
        code: code,
        retryAfter: retryAfterRaw is String ? DateTime.tryParse(retryAfterRaw) : null,
      );
    }
  }
  return const AiException('Lỗi gọi AI, vui lòng thử lại.', code: 'UNKNOWN');
}
