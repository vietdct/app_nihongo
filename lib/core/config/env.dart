/// Cấu hình môi trường, nạp qua `--dart-define-from-file=env.json` khi chạy/build.
///
/// KHÔNG hard-code key vào đây và KHÔNG commit file env.json thật (đã đưa vào .gitignore).
/// Xem env.example.json để biết định dạng.
abstract final class Env {
  static const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

  /// Chặn chạy app khi quên truyền env, cho lỗi rõ ràng thay vì crash mơ hồ.
  static void assertConfigured() {
    assert(
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty,
      'Thiếu SUPABASE_URL / SUPABASE_ANON_KEY. '
      'Chạy: flutter run --dart-define-from-file=env.json',
    );
  }
}
