import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_video_player/presentation/providers/player_provider.dart';
import 'package:flutter_video_player/presentation/providers/subtitle_style_provider.dart';

/// Renders the active subtitle cue (forwarded from native ExoPlayer) as styled
/// Flutter text, using the same appearance settings as the media_kit build.
/// Rendering subtitles in Flutter (rather than a native view) keeps full control
/// over font size / colour / background.
class SubtitleOverlay extends ConsumerWidget {
  const SubtitleOverlay({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final (:cue, :enabled) = ref.watch(playerProvider.select((s) => (
          cue: s.currentCue,
          enabled: s.subtitlesEnabled,
        )));
    if (!enabled || cue.isEmpty) return const SizedBox.shrink();
    final style = ref.watch(subtitleStyleProvider);

    return Positioned(
      left: 16,
      right: 16,
      bottom: 48,
      child: IgnorePointer(
        child: Center(
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
    );
  }
}
