part of 'player_controls_overlay.dart';

/// Thin adapter over the shared [glass.GlassSurface] widget: resolves
/// [PlayerControlsStyle] (read from [_GlassStyleScope]) to a [glass.GlassStyle]
/// so every player button, chip, and pill renders through the same primitive
/// the mini-player and lock overlay use — one shared implementation instead
/// of a second, diverging one.
///
/// Pass [borderRadius] null for a circle (icon buttons, seek/track/play) or a
/// radius for a pill/chip. [strong] uses a heavier fill for the play button so
/// its icon stays legible over bright frames.
class _GlassSurface extends StatelessWidget {
  final Widget child;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final AlignmentGeometry? alignment;
  final BorderRadius? borderRadius; // null => circle
  final Color? borderColor;
  final bool strong;
  final List<BoxShadow>? shadow; // tint mode only (clipped away when frosted)

  const _GlassSurface({
    required this.child,
    this.width,
    this.height,
    this.padding,
    this.alignment,
    this.borderRadius,
    this.borderColor,
    this.strong = false,
    this.shadow,
  });

  @override
  Widget build(BuildContext context) {
    final frosted =
        _GlassStyleScope.of(context) == PlayerControlsStyle.frosted;
    return glass.GlassSurface(
      style: frosted ? glass.GlassStyle.frosted : glass.GlassStyle.tint,
      width: width,
      height: height,
      padding: padding,
      alignment: alignment,
      borderRadius: borderRadius,
      borderColor: borderColor,
      strong: strong,
      shadow: shadow,
      child: child,
    );
  }
}
