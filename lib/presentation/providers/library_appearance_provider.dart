import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/player_preferences_service.dart';

/// Preset colors for the folder icon and the "NEW" badge. Index 0 is "Theme"
/// (color: null) — it tracks the app's current light/dark accent instead of a
/// fixed swatch. The rest are a curated jewel-tone palette (same family as
/// Tailwind's 500-shade scale) chosen for even saturation/lightness across
/// hues, rather than flat Material primaries. The index is what gets
/// persisted, so new presets must be appended, never inserted — changing a
/// hex value in place (a re-skin) is safe, reordering is not.
const libraryAccentPresets = <({String label, Color? color})>[
  (label: 'Theme', color: null),
  (label: 'Coral', color: Color(0xFFFF6F61)),
  (label: 'Amber', color: Color(0xFFF5A623)),
  (label: 'Emerald', color: Color(0xFF10B981)),
  (label: 'Sky', color: Color(0xFF0EA5E9)),
  (label: 'Indigo', color: Color(0xFF6366F1)),
  (label: 'Rose', color: Color(0xFFF43F5E)),
  (label: 'Teal', color: Color(0xFF14B8A6)),
  // Appended later — keep adding new presets to the end, never insert
  // earlier in the list (see class comment above).
  (label: 'Orange', color: Color(0xFFF97316)),
  (label: 'Violet', color: Color(0xFF8B5CF6)),
  (label: 'Fuchsia', color: Color(0xFFD946EF)),
  (label: 'Cyan', color: Color(0xFF06B6D4)),
  (label: 'Slate', color: Color(0xFF64748B)),
];

/// Resolves a [libraryAccentPresets] index to a concrete color, falling back
/// to [themeDefault] for the "Theme" preset so it keeps tracking the app's
/// current light/dark accent automatically. Shared by the folder icon, the
/// "NEW" badge, and their swatch pickers in the menu sheet.
Color resolveLibraryAccent(int index, Color themeDefault) =>
    libraryAccentPresets[index.clamp(0, libraryAccentPresets.length - 1)]
        .color ??
    themeDefault;

class LibraryAppearance {
  final int folderIconColorIndex;
  final int newBadgeColorIndex;

  const LibraryAppearance({
    this.folderIconColorIndex = 0,
    this.newBadgeColorIndex = 0,
  });

  LibraryAppearance copyWith({
    int? folderIconColorIndex,
    int? newBadgeColorIndex,
  }) =>
      LibraryAppearance(
        folderIconColorIndex:
            folderIconColorIndex ?? this.folderIconColorIndex,
        newBadgeColorIndex: newBadgeColorIndex ?? this.newBadgeColorIndex,
      );
}

final libraryAppearanceProvider =
    StateNotifierProvider<LibraryAppearanceNotifier, LibraryAppearance>((ref) {
  return LibraryAppearanceNotifier();
});

class LibraryAppearanceNotifier extends StateNotifier<LibraryAppearance> {
  // Seed from the synchronously-cached values (warmed by preload() in main) so
  // the saved colors apply on the first frame — no flash of the defaults.
  LibraryAppearanceNotifier() : super(_initial());

  static LibraryAppearance _initial() {
    final prefs = PlayerPreferencesService.instance;
    return LibraryAppearance(
      folderIconColorIndex: prefs.folderIconColorIndexCached,
      newBadgeColorIndex: prefs.newBadgeColorIndexCached,
    );
  }

  void setFolderIconColorIndex(int index) {
    state = state.copyWith(folderIconColorIndex: index);
    PlayerPreferencesService.instance.saveFolderIconColorIndex(index);
  }

  void setNewBadgeColorIndex(int index) {
    state = state.copyWith(newBadgeColorIndex: index);
    PlayerPreferencesService.instance.saveNewBadgeColorIndex(index);
  }
}
