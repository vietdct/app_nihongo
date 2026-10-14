import 'package:flutter/material.dart';

import '../core/services/dialogue_player.dart';
import '../core/services/jp_voice_prefs.dart';
import '../core/theme/app_motion.dart';
import '../core/theme/app_theme.dart';
import '../domain/entities/listening_dialogue.dart';
import 'motion/playing_indicator.dart';
import 'motion/press_scale.dart';

/// Màu theo thứ tự nhân vật (tối đa 4 màu rồi xoay vòng) — nhìn script là biết
/// ai đang nói mà không dùng quá nhiều màu.
({Color color, Color soft}) speakerStyle(int slot) => const [
      (color: AppColors.accentStrong, soft: AppColors.accentSoft),
      (color: AppColors.indigo, soft: AppColors.indigoSoft),
      (color: AppColors.teal, soft: AppColors.tealSoft),
      (color: AppColors.plum, soft: AppColors.plumSoft),
    ][slot % 4];

/// Khung nghe hội thoại dùng chung (bài học + Nghe hiểu): nút phát/tạm dừng
/// cả đoạn, mỗi nhân vật 1 màu, script bị che bằng dấu ＊ — cuối mỗi lượt thoại
/// có nút mắt để hiện đúng lượt đó khi cần. [revealAll] = true (vd. sau khi
/// trả lời) hiện toàn bộ script.
class DialogueListeningPanel extends StatefulWidget {
  const DialogueListeningPanel({
    super.key,
    required this.turns,
    required this.player,
    this.revealAll = false,
  });

  final List<ListeningTurn> turns;
  final DialoguePlayer player;
  final bool revealAll;

  @override
  State<DialogueListeningPanel> createState() => _DialogueListeningPanelState();
}

class _DialogueListeningPanelState extends State<DialogueListeningPanel> {
  final Set<int> _shown = {};

  @override
  void didUpdateWidget(covariant DialogueListeningPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.turns, widget.turns)) _shown.clear();
  }

  bool get _allShown =>
      widget.revealAll || _shown.length == widget.turns.length;

  void _toggleAll() => setState(() {
        if (_allShown) {
          _shown.clear();
        } else {
          _shown.addAll(List.generate(widget.turns.length, (i) => i));
        }
      });

  void _toggleTurn(int i) => setState(() {
        if (!_shown.add(i)) _shown.remove(i);
      });

  void _onMainTap(DialoguePlayState s) {
    switch (s) {
      case DialoguePlayState.idle:
        widget.player.play(widget.turns);
      case DialoguePlayState.playing:
        widget.player.pause();
      case DialoguePlayState.paused:
        widget.player.resume();
    }
  }

  @override
  Widget build(BuildContext context) {
    final turns = widget.turns;
    final speakers = turns.speakerOrder;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ValueListenableBuilder<DialoguePlayState>(
          valueListenable: widget.player.state,
          builder: (context, state, _) {
            final label = switch (state) {
              DialoguePlayState.idle => 'Chạm để nghe hội thoại',
              DialoguePlayState.playing => 'Đang phát · chạm để tạm dừng',
              DialoguePlayState.paused => 'Đã tạm dừng · chạm để nghe tiếp',
            };
            return Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (state != DialoguePlayState.idle)
                      const SizedBox(width: 48),
                    PlayingRing(
                      active: state == DialoguePlayState.playing,
                      color: AppColors.accent,
                      child: PressScale(
                        child: InkWell(
                          borderRadius: BorderRadius.circular(100),
                          onTap: () => _onMainTap(state),
                          child: Container(
                            width: 68,
                            height: 68,
                            decoration: const BoxDecoration(
                              color: AppColors.accentSoft,
                              shape: BoxShape.circle,
                            ),
                            alignment: Alignment.center,
                            child: SwapIcon(
                              icon: state == DialoguePlayState.playing
                                  ? Icons.pause_rounded
                                  : Icons.play_arrow_rounded,
                              size: 38,
                              color: AppColors.accentStrong,
                            ),
                          ),
                        ),
                      ),
                    ),
                    if (state != DialoguePlayState.idle)
                      SizedBox(
                        width: 48,
                        child: IconButton(
                          tooltip: 'Nghe lại từ đầu',
                          onPressed: () => widget.player.play(turns),
                          icon: const Icon(Icons.replay_rounded, size: 22),
                          color: AppColors.inkSoft,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.inkSoft,
                  ),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 14),
        ValueListenableBuilder<int?>(
          valueListenable: widget.player.currentTurn,
          builder: (context, current, _) {
            return Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border, width: 0.8),
              ),
              child: Column(
                children: [
                  for (var i = 0; i < turns.length; i++) ...[
                    if (i > 0) const SizedBox(height: 8),
                    _TurnRow(
                      turn: turns[i],
                      slot: speakers.indexOf(turns[i].speaker),
                      showAvatar: speakers.length > 1,
                      revealed: widget.revealAll || _shown.contains(i),
                      speaking: current == i,
                      onPlay: () => widget.player.play(
                        turns,
                        from: i,
                        single: true,
                      ),
                      onToggle: widget.revealAll ? null : () => _toggleTurn(i),
                    ),
                  ],
                ],
              ),
            );
          },
        ),
        if (!widget.revealAll && turns.length > 1)
          Center(
            child: TextButton.icon(
              onPressed: _toggleAll,
              icon: Icon(
                _allShown
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                size: 18,
              ),
              label:
                  Text(_allShown ? 'Ẩn tất cả script' : 'Hiện tất cả script'),
            ),
          ),
      ],
    );
  }
}

class _TurnRow extends StatelessWidget {
  const _TurnRow({
    required this.turn,
    required this.slot,
    required this.showAvatar,
    required this.revealed,
    required this.speaking,
    required this.onPlay,
    required this.onToggle,
  });

  final ListeningTurn turn;
  final int slot;
  final bool showAvatar;
  final bool revealed;
  final bool speaking;
  final VoidCallback onPlay;
  final VoidCallback? onToggle;

  @override
  Widget build(BuildContext context) {
    final (:color, :soft) = speakerStyle(slot);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (showAvatar) ...[
          _SpeakerAvatar(
            speaker: turn.speaker,
            slot: slot,
            radius: 14,
            speaking: speaking,
          ),
          const SizedBox(width: 8),
        ],
        Expanded(
          child: AnimatedContainer(
            duration: AppMotion.resolve(context, AppMotion.standard),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: speaking ? soft : AppColors.canvas,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: speaking ? color : Colors.transparent,
                width: 1.2,
              ),
            ),
            child: Text(
              revealed ? turn.jp : '＊ ＊ ＊ ＊ ＊',
              style: AppFonts.zenMaruGothic(
                fontSize: 15,
                color: revealed ? AppColors.ink : AppColors.inkFaint,
              ),
            ),
          ),
        ),
        IconButton(
          tooltip: 'Nghe lượt này',
          visualDensity: VisualDensity.compact,
          onPressed: onPlay,
          icon: Icon(Icons.volume_up_rounded, size: 20, color: color),
        ),
        IconButton(
          tooltip: revealed ? 'Ẩn script' : 'Hiện script',
          visualDensity: VisualDensity.compact,
          onPressed: onToggle,
          icon: Icon(
            revealed
                ? Icons.visibility_off_outlined
                : Icons.visibility_outlined,
            size: 20,
            color: AppColors.inkSoft,
          ),
        ),
      ],
    );
  }
}

/// Nút nghe gọn cho 1 đoạn hội thoại: phát/tạm dừng + trạng thái + chọn tốc độ
/// (0.75×/1.0×/1.25×). Không hiện chữ của script.
class DialogueAudioControls extends StatelessWidget {
  const DialogueAudioControls({
    super.key,
    required this.turns,
    required this.player,
  });

  final List<ListeningTurn> turns;
  final DialoguePlayer player;

  static const _speeds = [
    AudioPlaybackSpeed.x075,
    AudioPlaybackSpeed.x100,
    AudioPlaybackSpeed.x125,
  ];

  void _onMainTap(DialoguePlayState s) {
    switch (s) {
      case DialoguePlayState.idle:
        player.play(turns);
      case DialoguePlayState.playing:
        player.pause();
      case DialoguePlayState.paused:
        player.resume();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ValueListenableBuilder<DialoguePlayState>(
          valueListenable: player.state,
          builder: (context, state, _) {
            return ValueListenableBuilder<int?>(
              valueListenable: player.currentTurn,
              builder: (context, turn, _) {
                // Nhiều người nói: "Đang phát · A · 2/4"; 1 người: chỉ tiến độ.
                final who = turn != null &&
                        turn < turns.length &&
                        turns.hasMultipleSpeakers
                    ? ' · ${turns[turn].speaker}'
                    : '';
                final label = switch (state) {
                  DialoguePlayState.idle => 'Chạm để nghe',
                  DialoguePlayState.playing =>
                    'Đang phát$who${turn == null ? '' : ' · ${turn + 1}/${turns.length}'}',
                  DialoguePlayState.paused => 'Đã tạm dừng · chạm để nghe tiếp',
                };
                final playing = state == DialoguePlayState.playing;
                return Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (state != DialoguePlayState.idle)
                          const SizedBox(width: 44),
                        PlayingRing(
                          active: playing,
                          color: AppColors.accent,
                          child: PressScale(
                            child: InkWell(
                              borderRadius: BorderRadius.circular(100),
                              onTap: () => _onMainTap(state),
                              child: Container(
                                width: 56,
                                height: 56,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      AppColors.accent,
                                      Color(0xFFFFB020)
                                    ],
                                  ),
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.accent
                                          .withValues(alpha: 0.3),
                                      blurRadius: 12,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                alignment: Alignment.center,
                                child: SwapIcon(
                                  icon: playing
                                      ? Icons.pause_rounded
                                      : Icons.play_arrow_rounded,
                                  size: 30,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                        if (state != DialoguePlayState.idle)
                          SizedBox(
                            width: 44,
                            child: IconButton(
                              tooltip: 'Nghe lại từ đầu',
                              onPressed: () => player.play(turns),
                              icon: const Icon(Icons.replay_rounded, size: 20),
                              color: AppColors.inkSoft,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      label,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.inkSoft,
                      ),
                    ),
                  ],
                );
              },
            );
          },
        ),
        ValueListenableBuilder<AudioPlaybackSpeed>(
          valueListenable: player.speed,
          builder: (context, current, _) {
            return Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (final s in _speeds) ...[
                  if (s != _speeds.first) const SizedBox(width: 8),
                  ChoiceChip(
                    label: Text(s.label),
                    selected: s == current,
                    onSelected: (_) => player.setSpeed(s),
                    visualDensity: VisualDensity.compact,
                    showCheckmark: false,
                    labelStyle: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: s == current
                          ? AppColors.accentStrong
                          : AppColors.inkSoft,
                    ),
                    selectedColor: AppColors.accentSoft,
                    backgroundColor: AppColors.card,
                    side: BorderSide(
                      color: s == current ? AppColors.accent : AppColors.border,
                    ),
                  ),
                ],
              ],
            );
          },
        ),
      ],
    );
  }
}

/// Thẻ Script đầy đủ của đoạn hội thoại — CHỈ được dựng khi người học đã trả
/// lời và chủ động bấm xem (xem `ListeningPhase.reviewing`), không bao giờ
/// nằm trong widget tree ở lúc đang nghe.
class DialogueScriptCard extends StatelessWidget {
  const DialogueScriptCard({
    super.key,
    required this.turns,
    required this.player,
  });

  final List<ListeningTurn> turns;
  final DialoguePlayer player;

  @override
  Widget build(BuildContext context) {
    final speakers = turns.speakerOrder;
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(
                Icons.headphones_rounded,
                size: 18,
                color: AppColors.inkSoft,
              ),
              const SizedBox(width: 6),
              const Text(
                'Script',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: AppColors.inkSoft,
                ),
              ),
              const Spacer(),
              ValueListenableBuilder<DialoguePlayState>(
                valueListenable: player.state,
                builder: (context, state, _) {
                  final playing = state == DialoguePlayState.playing;
                  return TextButton.icon(
                    onPressed: () =>
                        playing ? player.pause() : player.play(turns),
                    icon: Icon(
                      playing ? Icons.pause_rounded : Icons.volume_up_rounded,
                      size: 18,
                    ),
                    label: Text(playing ? 'Tạm dừng' : 'Nghe lại'),
                  );
                },
              ),
            ],
          ),
          const Divider(height: 8, color: AppColors.border),
          const SizedBox(height: 6),
          ValueListenableBuilder<int?>(
            valueListenable: player.currentTurn,
            builder: (context, current, _) {
              return Column(
                children: [
                  for (var i = 0; i < turns.length; i++) ...[
                    if (i > 0) const SizedBox(height: 8),
                    _ScriptLine(
                      turn: turns[i],
                      slot: speakers.indexOf(turns[i].speaker),
                      showAvatar: speakers.length > 1,
                      speaking: current == i,
                      onPlay: () => player.play(turns, from: i, single: true),
                    ),
                  ],
                ],
              );
            },
          ),
          const SizedBox(height: 6),
        ],
      ),
    );
  }
}

class _ScriptLine extends StatelessWidget {
  const _ScriptLine({
    required this.turn,
    required this.slot,
    required this.showAvatar,
    required this.speaking,
    required this.onPlay,
  });

  final ListeningTurn turn;
  final int slot;
  final bool showAvatar;
  final bool speaking;
  final VoidCallback onPlay;

  @override
  Widget build(BuildContext context) {
    final (:color, :soft) = speakerStyle(slot);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showAvatar) ...[
          _SpeakerAvatar(
            speaker: turn.speaker,
            slot: slot,
            radius: 13,
            speaking: speaking,
          ),
          const SizedBox(width: 10),
        ],
        Expanded(
          child: AnimatedContainer(
            duration: AppMotion.resolve(context, AppMotion.standard),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: speaking ? soft : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              turn.jp,
              style: AppFonts.zenMaruGothic(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: AppColors.ink,
              ).copyWith(height: 1.55),
            ),
          ),
        ),
        IconButton(
          tooltip: 'Nghe lượt này',
          visualDensity: VisualDensity.compact,
          onPressed: onPlay,
          icon: Icon(Icons.volume_up_rounded, size: 20, color: color),
        ),
      ],
    );
  }
}

class _SpeakerAvatar extends StatelessWidget {
  const _SpeakerAvatar({
    required this.speaker,
    required this.slot,
    required this.radius,
    this.speaking = false,
  });

  final String speaker;
  final int slot;
  final double radius;

  /// Nhân vật này đang nói (theo `currentSpeaker`/`currentTurn` thật của
  /// player): phóng nhẹ + viền màu nhân vật, không đổi kích thước bố cục.
  final bool speaking;

  @override
  Widget build(BuildContext context) {
    final (:color, :soft) = speakerStyle(slot);
    final duration = AppMotion.resolve(context, AppMotion.standard);
    return AnimatedScale(
      scale: speaking ? 1.12 : 1,
      duration: duration,
      curve: AppMotion.curveSmooth,
      child: AnimatedContainer(
        duration: duration,
        width: radius * 2,
        height: radius * 2,
        foregroundDecoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: speaking ? color : Colors.transparent,
            width: 2,
          ),
        ),
        child: CircleAvatar(
          radius: radius,
          backgroundColor: soft,
          child: Text(
            speaker.characters.isEmpty ? '' : speaker.characters.first,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ),
      ),
    );
  }
}
