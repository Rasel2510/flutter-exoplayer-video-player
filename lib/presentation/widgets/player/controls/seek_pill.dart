part of 'player_controls_overlay.dart';

class _SeekPill extends StatelessWidget {
  final int seconds;
  final VoidCallback onTap;
  const _SeekPill({required this.seconds, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isForward = seconds > 0;
    final val = seconds.abs();

    final IconData iconData;
    if (isForward) {
      iconData = switch (val) {
        5  => Icons.forward_5_rounded,
        10 => Icons.forward_10_rounded,
        30 => Icons.forward_30_rounded,
        _  => Icons.fast_forward_rounded,
      };
    } else {
      iconData = switch (val) {
        5  => Icons.replay_5_rounded,
        10 => Icons.replay_10_rounded,
        30 => Icons.replay_30_rounded,
        _  => Icons.fast_rewind_rounded,
      };
    }

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: _GlassSurface(
        width: 46,
        height: 46,
        alignment: Alignment.center,
        // Glass circle — matches the play button beside it so the whole
        // center cluster reads as one control group.
        child: val == 15
          // Custom fallback for 15s since Icons.forward_15 doesn't exist natively.
          ? Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isForward ? Icons.fast_forward_rounded : Icons.fast_rewind_rounded,
                  size: 22,
                  color: _kWhite90,
                ),
                const Text('15', style: TextStyle(color: _kWhite90, fontSize: 9, fontWeight: FontWeight.bold, height: 1)),
              ],
            )
          : Icon(
              iconData,
              size: 28,
              color: _kWhite90,
            ),
      ),
    );
  }
}
