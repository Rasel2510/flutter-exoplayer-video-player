part of 'player_controls_overlay.dart';

class _PlaybackProgressControls extends ConsumerWidget {
  final void Function(double) onSeekStart;
  final void Function(double) onSeekUpdate;
  final void Function(double) onSeekEnd;

  const _PlaybackProgressControls({
    required this.onSeekStart,
    required this.onSeekUpdate,
    required this.onSeekEnd,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final (:position, :duration, :progress) =
        ref.watch(playerProvider.select((s) => (
              position: s.position,
              duration: s.duration,
              progress: s.progress,
            )));

    // One inline row — elapsed · slider · remaining — instead of the slider
    // stacked over a second times row: tighter, and the times sit right
    // where the thumb travel starts/ends (MX Player style).
    return Row(
      children: [
        Text(
          DurationFormatter.format(position),
          style: TextStyle(
            // Matches the accent progress track beside it.
            color: context.colors.accent,
            fontSize: 12,
            fontFamily: 'monospace',
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
        Expanded(
          child: _MinimalistSlider(
            value: progress.clamp(0.0, 1.0),
            onChangeStart: onSeekStart,
            onChanged: onSeekUpdate,
            onChangeEnd: onSeekEnd,
          ),
        ),
        Text(
          '−${DurationFormatter.format(duration - position)}',
          style: const TextStyle(
            color: _kWhite60,
            fontSize: 12,
            fontFamily: 'monospace',
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }
}


