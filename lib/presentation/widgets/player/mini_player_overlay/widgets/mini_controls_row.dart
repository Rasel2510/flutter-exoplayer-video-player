import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_video_player/presentation/providers/player_provider.dart';
import 'yt_mini_button.dart';

/// Isolated [ConsumerWidget] for the skip-back / play-pause / skip-forward row.
/// Watches only [PlayerState.intendsToPlay] so the full overlay tree does NOT
/// rebuild on every play/pause toggle — only this row does.
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final intendsToPlay = ref.watch(
      playerProvider.select((s) => s.intendsToPlay),
    );

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Skip back
        YtMiniButton(
          icon: replayIcon,
          size: 22 * iconScale,
          onTap: () {
            ref
                .read(playerProvider.notifier)
                .seekRelative(-seekInterval, revealControls: false);
            onShowControls();
          },
        ),
        const SizedBox(width: 4),
        // Play / Pause
        YtMiniButton(
          icon: intendsToPlay
              ? Icons.pause_rounded
              : Icons.play_arrow_rounded,
          size: 32 * iconScale,
          onTap: () {
            ref.read(playerProvider.notifier).togglePlay();
            onShowControls();
          },
        ),
        const SizedBox(width: 4),
        // Skip forward
        YtMiniButton(
          icon: forwardIcon,
          size: 22 * iconScale,
          onTap: () {
            ref
                .read(playerProvider.notifier)
                .seekRelative(seekInterval, revealControls: false);
            onShowControls();
          },
        ),
      ],
    );
  }
}
