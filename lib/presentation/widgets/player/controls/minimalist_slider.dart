part of '../player_controls_overlay.dart';

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
    return SliderTheme(
      data: SliderTheme.of(context).copyWith(
        trackHeight: 2.5,
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
        overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
        thumbColor: _kWhite100,
        activeTrackColor: _kWhite100,
        inactiveTrackColor: _kWhite30,
        overlayColor: _kWhite12,
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


