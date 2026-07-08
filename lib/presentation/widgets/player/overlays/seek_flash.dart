import 'package:flutter/material.dart';

class SeekFlash extends StatelessWidget {
  final Animation<double> animation;
  final bool isForward;
  final int seekInterval;

  const SeekFlash({
    super.key,
    required this.animation,
    required this.isForward,
    required this.seekInterval,
  });

  @override
  Widget build(BuildContext context) {
    // Precompute BorderRadius once — isForward is final so this never changes.
    // Without this, BorderRadius.horizontal() was called on every animation frame.
    final radius = BorderRadius.horizontal(
      left:  isForward ? Radius.zero : const Radius.circular(999),
      right: isForward ? const Radius.circular(999) : Radius.zero,
    );

    // Icon and label are static — extract outside AnimatedBuilder so Flutter
    // doesn't reconstruct them on every frame (only the Container colour changes).
    // Pick the icon that best matches the configured interval.
    final IconData iconData;
    if (isForward) {
      iconData = seekInterval <= 5
          ? Icons.forward_5_rounded
          : seekInterval <= 10
              ? Icons.forward_10_rounded
              : Icons.forward_30_rounded;
    } else {
      iconData = seekInterval <= 5
          ? Icons.replay_5_rounded
          : seekInterval <= 10
              ? Icons.replay_10_rounded
              : Icons.replay_30_rounded;
    }
    final icon = Icon(iconData, color: Colors.white, size: 40);
    final label = Text(
      isForward ? '+${seekInterval}s' : '-${seekInterval}s',
      style: const TextStyle(
        color: Colors.white,
        fontSize: 13,
        fontWeight: FontWeight.w600,
      ),
    );

    return AnimatedBuilder(
      animation: animation,
      builder: (_, __) {
        final opacity = (1.0 - animation.value).clamp(0.0, 1.0);
        return IgnorePointer(
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: opacity * 0.15),
              borderRadius: radius,   // reuse precomputed value
            ),
            child: Center(
              child: Opacity(
                opacity: opacity,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [icon, const SizedBox(height: 6), label],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
