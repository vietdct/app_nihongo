import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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

  Future<void> signInWithEmail(String email, String password) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await _sb.auth.signInWithPassword(email: email, password: password);
    });
  }

  Future<void> signUpWithEmail(
    String email,
    String password,
    String displayName,
  ) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await _sb.auth.signUp(
        email: email,
        password: password,
        data: {'name': displayName},
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
