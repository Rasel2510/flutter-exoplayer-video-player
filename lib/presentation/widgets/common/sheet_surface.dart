import 'package:flutter/material.dart';
import 'package:flutter_video_player/core/theme/app_theme.dart';

/// Shared shell for every bottom sheet in the app.
///
/// Crucially, it bounds the sheet to a fraction of the screen height. The
/// player runs in landscape, where the usable height is small (~360 dp), and
/// the fixed-height [Column]s the sheets are built from used to overflow there
/// — pushing the lower controls off-screen and clipping them. Bounding the
/// height and letting the body scroll keeps every control reachable in any
/// orientation.
///
/// Always open the sheet with `isScrollControlled: true` so the modal is
/// allowed to take the full height this shell asks for.
class SheetSurface extends StatelessWidget {
  /// The body shown beneath the drag handle. It is given the remaining space
  /// via [Flexible], so a [SingleChildScrollView] (for fixed content) or a
  /// [Column] ending in an [Expanded] list both behave correctly and scroll
  /// instead of overflowing.
  final Widget child;

  /// Fraction of screen height the sheet may occupy at most.
  final double maxHeightFactor;

  const SheetSurface({
    super.key,
    required this.child,
    this.maxHeightFactor = 0.9,
  });

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * maxHeightFactor,
      ),
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: context.colors.panel,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Drag handle ──────────────────────────────────────────────
            Center(
              child: Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: context.colors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Flexible(child: child),
          ],
        ),
      ),
    );
  }
}
