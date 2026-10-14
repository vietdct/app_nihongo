import 'dart:async';
import 'dart:io' show SocketException;

import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';

/// Thông điệp lỗi tải dữ liệu thân thiện — KHÔNG hiển thị exception/stack
/// trace. Chỉ phân biệt "mất kết nối" với lỗi chung vì đó là điều người dùng
/// có thể tự xử lý.
String loadErrorMessage(Object error) {
  final text = error.toString().toLowerCase();
  final network = error is SocketException ||
      error is TimeoutException ||
      text.contains('socketexception') ||
      text.contains('clientexception') ||
      text.contains('failed host lookup') ||
      text.contains('connection') ||
      text.contains('network') ||
      text.contains('timeout');
  return network
      ? 'Không kết nối được máy chủ. Kiểm tra mạng rồi thử lại.'
      : 'Không tải được dữ liệu. Vui lòng thử lại.';
}

/// Khung căn giữa nhưng vẫn cuộn được (luôn cho kéo) để `RefreshIndicator`
/// bọc bên ngoài hoạt động cả khi chỉ có trạng thái rỗng/lỗi.
class _CenteredScrollable extends StatelessWidget {
  const _CenteredScrollable({required this.child, this.compact = false});

  final Widget child;

  /// Dùng khi đặt TRONG một danh sách cuộn khác (chiều cao không giới hạn):
  /// chỉ căn giữa theo nội dung, không tự cuộn.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
          child: child,
        ),
      );
    }
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

/// Trạng thái RỖNG: đã tải thành công và thật sự không có mục nào (hoặc bộ
/// lọc/tìm kiếm không khớp). Không dùng cho đang tải hay bị lỗi.
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.title,
    this.message,
    this.icon = Icons.inbox_outlined,
    this.actionLabel,
    this.onAction,
    this.compact = false,
  });

  final String title;
  final String? message;
  final IconData icon;

  /// Chỉ truyền khi có hành động thật (VD "Xoá bộ lọc").
  final String? actionLabel;
  final VoidCallback? onAction;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return _CenteredScrollable(
      compact: compact,
      child: Semantics(
        container: true,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 40, color: AppColors.inkFaint),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.ink,
              ),
            ),
            if (message != null) ...[
              const SizedBox(height: 6),
              Text(
                message!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                  height: 1.4,
                  color: AppColors.inkSoft,
                ),
              ),
            ],
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 14),
              OutlinedButton(onPressed: onAction, child: Text(actionLabel!)),
            ],
          ],
        ),
      ),
    );
  }
}

/// Trạng thái LỖI TẢI (không có dữ liệu dùng được). Nút Thử lại gọi đúng
/// callback tải lại của màn hình và bị khoá tới khi callback (nếu trả
/// `Future`) hoàn tất, nên một lần bấm không sinh hai lần tải.
class ErrorState extends StatefulWidget {
  const ErrorState({
    super.key,
    required this.error,
    required this.onRetry,
    this.title = 'Không tải được nội dung',
    this.compact = false,
  });

  final Object error;
  final String title;
  final FutureOr<void> Function() onRetry;
  final bool compact;

  @override
  State<ErrorState> createState() => _ErrorStateState();
}

class _ErrorStateState extends State<ErrorState> {
  bool _retrying = false;

  Future<void> _retry() async {
    if (_retrying) return;
    setState(() => _retrying = true);
    try {
      await widget.onRetry();
    } finally {
      if (mounted) setState(() => _retrying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _CenteredScrollable(
      compact: widget.compact,
      child: Semantics(
        container: true,
        liveRegion: true,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.cloud_off_rounded,
              size: 40,
              color: AppColors.danger,
            ),
            const SizedBox(height: 12),
            Text(
              widget.title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              loadErrorMessage(widget.error),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                height: 1.4,
                color: AppColors.inkSoft,
              ),
            ),
            const SizedBox(height: 14),
            OutlinedButton.icon(
              onPressed: _retrying ? null : _retry,
              icon: _retrying
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Thử lại'),
            ),
          ],
        ),
      ),
    );
  }
}
