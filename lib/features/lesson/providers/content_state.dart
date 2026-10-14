import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/repositories/content_repository_provider.dart';
import 'content_providers.dart';
import 'level_providers.dart';

/// Gộp 3 nguồn trạng thái của một danh sách nội dung offline-first thành MỘT
/// [AsyncValue] để màn hình chỉ cần `when(loading/error/data)`:
///
/// - luồng Drift [stream] (đọc cache),
/// - [contentRefreshProvider] (đồng bộ nền từ Supabase),
/// - [jlptLevelsProvider] (tra id cấp độ, chỉ có mạng).
///
/// Quy tắc (không bao giờ ẩn dữ liệu đã có):
/// 1. Có mục để hiển thị (kể cả cache cũ) → luôn là dữ liệu, bất kể đồng bộ
///    đang chạy hay vừa lỗi.
/// 2. Chưa có mục nào: đang tra cấp độ/đồng bộ → *loading* (chưa được kết
///    luận là rỗng); cấp độ hoặc đồng bộ lỗi → *error*; đồng bộ xong thành
///    công → dữ liệu rỗng (rỗng thật).
/// 3. Lỗi đọc DB (hiếm) → lỗi đó.
AsyncValue<List<T>> resolveContentList<T>(
  WidgetRef ref,
  AsyncValue<List<T>> stream,
) {
  if (stream.hasError && !stream.isLoading) return stream;
  final items = stream.valueOrNull;
  if (items != null && items.isNotEmpty) return stream;

  final levels = ref.watch(jlptLevelsProvider);
  final sync = ref.watch(contentRefreshProvider);
  if (levels.isLoading) return AsyncValue<List<T>>.loading();
  if (levels.hasError) {
    return AsyncValue<List<T>>.error(
      levels.error!,
      levels.stackTrace ?? StackTrace.empty,
    );
  }
  if (sync.isLoading) return AsyncValue<List<T>>.loading();
  if (sync.hasError) {
    return AsyncValue<List<T>>.error(
      sync.error!,
      sync.stackTrace ?? StackTrace.empty,
    );
  }
  if (items == null) return AsyncValue<List<T>>.loading();
  return stream; // rỗng thật: đã đồng bộ thành công mà không có mục nào
}

/// "Thử lại" khi chưa có dữ liệu để hiển thị: chạy lại đúng bước đang lỗi
/// (tra cấp độ hoặc đồng bộ nền) — không tạo callback tải mới. Bỏ qua nếu bước
/// đó đang chạy, nên bấm nhiều lần không sinh nhiều request.
void retryContentSync(
  WidgetRef ref, {
  ProviderBase<AsyncValue<Object?>>? streamProvider,
}) {
  final levels = ref.read(jlptLevelsProvider);
  if (levels.hasError && !levels.isLoading) {
    ref.invalidate(jlptLevelsProvider);
    return;
  }
  final sync = ref.read(contentRefreshProvider);
  if (!sync.isLoading) ref.invalidate(contentRefreshProvider);
  if (streamProvider != null) {
    final s = ref.read(streamProvider);
    if (s.hasError && !s.isLoading) ref.invalidate(streamProvider);
  }
}

/// Làm mới thủ công (kéo để làm mới) — gọi đúng `refreshFromRemote` của
/// repository. KHÔNG invalidate [contentRefreshProvider]: invalidate làm mọi
/// provider danh sách phụ thuộc dựng lại (nháy skeleton, mất vị trí cuộn);
/// còn gọi trực tiếp thì Drift tự phát lại danh sách khi ghi xong. Lỗi mạng
/// xảy ra TRƯỚC bước ghi nên cache cũ không bị xoá.
///
/// Chống trùng: đang có lượt làm mới thủ công hoặc đồng bộ nền → dùng lại
/// request đó thay vì gửi thêm.
class ContentRefresher {
  ContentRefresher(this._ref);

  final Ref _ref;
  Future<void>? _inflight;

  Future<void> refresh() {
    final running = _inflight;
    if (running != null) return running;
    if (_ref.read(contentRefreshProvider).isLoading) {
      return _ref.read(contentRefreshProvider.future);
    }
    final target = syncTargetOf(_ref.read);
    if (target == null) return Future<void>.value();
    final request = _ref
        .read(contentRepositoryProvider)
        .refreshFromRemote(target.levelId, coreN5Only: target.coreN5Only)
        .whenComplete(() => _inflight = null);
    return _inflight = request;
  }
}

final contentRefresherProvider =
    Provider<ContentRefresher>((ref) => ContentRefresher(ref));

/// `onRefresh` cho `RefreshIndicator` của danh sách nội dung: chờ tới khi làm
/// mới xong; thất bại thì giữ nguyên danh sách cũ và báo bằng SnackBar.
Future<void> pullToRefreshContent(BuildContext context, WidgetRef ref) async {
  final messenger = ScaffoldMessenger.maybeOf(context);
  try {
    await ref.read(contentRefresherProvider).refresh();
  } catch (_) {
    messenger
      ?..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text(
            'Không làm mới được. Nội dung đang hiển thị được giữ nguyên.',
          ),
        ),
      );
  }
}
