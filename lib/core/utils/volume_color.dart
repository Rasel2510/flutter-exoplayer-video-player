import 'package:flutter/material.dart';

/// Shared volume-gauge colour logic so the volume sheet slider and the swipe
/// HUD ramp identically: the accent colour (blue) at ≤100 %, lerping toward
/// [boost] (orange) the further past 100 % the volume is pushed — fully orange
/// at 200 %.
abstract final class VolumeColor {
  /// Orange shown at full 200 % boost.
  static const Color boost = Color(0xFFFF8C00);

  /// Translucent boost orange, used for soft fills / overlays.
  static const Color boostSoft = Color(0x33FF8C00);

  /// Fraction (0–1) of the way into the boost range for [volumePercent]:
  /// 0 at or below 100 %, 1 at 200 %.
  static double boostT(double volumePercent) =>
      ((volumePercent - 100.0) / 100.0).clamp(0.0, 1.0);

  /// Gauge colour for [volumePercent], lerping [accent] → [boost].
  static Color forVolume(double volumePercent, Color accent) {
    final t = boostT(volumePercent);
    return t <= 0.0 ? accent : Color.lerp(accent, boost, t)!;
  }
}
