import 'package:flutter/material.dart';
import 'package:flutter_video_player/core/theme/app_theme.dart';
import 'package:flutter_video_player/core/utils/volume_color.dart';
import 'package:flutter_video_player/presentation/providers/player_provider.dart';

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

    // ── Bar fill (SwipeHud design spec) ──────────────────────────────────────
    // 0–100 %: the fill grows 0→full (full exactly at 100 %). 100–200 %: the
    // bar STAYS full — no climbing layer, no dimming — and the fill colour
    // shifts accent→hot red as the boost increases, so it never feels empty.
    final double basePct =
        isBrightness ? value : (value * 2).clamp(0.0, 1.0);
    final Color fillColor = isBrightness
        ? _brightnessColor
        : VolumeColor.barColor(value * 200, context.colors.accent);

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
            // Single solid fill: grows to full at 100 %, then the whole bar's
            // colour heats accent→red across the boost range (design spec).
            SizedBox(
              width: 4,
              height: 90,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(2),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    const ColoredBox(color: Color(0x2EFFFFFF)),
                    Align(
                      alignment: Alignment.bottomCenter,
                      child: FractionallySizedBox(
                        heightFactor: basePct,
                        widthFactor: 1.0,
                        child: ColoredBox(color: fillColor),
                      ),
                    ),
                  ],
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
