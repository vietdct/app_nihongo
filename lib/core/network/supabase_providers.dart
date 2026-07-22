import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Client Supabase dùng chung. Mọi tầng Data lấy client qua provider này
/// (không gọi thẳng Supabase.instance ở feature) để dễ thay thế/khoá mock khi test.
final supabaseProvider = Provider<SupabaseClient>(
  (ref) => Supabase.instance.client,
);

/// Stream trạng thái xác thực — phát ra mỗi lần đăng nhập/đăng xuất/refresh token.
final authStateProvider = StreamProvider<AuthState>(
  (ref) => ref.watch(supabaseProvider).auth.onAuthStateChange,
);

/// User hiện tại (null nếu chưa đăng nhập). Rebuild theo [authStateProvider].
final currentUserProvider = Provider<User?>((ref) {
  ref.watch(authStateProvider);
  return ref.watch(supabaseProvider).auth.currentUser;
});
