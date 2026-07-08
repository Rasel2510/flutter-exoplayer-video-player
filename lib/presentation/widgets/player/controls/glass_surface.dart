part of 'player_controls_overlay.dart';

/// The shared material for every player control surface. In [tint] mode it is
/// a flat translucent-black container (the original look); in [frosted] mode it
/// clips to its shape and applies a [BackdropFilter.grouped] blur so the live
/// video melts through the glass. All frosted surfaces share one blur pass via
/// the [BackdropGroup] the overlay installs, so N buttons cost one blur, not N.
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
    final isCircle = borderRadius == null;

    final decoration = BoxDecoration(
      gradient: frosted
          ? (strong ? _kFrostGradientStrong : _kFrostGradient)
          : (strong ? _kTintGradientStrong : _kTintGradient),
      shape: isCircle ? BoxShape.circle : BoxShape.rectangle,
      borderRadius: borderRadius,
      // A brighter hairline on frosted surfaces reads as a lit glass edge.
      border: Border.all(
        color: borderColor ?? (frosted ? _kWhite30 : _kWhite20),
      ),
      // A drop shadow only makes sense in tint mode — inside the frosted clip
      // it can't cast beyond the surface anyway.
      boxShadow: frosted ? null : shadow,
    );

    final content = Container(
      width: width,
      height: height,
      padding: padding,
      alignment: alignment,
      decoration: decoration,
      child: child,
    );

    if (!frosted) return content;

    final blurred =
        BackdropFilter.grouped(filter: _kFrostFilter, child: content);
    return isCircle
        ? ClipOval(child: blurred)
        : ClipRRect(borderRadius: borderRadius!, child: blurred);
  }
}
