import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/network/ai_exception.dart';
import '../../core/network/supabase_providers.dart';

/// Điều phối các hành động xác thực. State là AsyncValue<void>:
/// - loading khi đang gọi mạng
/// - error khi thất bại (UI lắng nghe để hiện SnackBar)
/// Việc chuyển màn sau đăng nhập do go_router redirect lo, không xử lý ở đây.
final authControllerProvider = AsyncNotifierProvider<AuthController, void>(
  AuthController.new,
);

class AuthController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  SupabaseClient get _sb => ref.read(supabaseProvider);

  /// Đăng nhập bằng email HOẶC tên đăng nhập — Supabase Auth chỉ nhận
  /// email/phone, nên nếu [identifier] không chứa '@' thì gọi Edge Function
  /// `auth-login-username` (tra email + xác thực mật khẩu ở server bằng
  /// service role key) thay vì tự tra email qua RPC ở client — tránh lộ
  /// email ứng với 1 username cho người chưa đăng nhập (xem migration
  /// Pha 3b `username_login_email_leak_fix`).
  Future<void> signInWithIdentifier(String identifier, String password) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final trimmed = identifier.trim();
      if (trimmed.contains('@')) {
        await _sb.auth.signInWithPassword(email: trimmed, password: password);
        return;
      }

      final FunctionResponse res;
      try {
        res = await _sb.functions.invoke(
          'auth-login-username',
          body: {'username': trimmed, 'password': password},
        );
      } on FunctionException catch (e) {
        throw mapAiFunctionException(e);
      }

      final data = res.data;
      final refreshToken = data is Map ? data['refreshToken'] : null;
      if (refreshToken is! String) {
        throw const AiException('Đăng nhập thất bại, vui lòng thử lại.', code: 'UNKNOWN');
      }
      await _sb.auth.setSession(refreshToken);
    });
  }

  Future<void> signUpWithEmail(
    String email,
    String password,
    String displayName,
    String username,
  ) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await _sb.auth.signUp(
        email: email,
        password: password,
        data: {'name': displayName, 'username': username},
      );
    });
  }

  /// Yêu cầu cấu hình Google provider trong Supabase dashboard + OAuth client
  /// trong Google Cloud trước khi dùng (xem README, Pha 1).
  Future<void> signInWithGoogle() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await _sb.auth.signInWithOAuth(OAuthProvider.google);
    });
  }

  Future<void> signOut() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await _sb.auth.signOut();
    });
  }
}
