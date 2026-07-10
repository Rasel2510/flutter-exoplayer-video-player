import 'dart:ui' show ImageFilter;
import 'package:flutter/material.dart';

/// Visual treatment for a translucent "glass" control surface — shared by
/// the player's on-screen buttons, the mini-player, and the lock overlay so
/// they all render identically and stay in sync with the same setting.
enum GlassStyle { tint, frosted }

// Shared once (ImageFilter is immutable) so no button allocates its own blur
// handle per rebuild. `kGlassNoBlur` is a 0-sigma blur — a cheap pass-through
// — used for [GlassStyle.tint] so tint and frosted always render through the
// exact same clip+backdrop-filter shape (only the filter/gradient VALUES
// differ, never the widget type). That's what lets a GlassSurface's style
// change at runtime without ever tearing down its descendants: a play button
// mid-animation, an open ink splash, a scrolled action pill all survive a
// tint<->frosted toggle intact.
final ImageFilter kGlassNoBlur = ImageFilter.blur(sigmaX: 0, sigmaY: 0);
final ImageFilter kGlassFrostBlur = ImageFilter.blur(sigmaX: 18.0, sigmaY: 18.0);

const Color kGlassBorderTint = Color(0x1FFFFFFF); // ~12% white
const Color kGlassBorderFrost = Color(0x4DFFFFFF); // ~30% white

// A light sheen at the top edge (simulating rim light on glass) eases into a
// darker body that keeps white icons legible over bright frames. Frosted
// variants sit over a live blur so their bodies are lighter (more video
// colour shows through); tint variants are darker since there's no blur to
// add depth.
const LinearGradient kGlassTintGradient = LinearGradient(
  begin: Alignment.topCenter,
  end: Alignment.bottomCenter,
  colors: [Color(0x24FFFFFF), Color(0x4D000000), Color(0x6B000000)],
  stops: [0.0, 0.4, 1.0],
);
// Slightly less bright at the top than the non-strong variant — the play
// button (the only "strong" user) needs the icon legible against bright
// frames more than it needs a pronounced rim highlight.
const LinearGradient kGlassTintGradientStrong = LinearGradient(
  begin: Alignment.topCenter,
  end: Alignment.bottomCenter,
  colors: [Color(0x1AFFFFFF), Color(0x99000000), Color(0xB3000000)],
  stops: [0.0, 0.4, 1.0],
);
const LinearGradient kGlassFrostGradient = LinearGradient(
  begin: Alignment.topCenter,
  end: Alignment.bottomCenter,
  colors: [Color(0x40FFFFFF), Color(0x1F000000), Color(0x42000000)],
  stops: [0.0, 0.45, 1.0],
);
const LinearGradient kGlassFrostGradientStrong = LinearGradient(
  begin: Alignment.topCenter,
  end: Alignment.bottomCenter,
  colors: [Color(0x4DFFFFFF), Color(0x3D000000), Color(0x5C000000)],
  stops: [0.0, 0.45, 1.0],
);

/// A translucent glass control surface. [style] picks the look; both
/// variants always render through the identical clip + backdrop-filter +
/// container shape (only the blur sigma and gradient differ), so toggling
/// [style] — or a [BackdropGroup] ancestor coming or going — never swaps
/// this widget's type and never tears down its descendants. Every frosted
/// surface under one [BackdropGroup] shares a single blur pass.
///
/// Pass [borderRadius] null for a circle (icon buttons, seek/track/play) or
/// a radius for a pill/chip. [strong] uses a slightly heavier/darker fill
/// for surfaces (like the play button) whose icon needs to stay legible over
/// bright frames. [shadow] (tint only — a blurred+clipped surface can't cast
/// a shadow past its own edge) is always wrapped when the *call site* passes
/// one, so its presence never depends on the runtime style either.
class GlassSurface extends StatelessWidget {
  final GlassStyle style;
  final Widget child;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final AlignmentGeometry? alignment;
  final BorderRadius? borderRadius; // null => circle
  final Color? borderColor;
  final bool strong;
  final List<BoxShadow>? shadow;

  const GlassSurface({
    super.key,
    required this.style,
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
    final frosted = style == GlassStyle.frosted;
    final isCircle = borderRadius == null;

    final gradient = frosted
        ? (strong ? kGlassFrostGradientStrong : kGlassFrostGradient)
        : (strong ? kGlassTintGradientStrong : kGlassTintGradient);

    Widget surface = Container(
      width: width,
      height: height,
      padding: padding,
      alignment: alignment,
      decoration: BoxDecoration(
        gradient: gradient,
        shape: isCircle ? BoxShape.circle : BoxShape.rectangle,
        borderRadius: borderRadius,
        border: Border.all(
          color: borderColor ?? (frosted ? kGlassBorderFrost : kGlassBorderTint),
        ),
      ),
      child: child,
    );

    // Always clipped + backdrop-filtered, in both styles (a 0-sigma blur is
    // a cheap no-op) — this is what keeps the pill/circle shape from ever
    // showing unclipped corners in tint mode, and keeps the widget shape
    // stable across a style change.
    surface = BackdropFilter.grouped(
      filter: frosted ? kGlassFrostBlur : kGlassNoBlur,
      child: surface,
    );
    surface = isCircle
        ? ClipOval(child: surface)
        : ClipRRect(borderRadius: borderRadius!, child: surface);

    if (shadow != null) {
      // Shadows must render OUTSIDE the clip above (they extend past the
      // shape's own bounds) — this shape-only DecoratedBox paints just the
      // drop shadow; the clipped surface above supplies the fill/blur/border.
      // Wrapped whenever the CALL SITE passes a shadow (a per-widget-type
      // constant — only the play button does), so this wrapper's presence
      // never depends on `frosted`, only the boxShadow's value does.
      surface = DecoratedBox(
        decoration: BoxDecoration(
          shape: isCircle ? BoxShape.circle : BoxShape.rectangle,
          borderRadius: borderRadius,
          boxShadow: frosted ? null : shadow,
        ),
        child: surface,
      );
    }

    return surface;
  }
}
