part of '../player_controls_overlay.dart';

class _CenterControls extends ConsumerWidget {
  final VoidCallback onTogglePlay;
  final VoidCallback onPlayPrevious;
  final VoidCallback onPlayNext;
  final VoidCallback onSeekBack;
  final VoidCallback onSeekForward;

  const _CenterControls({
    required this.onTogglePlay,
    required this.onPlayPrevious,
    required this.onPlayNext,
    required this.onSeekBack,
    required this.onSeekForward,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Single combined select for all three booleans + seekInterval.
    // The play/pause icon follows playback INTENT, not raw isPlaying, so it
    // doesn't flicker to "play" during the brief re-buffer of a seek.
    final (:isPlaying, :hasPrevious, :hasNext, :seekInterval) =
        ref.watch(playerProvider.select((s) => (
              isPlaying: s.intendsToPlay,
              hasPrevious: s.hasPrevious,
              hasNext: s.hasNext,
              seekInterval: s.seekInterval,
            )));
    final hasSiblings = hasPrevious || hasNext;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (hasSiblings) ...[
          _TrackButton(
            icon: Icons.skip_previous_rounded,
            enabled: hasPrevious,
            onTap: onPlayPrevious,
          ),
          const SizedBox(width: 12),
        ],
        _SeekPill(seconds: -seekInterval, onTap: onSeekBack),
        const SizedBox(width: 16),
        _PlayButton(isPlaying: isPlaying, onTap: onTogglePlay),
        const SizedBox(width: 16),
        _SeekPill(seconds: seekInterval, onTap: onSeekForward),
        if (hasSiblings) ...[
          const SizedBox(width: 12),
          _TrackButton(
            icon: Icons.skip_next_rounded,
            enabled: hasNext,
            onTap: onPlayNext,
          ),
        ],
      ],
    );
  }
}


