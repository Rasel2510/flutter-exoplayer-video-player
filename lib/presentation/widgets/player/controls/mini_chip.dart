part of 'player_controls_overlay.dart';

class _MiniChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final Color? color;

  /// True when the chip sits inside the top action pill, which already
  /// provides the glass surface — so the chip draws no fill of its own
  /// (only its text, plus a thin accent outline when [color] marks it active).
  /// False for standalone chips (the bottom FIT chip), which get their own
  /// [_GlassSurface].
  final bool bare;

  const _MiniChip({
    required this.label,
    required this.onTap,
    this.color,
    this.bare = false,
  });

  @override
  Widget build(BuildContext context) {
    final text = Text(
      label,
      style: TextStyle(
        color: color ?? _kWhite100,
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.6,
      ),
    );

    final Widget surface;
    if (bare) {
      final inner = Container(
        height: 32,
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 11),
        child: text,
      );
      surface = color == null
          ? inner
          : DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: color!),
              ),
              child: inner,
            );
    } else {
      surface = _GlassSurface(
        height: 32,
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 13),
        // Stadium shape to match the circular glass buttons beside it.
        borderRadius: BorderRadius.circular(16),
        borderColor: color,
        child: text,
      );
    }

    // opaque: the bare branch's Container has no decoration (no color/border
    // when `color` is null), so without this the tap area shrinks to just
    // the Text's own glyph bounds instead of the full padded chip.
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: surface,
    );
  }
}

// ── Public exports ────────────────────────────────────────────────────────────


