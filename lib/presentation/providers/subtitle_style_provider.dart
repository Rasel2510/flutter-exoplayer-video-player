import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_video_player/data/services/player_preferences_service.dart';

/// Preset subtitle text colors. The index into this list is what gets
/// persisted (so adding presets later won't shift anyone's saved choice as
/// long as new colors are appended, not inserted).
const subtitleColorPresets = <Color>[
  Color(0xFFFFFFFF), // White (default)
  Color(0xFFFFEB3B), // Yellow
  Color(0xFF00E5FF), // Cyan
  Color(0xFF76FF03), // Green
  Color(0xFFFF4081), // Pink
  Color(0xFFFF9800), // Orange
  Color(0xFFE040FB), // Purple
  // Appended later — a softer, more refined set alongside the original neon
  // presets above (same jewel-tone family as libraryAccentPresets). Keep
  // adding new presets to the end, never insert earlier in the list.
  Color(0xFFFFD54F), // Gold
  Color(0xFF64B5F6), // Sky blue
  Color(0xFF69F0AE), // Mint
  Color(0xFFFF8A65), // Coral
  Color(0xFFB388FF), // Lavender
  Color(0xFFF48FB1), // Blush
];

const subtitleBgColorPresets = <Color>[
  Color(0xAA000000), // Black (default)
  Color(0xAA2196F3), // Blue
  Color(0xAA4CAF50), // Green
  Color(0xAAF44336), // Red
  Color(0xAA9C27B0), // Purple
  // Appended later — richer, more subdued tones than the bright primaries
  // above. Keep adding new presets to the end, never insert earlier.
  Color(0xAA37474F), // Slate
  Color(0xAA1A237E), // Navy
  Color(0xAA2E7D32), // Forest
];

/// Preset subtitle fonts. These are Android's built-in generic font families,
/// so they need no bundled assets and work offline on every device. The index
/// is what gets persisted — append new fonts, never insert.
const subtitleFontPresets = <({String label, String? family})>[
  (label: 'Default', family: null),
  (label: 'Serif', family: 'serif'),
  (label: 'Mono', family: 'monospace'),
  (label: 'Condensed', family: 'sans-serif-condensed'),
  (label: 'Light', family: 'sans-serif-light'),
  (label: 'Cursive', family: 'cursive'),
  (label: 'Casual', family: 'casual'),
  (label: 'Small Caps', family: 'sans-serif-smallcaps'),
];

class SubtitleStyle {
  final double fontSize;
  final int colorIndex;
  final bool background;
  final int backgroundColorIndex;
  final int fontIndex;
  final Offset? position;

  const SubtitleStyle({
    this.fontSize = 32.0,
    this.colorIndex = 0,
    this.background = true,
    this.backgroundColorIndex = 0,
    this.fontIndex = 0,
    this.position,
  });

  Color get color =>
      subtitleColorPresets[colorIndex.clamp(0, subtitleColorPresets.length - 1)];

  Color get backgroundColor =>
      subtitleBgColorPresets[backgroundColorIndex.clamp(0, subtitleBgColorPresets.length - 1)];

  /// Font family for the subtitle text; null = the app's default font.
  String? get fontFamily =>
      subtitleFontPresets[fontIndex.clamp(0, subtitleFontPresets.length - 1)]
          .family;

  SubtitleStyle copyWith({
    double? fontSize,
    int? colorIndex,
    bool? background,
    int? backgroundColorIndex,
    int? fontIndex,
    Offset? position,
  }) =>
      SubtitleStyle(
        fontSize: fontSize ?? this.fontSize,
        colorIndex: colorIndex ?? this.colorIndex,
        background: background ?? this.background,
        backgroundColorIndex: backgroundColorIndex ?? this.backgroundColorIndex,
        fontIndex: fontIndex ?? this.fontIndex,
        position: position ?? this.position,
      );
}

final subtitleStyleProvider =
    StateNotifierProvider<SubtitleStyleNotifier, SubtitleStyle>((ref) {
  return SubtitleStyleNotifier();
});

class SubtitleStyleNotifier extends StateNotifier<SubtitleStyle> {
  // Seed from the synchronously-cached values (warmed by preload() in main)
  // so the saved style applies on the first frame — no flash of the default.
  SubtitleStyleNotifier() : super(_initial());

  static SubtitleStyle _initial() {
    final prefs = PlayerPreferencesService.instance;
    final x = prefs.subtitlePositionXCached;
    final y = prefs.subtitlePositionYCached;
    final position = (x != null && y != null) ? Offset(x, y) : null;
    return SubtitleStyle(
      fontSize: prefs.subtitleFontSizeCached,
      colorIndex: prefs.subtitleColorIndexCached,
      background: prefs.subtitleBackgroundCached,
      backgroundColorIndex: prefs.subtitleBgColorIndexCached,
      fontIndex: prefs.subtitleFontIndexCached,
      position: position,
    );
  }

  static const double minFontSize = 16.0;
  static const double maxFontSize = 56.0;

  void adjustFontSize(double delta) {
    final clamped = (state.fontSize + delta).clamp(minFontSize, maxFontSize);
    state = state.copyWith(fontSize: clamped);
    PlayerPreferencesService.instance.saveSubtitleFontSize(clamped);
  }

  void setColorIndex(int index) {
    state = state.copyWith(colorIndex: index);
    PlayerPreferencesService.instance.saveSubtitleColorIndex(index);
  }

  void setBackground(bool enabled) {
    state = state.copyWith(background: enabled);
    PlayerPreferencesService.instance.saveSubtitleBackground(enabled);
  }

  void setBackgroundColorIndex(int index) {
    state = state.copyWith(backgroundColorIndex: index);
    PlayerPreferencesService.instance.saveSubtitleBgColorIndex(index);
  }

  void setFontIndex(int index) {
    state = state.copyWith(fontIndex: index);
    PlayerPreferencesService.instance.saveSubtitleFontIndex(index);
  }

  void setPosition(Offset position) {
    state = state.copyWith(position: position);
    PlayerPreferencesService.instance.saveSubtitlePosition(position.dx, position.dy);
  }

  void resetPosition() {
    state = SubtitleStyle(
      fontSize: state.fontSize,
      colorIndex: state.colorIndex,
      background: state.background,
      backgroundColorIndex: state.backgroundColorIndex,
      fontIndex: state.fontIndex,
      position: null,
    );
    PlayerPreferencesService.instance.saveSubtitlePosition(null, null);
  }
}
