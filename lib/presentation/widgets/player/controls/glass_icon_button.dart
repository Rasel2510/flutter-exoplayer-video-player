part of 'player_controls_overlay.dart';

class _GlassIconButton extends StatelessWidget {
  final IconData icon;
  final double size;
  final VoidCallback onTap;
  final bool active;
  final bool boosted;
  final LoopMode? loopMode;

  /// Draws the icon inside a translucent glass circle — used for the
  /// standalone buttons (lock / PiP / rotate) so they read as tappable
  /// against any video frame. Left off inside the top action pill, where
  /// the shared pill background already does that job.
  final bool filled;

  const _GlassIconButton({
    required this.icon,
    required this.size,
    required this.onTap,
    this.active = false,
    this.boosted = false,
    this.loopMode,
    this.filled = false,
  });

  // Inlined as a method so the expression is evaluated once per build,
  // not allocated as a separate stack frame.
  Color _getIconColor(BuildContext context) {
    if (boosted) {
      return _kOrange;
    }
    if (loopMode != null) {
      return switch (loopMode!) {
        LoopMode.none => _kWhite100,
        LoopMode.loopAll => context.colors.accent,
        LoopMode.loopOne => _kOrange,
      };
    }
    return active ? context.colors.accent : _kWhite100;
  }

  @override
  Widget build(BuildContext context) {
    final iconWidget = Icon(icon, size: size, color: _getIconColor(context));
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: filled
          ? _GlassSurface(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              child: iconWidget,
            )
          : Padding(
              padding: const EdgeInsets.all(8),
              child: iconWidget,
            ),
    );
  }
}
