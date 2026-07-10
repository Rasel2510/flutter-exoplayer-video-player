import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_video_player/core/theme/app_theme.dart';
import 'package:flutter_video_player/presentation/providers/library_card_style_provider.dart';
import 'animated_squish_card.dart';

// Hoisted top-level so they're built once, not reallocated on every list
// item's build. Deliberately NOT shared with the player controls' glass
// gradients (common/glass_surface.dart) — those are tuned for a permanently
// dark video backdrop, while cards need separate dark/light variants to stay
// legible against the app's own theme.
const LinearGradient _kTintedGradientDark = LinearGradient(
  begin: Alignment.topCenter,
  end: Alignment.bottomCenter,
  colors: [Color(0x24FFFFFF), Color(0x4D000000), Color(0x6B000000)],
  stops: [0.0, 0.4, 1.0],
);
const LinearGradient _kTintedGradientLight = LinearGradient(
  begin: Alignment.topCenter,
  end: Alignment.bottomCenter,
  colors: [Color(0x18FFFFFF), Color(0x24000000), Color(0x32000000)],
  stops: [0.0, 0.45, 1.0],
);
const Color _kTintedBorderDark = Color(0x33FFFFFF);
const Color _kTintedBorderLight = Color(0x20000000);
const List<BoxShadow> _kTintedShadowDark = [
  BoxShadow(color: Color(0x33000000), blurRadius: 12, offset: Offset(0, 6)),
];
const List<BoxShadow> _kTintedShadowLight = [
  BoxShadow(color: Color(0x20000000), blurRadius: 10, offset: Offset(0, 4)),
];

/// Shared shell for library list cards (folder & video). In
/// [LibraryCardStyle.standard] it's the original opaque [surface] card; in
/// [LibraryCardStyle.tinted] it becomes a translucent glass card — a subtle
/// top-sheen gradient with a brighter hairline edge — echoing the player's
/// tinted controls. Keeps the ink ripple in both modes and wraps everything
/// in the [AnimatedSquishCard] press animation the cards already used.
class TintableCard extends ConsumerWidget {
  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const TintableCard({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tinted = ref.watch(cardStyleProvider) == LibraryCardStyle.tinted;
    final dark = Theme.of(context).brightness == Brightness.dark;

    final ink = InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      splashColor: context.colors.accentSoft,
      highlightColor: Colors.transparent,
      child: child,
    );

    // Always the SAME widget shape (DecoratedBox -> Material(transparent) ->
    // InkWell) regardless of `tinted` — only the BoxDecoration's fields
    // change. This is what lets the "Tinted card style" toggle update
    // in place instead of tearing down and rebuilding every visible card's
    // subtree (which used to reset each VideoThumbnailWidget and flash its
    // shimmer placeholder on every toggle, since Material and DecoratedBox
    // are different widget types at the same tree slot).
    final decoration = tinted
        ? BoxDecoration(
            borderRadius: AppRadius.md,
            gradient: dark ? _kTintedGradientDark : _kTintedGradientLight,
            border: Border.all(
              color: dark ? _kTintedBorderDark : _kTintedBorderLight,
            ),
            boxShadow: dark ? _kTintedShadowDark : _kTintedShadowLight,
          )
        : BoxDecoration(
            borderRadius: AppRadius.md,
            color: context.colors.surface,
          );

    return AnimatedSquishCard(
      child: DecoratedBox(
        decoration: decoration,
        child: Material(
          color: Colors.transparent,
          borderRadius: AppRadius.md,
          clipBehavior: Clip.antiAlias,
          child: ink,
        ),
      ),
    );
  }
}
