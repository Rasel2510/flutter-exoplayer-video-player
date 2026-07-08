import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_video_player/presentation/providers/player_provider.dart';
import 'package:flutter_video_player/core/theme/app_theme.dart';

/// A thin accent-coloured progress bar at the bottom of the mini player.
/// Rendered as a plain [StatelessWidget] when the progress value is known.
class MiniProgressBar extends StatelessWidget {
  final double progress;
  const MiniProgressBar({super.key, required this.progress});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 3,
      child: LinearProgressIndicator(
        value: progress.clamp(0.0, 1.0),
        backgroundColor: Colors.white24,
        valueColor: AlwaysStoppedAnimation<Color>(context.colors.accent),
        minHeight: 3,
      ),
    );
  }
}

/// Isolated [ConsumerWidget] wrapper — watches only [PlayerState.progress] so
/// only this tiny bar rebuilds every second as the position stream ticks.
/// The parent overlay (layout + gesture tree) stays completely inert.
class MiniProgressBarConsumer extends ConsumerWidget {
  const MiniProgressBarConsumer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progress = ref.watch(
      playerProvider.select((s) => s.progress),
    );
    return MiniProgressBar(progress: progress);
  }
}
