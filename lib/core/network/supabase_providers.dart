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

/// User hiện tại (null nếu chưa đăng nhập). Lấy thẳng từ session của sự kiện
/// [authStateProvider] mới nhất (không tra riêng `auth.currentUser`) — SDK
/// cập nhật field `currentUser` nội bộ có thể chậm hơn 1 nhịp so với lúc
/// stream `onAuthStateChange` phát sự kiện, khiến router đọc "vẫn đăng nhập"
/// ngay sau khi đăng xuất và không redirect kịp về /login.
final currentUserProvider = Provider<User?>((ref) {
  final authState = ref.watch(authStateProvider).valueOrNull;
  if (authState != null) return authState.session?.user;
  return ref.watch(supabaseProvider).auth.currentUser;
});
