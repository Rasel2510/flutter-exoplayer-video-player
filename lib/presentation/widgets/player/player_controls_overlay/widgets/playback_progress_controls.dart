part of '../player_controls_overlay.dart';

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

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _MinimalistSlider(
          value: progress.clamp(0.0, 1.0),
          onChangeStart: onSeekStart,
          onChanged: onSeekUpdate,
          onChangeEnd: onSeekEnd,
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              DurationFormatter.format(position),
              style: const TextStyle(
                color: _kWhite100,
                fontSize: 12,
                fontFamily: 'monospace',
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
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
        ),
      ],
    );
  }
}


