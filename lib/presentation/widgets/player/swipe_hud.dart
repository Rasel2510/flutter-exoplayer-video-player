import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/volume_color.dart';
import '../../providers/player_provider.dart';

class SwipeHud extends StatelessWidget {
  final SwipeGesture gesture;

  /// Normalised value passed from the provider.
  ///
  /// • Brightness: 0.0 – 1.0  (direct fraction)
  /// • Volume:     0.0 – 1.0  where 0.5 = device 100 %, 1.0 = boost 200 %
  ///               (stored as volume / 200 in the provider)
  final double value;

  const SwipeHud({super.key, required this.gesture, required this.value});

  static const Color _brightnessColor = Color(0xFFFFE066); // warm yellow

  @override
  Widget build(BuildContext context) {
    final isBrightness = gesture == SwipeGesture.brightness;

    // ── Colour ───────────────────────────────────────────────────────────────
    // Brightness: warm yellow.
    // Volume ≤ 100 %: accent (blue); > 100 %: lerp blue → orange, getting more
    // orange the higher it goes (swipeValue = volume / 200, so value * 200 is
    // the real volume %). Shared with the volume sheet via VolumeColor.
    final Color color = isBrightness
        ? _brightnessColor
        : VolumeColor.forVolume(value * 200, context.colors.accent);

    // ── Icon ────────────────────────────────────────────────────────────────
    final IconData icon;
    if (isBrightness) {
      icon = value > 0.6
          ? Icons.brightness_high_rounded
          : value > 0.3
              ? Icons.brightness_medium_rounded
              : Icons.brightness_low_rounded;
    } else {
      icon = value > 0.6
          ? Icons.volume_up_rounded
          : value > 0.0
              ? Icons.volume_down_rounded
              : Icons.volume_off_rounded;
    }

    // ── Percentage text ─────────────────────────────────────────────────────
    // Brightness: value is 0–1  → multiply by 100.
    // Volume    : value is volume/200 → multiply by 200 to get real volume %.
    final String percent = isBrightness
        ? '${(value * 100).round()}%'
        : '${(value * 200).round()}%';

    return Align(
      alignment: isBrightness ? Alignment.centerLeft : Alignment.centerRight,
      child: Container(
        width: 44,
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xB8000000),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: const Color(0x1AFFFFFF), width: 1),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 8),
            // ── Progress bar ──────────────────────────────────────────────
            // Single bar whose fill colour shifts from blue (≤100 %) toward
            // orange as the boost ratio climbs to 200 %.
            SizedBox(
              width: 4,
              height: 90,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(2),
                child: RotatedBox(
                  quarterTurns: -1,
                  child: LinearProgressIndicator(
                    value: value.clamp(0.0, 1.0),
                    backgroundColor: const Color(0x2EFFFFFF),
                    valueColor: AlwaysStoppedAnimation(color),
                    minHeight: 4,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              percent,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                fontFamily: 'monospace',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
