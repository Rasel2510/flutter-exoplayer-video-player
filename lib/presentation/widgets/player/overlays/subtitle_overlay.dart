import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_video_player/presentation/providers/player_provider.dart';
import 'package:flutter_video_player/presentation/providers/subtitle_style_provider.dart';

/// Renders the active subtitle cue (forwarded from native ExoPlayer) as styled
/// Flutter text, using the same appearance settings as the media_kit build.
/// Rendering subtitles in Flutter (rather than a native view) keeps full control
/// over font size / colour / background.
class SubtitleOverlay extends ConsumerStatefulWidget {
  const SubtitleOverlay({super.key});

  @override
  ConsumerState<SubtitleOverlay> createState() => _SubtitleOverlayState();
}

class _SubtitleOverlayState extends ConsumerState<SubtitleOverlay> {
  Offset? _dragOffset;
  bool _isDragging = false;

  @override
  Widget build(BuildContext context) {
    final (:cue, :enabled) = ref.watch(playerProvider.select((s) => (
          cue: s.currentCue,
          enabled: s.subtitlesEnabled,
        )));
    if (!enabled || cue.isEmpty) return const SizedBox.shrink();
    final style = ref.watch(subtitleStyleProvider);
    final position = _isDragging ? _dragOffset : style.position;

    return Positioned(
      left: 16,
      right: 16,
      bottom: 48,
      child: AnimatedContainer(
        duration: _isDragging ? Duration.zero : const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        transform: Matrix4.translationValues(position?.dx ?? 0, position?.dy ?? 0, 0),
        child: Center(
          child: GestureDetector(
            onPanStart: (details) {
              setState(() {
                _isDragging = true;
                _dragOffset = style.position ?? Offset.zero;
              });
            },
            onPanUpdate: (details) {
              final mq = MediaQuery.of(context).size;
              setState(() {
                var newPos = (_dragOffset ?? Offset.zero) + details.delta;
                _dragOffset = Offset(
                  newPos.dx.clamp(-mq.width * 0.8, mq.width * 0.8),
                  newPos.dy.clamp(-mq.height * 0.8, mq.height * 0.8),
                );
              });
            },
            onPanEnd: (details) {
              setState(() => _isDragging = false);
              if (_dragOffset != null) {
                ref.read(subtitleStyleProvider.notifier).setPosition(_dragOffset!);
              }
            },
            onPanCancel: () {
              setState(() => _isDragging = false);
            },
            child: Container(
            padding: style.background
                ? const EdgeInsets.symmetric(horizontal: 10, vertical: 4)
                : EdgeInsets.zero,
            decoration: style.background
                ? BoxDecoration(
                    color: style.backgroundColor,
                    borderRadius: BorderRadius.circular(6),
                  )
                : null,
            child: Text(
              cue,
              textAlign: TextAlign.center,
              style: TextStyle(
                height: 1.3,
                fontSize: style.fontSize,
                color: style.color,
                fontFamily: style.fontFamily,
                fontWeight: FontWeight.bold,
                shadows: style.background
                    ? null
                    : const [
                        Shadow(blurRadius: 4, color: Colors.black),
                        Shadow(blurRadius: 8, color: Colors.black),
                      ],
              ),
            ),
            ),
          ),
        ),
      ),
    );
  }
}
