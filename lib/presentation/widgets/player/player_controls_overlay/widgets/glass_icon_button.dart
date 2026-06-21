part of '../player_controls_overlay.dart';

class _GlassIconButton extends StatelessWidget {
  final IconData icon;
  final double size;
  final VoidCallback onTap;
  final bool active;
  final bool boosted;
  final LoopMode? loopMode;

  const _GlassIconButton({
    required this.icon,
    required this.size,
    required this.onTap,
    this.active = false,
    this.boosted = false,
    this.loopMode,
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
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Icon(icon, size: size, color: _getIconColor(context)),
      ),
    );
  }
}


