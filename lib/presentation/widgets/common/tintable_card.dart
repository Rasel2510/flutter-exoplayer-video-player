import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_video_player/core/theme/app_theme.dart';
import 'package:flutter_video_player/presentation/providers/library_card_style_provider.dart';
import 'animated_squish_card.dart';

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

    final ink = InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      splashColor: context.colors.accentSoft,
      highlightColor: Colors.transparent,
      child: child,
    );

    final Widget surface;
    if (tinted) {
      final dark = Theme.of(context).brightness == Brightness.dark;
      surface = DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: AppRadius.md,
          // Light mode uses a softer, brighter tint so the card reads like a
          // subtle glass overlay instead of a dark block. Dark mode keeps the
          // stronger black-and-white player-control treatment.
          gradient: dark
              ? const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0x24FFFFFF),
                    Color(0x4D000000),
                    Color(0x6B000000)
                  ],
                  stops: [0.0, 0.4, 1.0],
                )
              : const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0x12FFFFFF),
                    Color(0x0D000000),
                    Color(0x0A000000)
                  ],
                  stops: [0.0, 0.45, 1.0],
                ),
          border: Border.all(
            color: dark ? const Color(0x33FFFFFF) : const Color(0x14000000),
          ),
          boxShadow: dark
              ? const [
                  BoxShadow(
                    color: Color(0x33000000),
                    blurRadius: 12,
                    offset: Offset(0, 6),
                  ),
                ]
              : const [
                  BoxShadow(
                    color: Color(0x14000000),
                    blurRadius: 8,
                    offset: Offset(0, 3),
                  ),
                ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: AppRadius.md,
          clipBehavior: Clip.antiAlias,
          child: ink,
        ),
      );
    } else {
      surface = Material(
        color: context.colors.surface,
        borderRadius: AppRadius.md,
        clipBehavior: Clip.antiAlias,
        child: ink,
      );
    }

    return AnimatedSquishCard(child: surface);
  }
}
