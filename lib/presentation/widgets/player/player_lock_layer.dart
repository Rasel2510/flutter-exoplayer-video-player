import 'package:flutter/material.dart';
import 'overlays/lock_overlay.dart';

/// The lock-mode touch-absorber + lock icon, layered above the gesture layer.
/// Icon visibility is driven entirely by [iconController] (an
/// AnimationController owned by the screen) rather than provider state, so
/// showing/hiding it never triggers a Consumer rebuild — and therefore never
/// re-composites the video platform view (the white-flash bug this
/// specifically avoids).
class PlayerLockLayer extends StatelessWidget {
  final bool isLocked;
  final AnimationController iconController;
  final VoidCallback onTapWhileLocked;
  final VoidCallback onUnlock;

  const PlayerLockLayer({
    super.key,
    required this.isLocked,
    required this.iconController,
    required this.onTapWhileLocked,
    required this.onUnlock,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Touch-absorber — always in tree, active only when locked.
        // IgnorePointer switches touch-absorption without adding/removing
        // siblings, so the Video platform view is never re-composited.
        Positioned.fill(
          child: IgnorePointer(
            ignoring: !isLocked,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              // When the locked screen is tapped, show the lock icon via
              // iconController — a purely local animation that never updates
              // provider state and therefore causes zero rebuilds (and zero
              // white flashes on the video layer).
              onTap: isLocked ? onTapWhileLocked : null,
              onScaleStart: (_) {},
              onScaleUpdate: (_) {},
              onScaleEnd: (_) {},
              child: const SizedBox.expand(),
            ),
          ),
        ),

        // Lock icon — driven by the local AnimationController.
        Positioned.fill(
          child: FadeTransition(
            opacity: iconController,
            child: AnimatedBuilder(
              animation: iconController,
              builder: (context, child) => IgnorePointer(
                // Pass taps through when hidden so the touch-absorber can
                // show the icon on the next tap.
                ignoring: !isLocked || iconController.value == 0,
                child: child,
              ),
              child: LockOverlay(onUnlock: onUnlock),
            ),
          ),
        ),
      ],
    );
  }
}
