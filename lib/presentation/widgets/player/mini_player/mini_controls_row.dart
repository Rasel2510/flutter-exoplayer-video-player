import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_video_player/presentation/providers/player_provider.dart';
import 'yt_mini_button.dart';

/// Isolated [ConsumerWidget] for the mini player's center control row.
/// Watches only the handful of [PlayerState] fields it needs so the full
/// overlay tree does NOT rebuild on every play/pause toggle — only this row
/// does. Normally shows skip-back / play-pause / skip-forward; once the video
/// has played to its end ([PlayerState.hasEnded]), swaps to
/// previous-video / replay / next-video instead (previous/next disabled when
/// there's no adjacent video in the playlist).
class MiniControlsRow extends ConsumerWidget {
  final int seekInterval;
  final IconData replayIcon;
  final IconData forwardIcon;
  final double iconScale;
  final VoidCallback onShowControls;

  const MiniControlsRow({
    super.key,
    required this.seekInterval,
    required this.replayIcon,
    required this.forwardIcon,
    required this.iconScale,
    required this.onShowControls,
  });

  Widget _buildSeekButtonContent({
    required bool isForward,
    required IconData fallbackIcon,
    required double size,
  }) {
    if (seekInterval == 15) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isForward ? Icons.fast_forward_rounded : Icons.fast_rewind_rounded,
            size: size * 0.8,
            color: Colors.white,
          ),
          const Text(
            '15',
            style: TextStyle(
              color: Colors.white,
              fontSize: 9,
              fontWeight: FontWeight.bold,
              height: 1,
            ),
          ),
        ],
      );
    }

    return Icon(fallbackIcon, size: size, color: Colors.white);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final (:intendsToPlay, :hasEnded, :hasPrevious, :hasNext) = ref.watch(
      playerProvider.select((s) => (
            intendsToPlay: s.intendsToPlay,
            hasEnded: s.hasEnded,
            hasPrevious: s.hasPrevious,
            hasNext: s.hasNext,
          )),
    );

    if (hasEnded) {
      final notifier = ref.read(playerProvider.notifier);
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Previous video — dimmed (but still tappable-looking) when there
          // isn't one; disabled via a null onTap.
          Opacity(
            opacity: hasPrevious ? 1.0 : 0.4,
            child: YtMiniButton(
              icon: Icons.skip_previous_rounded,
              size: 26 * iconScale,
              onTap: hasPrevious
                  ? () {
                      notifier.playPrevious();
                      onShowControls();
                    }
                  : () {},
            ),
          ),
          const SizedBox(width: 4),
          // Replay
          YtMiniButton(
            icon: Icons.replay_rounded,
            size: 32 * iconScale,
            onTap: () {
              notifier.replay();
              onShowControls();
            },
          ),
          const SizedBox(width: 4),
          // Next video
          Opacity(
            opacity: hasNext ? 1.0 : 0.4,
            child: YtMiniButton(
              icon: Icons.skip_next_rounded,
              size: 26 * iconScale,
              onTap: hasNext
                  ? () {
                      notifier.playNext();
                      onShowControls();
                    }
                  : () {},
            ),
          ),
        ],
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Skip back
        YtMiniButton(
          size: 22 * iconScale,
          onTap: () {
            ref
                .read(playerProvider.notifier)
                .seekRelative(-seekInterval, revealControls: false);
            onShowControls();
          },
          child: _buildSeekButtonContent(
            isForward: false,
            fallbackIcon: replayIcon,
            size: 22 * iconScale,
          ),
        ),
        const SizedBox(width: 4),
        // Play / Pause
        YtMiniButton(
          icon: intendsToPlay ? Icons.pause_rounded : Icons.play_arrow_rounded,
          size: 32 * iconScale,
          onTap: () {
            ref.read(playerProvider.notifier).togglePlay();
            onShowControls();
          },
        ),
        const SizedBox(width: 4),
        // Skip forward
        YtMiniButton(
          size: 22 * iconScale,
          onTap: () {
            ref
                .read(playerProvider.notifier)
                .seekRelative(seekInterval, revealControls: false);
            onShowControls();
          },
          child: _buildSeekButtonContent(
            isForward: true,
            fallbackIcon: forwardIcon,
            size: 22 * iconScale,
          ),
        ),
      ],
    );
  }
}
