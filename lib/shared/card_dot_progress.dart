import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';

/// Progress dạng chấm tròn cuộn ngang (thay thanh bar tuyến tính) — dùng
/// chung cho mọi flashcard lật 2 mặt. Số thẻ trong 1 lượt có thể vượt quá bề
/// ngang màn hình nên cho cuộn thay vì cố định số chấm, tự cuộn tới chấm
/// hiện tại mỗi khi đổi thẻ.
class CardDotProgress extends StatefulWidget {
  const CardDotProgress({
    super.key,
    required this.total,
    required this.index,
    this.wrongIndices = const {},
  });

  final int total;
  final int index;

  /// Vị trí các thẻ đã vuốt "chưa thuộc" — hiển thị dấu X đỏ thay vì tích
  /// xanh tại đúng số thứ tự đó.
  final Set<int> wrongIndices;

  @override
  State<CardDotProgress> createState() => _CardDotProgressState();
}

class _CardDotProgressState extends State<CardDotProgress> {
  static const _dotSize = 38.0;
  static const _dotSpacing = 11.0;
  static const _dotExtent = _dotSize + _dotSpacing;
  final _controller = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToCurrent());
  }

  @override
  void didUpdateWidget(covariant CardDotProgress oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.index != widget.index) _scrollToCurrent();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _scrollToCurrent() {
    if (!_controller.hasClients) return;
    final target = (widget.index * _dotExtent) -
        (_controller.position.viewportDimension / 2) +
        (_dotExtent / 2);
    _controller.animateTo(
      target.clamp(0.0, _controller.position.maxScrollExtent),
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOut,
    );
  }

  _DotState _stateFor(int i) => i < widget.index
      ? (widget.wrongIndices.contains(i) ? _DotState.wrong : _DotState.done)
      : i == widget.index
          ? _DotState.current
          : _DotState.upcoming;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: _dotSize,
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Dãy số phải căn giữa tuyệt đối theo yêu cầu thiết kế — đúng cho
          // trường hợp phổ biến (1 lượt chỉ vài thẻ). Nếu tổng số thẻ vượt
          // bề ngang màn hình thì rơi về danh sách cuộn ngang (tự cuộn tới
          // thẻ hiện tại) để không vỡ layout với bộ thẻ dài.
          final contentWidth = widget.total * _dotExtent - _dotSpacing;
          if (contentWidth <= constraints.maxWidth) {
            return Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (var i = 0; i < widget.total; i++) ...[
                    if (i > 0) const SizedBox(width: _dotSpacing),
                    _Dot(state: _stateFor(i), number: i + 1, size: _dotSize),
                  ],
                ],
              ),
            );
          }
          return ListView.builder(
            controller: _controller,
            scrollDirection: Axis.horizontal,
            itemCount: widget.total,
            itemBuilder: (context, i) {
              return Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: _dotSpacing / 2),
                child: Center(
                  child:
                      _Dot(state: _stateFor(i), number: i + 1, size: _dotSize),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

enum _DotState { done, wrong, current, upcoming }

class _Dot extends StatelessWidget {
  const _Dot({required this.state, required this.number, required this.size});

  final _DotState state;
  final int number;
  final double size;

  @override
  Widget build(BuildContext context) {
    switch (state) {
      case _DotState.done:
        return SizedBox(
          width: size,
          height: size,
          child: DecoratedBox(
            decoration: const BoxDecoration(
              color: AppColors.moss,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.check_rounded,
              size: size * 0.44,
              color: Colors.white,
            ),
          ),
        );
      case _DotState.wrong:
        return SizedBox(
          width: size,
          height: size,
          child: DecoratedBox(
            decoration: const BoxDecoration(
              color: AppColors.danger,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.close_rounded,
              size: size * 0.5,
              color: Colors.white,
            ),
          ),
        );
      case _DotState.current:
        return Container(
          width: size,
          height: size,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.accent, AppColors.heroGradientEnd],
            ),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppColors.accent.withValues(alpha: 0.4),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Text(
            '$number',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
        );
      case _DotState.upcoming:
        return Container(
          width: size,
          height: size,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            color: AppColors.border,
            shape: BoxShape.circle,
          ),
          child: Text(
            '$number',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.inkSoft,
            ),
          ),
        );
    }
  }
}
