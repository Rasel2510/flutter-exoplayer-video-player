part of 'player_controls_overlay.dart';

class _MinimalistSlider extends StatelessWidget {
  final double value;
  final void Function(double) onChangeStart;
  final void Function(double) onChanged;
  final void Function(double) onChangeEnd;

  const _MinimalistSlider({
    required this.value,
    required this.onChangeStart,
    required this.onChanged,
    required this.onChangeEnd,
  });

  @override
  Widget build(BuildContext context) {
    final accent = context.colors.accent;
    return SliderTheme(
      data: SliderTheme.of(context).copyWith(
        trackHeight: 3,
        thumbShape: const RoundSliderThumbShape(
          enabledThumbRadius: 6.5,
          elevation: 3,
          pressedElevation: 6,
        ),
        overlayShape: const RoundSliderOverlayShape(overlayRadius: 18),
        thumbColor: _kWhite100,
        // Accent-colored progress reads instantly against the white-on-black
        // chrome and matches the rest of the app's accent usage.
        activeTrackColor: accent,
        inactiveTrackColor: _kWhite30,
        overlayColor: accent.withValues(alpha: 0.18),
      ),
      child: Slider(
        value: value,
        onChangeStart: onChangeStart,
        onChanged: onChanged,
        onChangeEnd: onChangeEnd,
      ),
    );
  }
}

// ── Shared small widgets ──────────────────────────────────────────────────────


