import 'package:flutter/material.dart';

import '../../core/theme/app_motion.dart';

/// Hiệu ứng vào so le (fade + trượt lên rất ngắn) cho các mục đầu của một
/// danh sách/màn hình. Dùng cặp [StaggerGroup] (chủ vòng đời) + [StaggerItem].
///
/// Vòng đời: [StaggerGroup] chạy ĐÚNG MỘT LẦN khi nó được tạo trong cây widget
/// (đó là lúc danh sách/màn hình được mở hoặc dataset mới xuất hiện — đặt group
/// bên trong nhánh `data` của `AsyncValue.when` hoặc gắn `key` theo dataset).
/// Rebuild, cuộn, gõ tìm kiếm/lọc, chuyển tab (IndexedStack giữ nguyên State),
/// quay lại từ màn chi tiết đều KHÔNG chạy lại vì group không bị tạo mới.
///
/// Hiệu năng: chỉ MỘT AnimationController cho cả nhóm (không controller/timer
/// riêng cho từng mục); chỉ [maxItems] mục đầu được animate, các mục còn lại
/// là widget thường, hiện ngay.
class StaggerGroup extends StatefulWidget {
  const StaggerGroup({
    super.key,
    required this.child,
    this.active = true,
    this.maxItems = 8,
    this.delay = const Duration(milliseconds: 40),
    this.itemDuration = const Duration(milliseconds: 240),
  });

  final Widget child;

  /// Khi nào group được phép bắt đầu chạy (đúng 1 lần, ở lần đầu `true`). Dùng
  /// khi group đứng BÊN NGOÀI nhánh dữ liệu để sống xuyên qua tìm kiếm/lọc/rỗng
  /// (không chạy lại), nhưng chỉ bắt đầu khi dữ liệu đầu tiên đã sẵn sàng —
  /// truyền `active: async.hasValue`. Mặc định `true` (chạy ngay khi tạo).
  /// Gắn `key` theo dataset (VD mã cấp độ) để dataset mới có lượt chạy mới.
  final bool active;

  /// Số mục tối đa được animate (mục có index >= giá trị này hiện ngay).
  final int maxItems;

  /// Độ trễ giữa hai mục liền nhau.
  final Duration delay;

  /// Thời lượng animation của mỗi mục.
  final Duration itemDuration;

  @override
  State<StaggerGroup> createState() => _StaggerGroupState();
}

class _StaggerGroupState extends State<StaggerGroup>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: _total,
  );
  bool _started = false;

  Duration get _total =>
      widget.delay * (widget.maxItems - 1) + widget.itemDuration;

  // Cần MediaQuery nên khởi động ở didChangeDependencies, đúng 1 lần cho cả
  // vòng đời group. Giảm chuyển động: về thẳng trạng thái cuối, không delay.
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _maybeStart();
  }

  @override
  void didUpdateWidget(StaggerGroup old) {
    super.didUpdateWidget(old);
    _maybeStart();
  }

  void _maybeStart() {
    if (_started || !widget.active) return;
    _started = true;
    if (AppMotion.reduced(context)) {
      _controller.value = 1;
    } else {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _StaggerScope(
      controller: _controller,
      maxItems: widget.maxItems,
      delayMs: widget.delay.inMilliseconds,
      itemMs: widget.itemDuration.inMilliseconds,
      totalMs: _total.inMilliseconds,
      child: widget.child,
    );
  }
}

class _StaggerScope extends InheritedWidget {
  const _StaggerScope({
    required this.controller,
    required this.maxItems,
    required this.delayMs,
    required this.itemMs,
    required this.totalMs,
    required super.child,
  });

  final Animation<double> controller;
  final int maxItems;
  final int delayMs;
  final int itemMs;
  final int totalMs;

  static _StaggerScope? maybeOf(BuildContext context) =>
      context.getInheritedWidgetOfExactType<_StaggerScope>();

  // Cấu hình không đổi trong vòng đời group; item tự nghe controller.
  @override
  bool updateShouldNotify(_StaggerScope old) => false;
}

/// Một mục của [StaggerGroup]. [index] là vị trí hiển thị (hoặc "ô" cố định
/// với màn có mục xuất hiện có điều kiện như Home). Ngoài group, hoặc
/// index ngoài giới hạn → chính [child], không bọc gì.
///
/// Cây widget của mục không đổi hình dạng theo thời gian (luôn bọc sau lần
/// build đầu), nên rebuild/lọc/cuộn không dựng lại [child]; sau khi animation
/// xong mục ở trạng thái cuối (opacity 1, không dịch) nên hiện ngay.
class StaggerItem extends StatelessWidget {
  const StaggerItem({
    super.key,
    required this.index,
    required this.child,
    this.offset = const Offset(0, 0.04),
  });

  final int index;
  final Widget child;

  /// Độ lệch ban đầu theo tỉ lệ kích thước của [child] (0.04 ≈ 4% chiều cao).
  final Offset offset;

  @override
  Widget build(BuildContext context) {
    final scope = _StaggerScope.maybeOf(context);
    if (scope == null || index < 0 || index >= scope.maxItems) return child;

    final start = index * scope.delayMs / scope.totalMs;
    final end = (index * scope.delayMs + scope.itemMs) / scope.totalMs;
    final interval = Interval(start, end, curve: Curves.easeOutCubic);

    return AnimatedBuilder(
      animation: scope.controller,
      child: child,
      builder: (context, child) {
        final t = interval.transform(scope.controller.value);
        return Opacity(
          opacity: t,
          child: FractionalTranslation(
            translation: Offset(offset.dx * (1 - t), offset.dy * (1 - t)),
            child: child,
          ),
        );
      },
    );
  }
}
