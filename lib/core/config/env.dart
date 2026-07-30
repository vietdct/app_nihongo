/// Cấu hình môi trường, nạp qua `--dart-define-from-file=env.json` khi chạy/build.
///
/// KHÔNG hard-code key vào đây và KHÔNG commit file env.json thật (đã đưa vào .gitignore).
/// Xem env.example.json để biết định dạng.
abstract final class Env {
  static const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

  /// Chặn chạy app khi quên truyền env, cho lỗi rõ ràng thay vì crash mơ hồ.
  /// Dùng `throw` thay vì `assert` vì `assert` bị Dart loại bỏ hoàn toàn ở
  /// bản release — quên `--dart-define-from-file` khi build release sẽ
  /// không báo lỗi gì, app chạy với URL rỗng rồi lỗi khó hiểu về sau.
  static void assertConfigured() {
    if (supabaseUrl.isEmpty || supabaseAnonKey.isEmpty) {
      throw StateError(
        'Thiếu SUPABASE_URL / SUPABASE_ANON_KEY. '
        'Chạy: flutter run --dart-define-from-file=env.json',
      );
    }
  }
}
