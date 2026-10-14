import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../core/theme/app_motion.dart';

/// Theo dõi tin nhắn "vừa được thêm" trong lượt này để chỉ chúng mới chạy
/// animation xuất hiện — CHỈ trình bày, không đọc/ghi dữ liệu hội thoại.
///
/// - [markFresh] gọi trong cùng `setState` thêm tin; cờ tự xoá sau khung hình
///   đó, nên tin nào chưa được dựng (cuộn xa) hoặc được dựng lại sau này
///   (cuộn về, mở lại hội thoại, rebuild) sẽ KHÔNG animate.
/// - [alias] giữ key ổn định khi id đổi (tin tạm `pending-…` → id thật sau khi
///   server trả về), để bubble không bị dựng lại và không chạy lại animation.
class ChatEntranceTracker {
  final Set<String> _fresh = {};
  final Map<String, String> _alias = {};

  /// Key hiển thị ổn định của tin có [id].
  String keyOf(String id) => _alias[id] ?? id;

  bool isFresh(String key) => _fresh.contains(key);

  /// Ghi nhận tin có id thật [id] chính là bubble đang hiển thị bằng [key].
  void alias(String id, String key) {
    if (id != key) _alias[id] = key;
  }

  void markFresh(Iterable<String> keys) {
    final added = keys.toList();
    _fresh.addAll(added);
    SchedulerBinding.instance
      ..addPostFrameCallback((_) => _fresh.removeAll(added))
      ..ensureVisualUpdate();
  }
}

/// Bubble mới vào bằng fade + trượt ngắn từ phía người gửi. Việc có chạy hay
/// không được chốt MỘT LẦN lúc State được tạo ([animate]); rebuild cùng key
/// không chạy lại. Cấu trúc widget luôn cố định để khi cờ đổi bubble không bị
/// dựng lại. Giảm chuyển động: hiện ngay.
class MessageEntrance extends StatefulWidget {
  const MessageEntrance({
    super.key,
    required this.animate,
    required this.fromRight,
    required this.child,
  });

  final bool animate;
  final bool fromRight;
  final Widget child;

  @override
  State<MessageEntrance> createState() => _MessageEntranceState();
}

class _MessageEntranceState extends State<MessageEntrance> {
  late final bool _play = widget.animate;

  @override
  Widget build(BuildContext context) {
    final play = _play && !AppMotion.reduced(context);
    final dir = widget.fromRight ? 1.0 : -1.0;
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: play ? 0 : 1, end: 1),
      duration: play ? AppMotion.standard : Duration.zero,
      curve: AppMotion.curveEnter,
      child: widget.child,
      builder: (context, t, child) => Opacity(
        opacity: t,
        child: FractionalTranslation(
          translation: Offset(dir * 0.04 * (1 - t), 0.12 * (1 - t)),
          child: child,
        ),
      ),
    );
  }
}

/// Ba chấm "đang soạn" — chỉ là hình ảnh; widget được dựng khi và chỉ khi
/// trạng thái chờ thật đang bật (do màn hình quyết định), gỡ ra là ticker dừng
/// hẳn. Giảm chuyển động: ba chấm tĩnh, không chuyển động lặp.
class TypingDots extends StatefulWidget {
  const TypingDots({super.key, required this.color});

  final Color color;

  @override
  State<TypingDots> createState() => _TypingDotsState();
}

class _TypingDotsState extends State<TypingDots>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (AppMotion.reduced(context)) {
      _controller.stop();
      _controller.value = 0;
    } else if (!_controller.isAnimating) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduced = AppMotion.reduced(context);
    return Semantics(
      label: 'Đang trả lời',
      child: ExcludeSemantics(
        child: SizedBox(
          height: 14,
          child: reduced
              ? _dots((_) => (0.6, 0))
              : AnimatedBuilder(
                  animation: _controller,
                  builder: (context, _) {
                    return _dots((i) {
                      final p = (_controller.value - i * 0.2) % 1.0;
                      final w = p < 0.5 ? math.sin(p / 0.5 * math.pi) : 0.0;
                      return (0.35 + 0.65 * w, -3 * w);
                    });
                  },
                ),
        ),
      ),
    );
  }

  /// [spec] trả về (độ đậm, độ nhấc lên) của chấm thứ i.
  Widget _dots((double, double) Function(int i) spec) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        for (var i = 0; i < 3; i++) ...[
          if (i > 0) const SizedBox(width: 5),
          Builder(
            builder: (_) {
              final (opacity, dy) = spec(i);
              return Transform.translate(
                offset: Offset(0, dy),
                child: Container(
                  key: ValueKey('typing-dot-$i'),
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: widget.color.withValues(alpha: opacity),
                  ),
                ),
              );
            },
          ),
        ],
      ],
    );
  }
}
