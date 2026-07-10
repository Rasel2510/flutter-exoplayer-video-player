import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_video_player/data/services/player_preferences_service.dart';
import 'bool_preference_notifier.dart';

/// Visual material used for the folder/video cards in the library. [standard]
/// is the default opaque surface; [tinted] gives them a translucent
/// glass look (subtle top sheen + hairline edge) matching the player's tint
/// controls. User-selectable in the Settings sheet.
enum LibraryCardStyle { standard, tinted }

final cardStyleProvider = StateNotifierProvider<
    BoolPreferenceNotifier<LibraryCardStyle>, LibraryCardStyle>((ref) {
  return BoolPreferenceNotifier<LibraryCardStyle>(
    initial: PlayerPreferencesService.instance.cardTintedCached,
    fromBool: (v) => v ? LibraryCardStyle.tinted : LibraryCardStyle.standard,
    toBool: (s) => s == LibraryCardStyle.tinted,
    save: PlayerPreferencesService.instance.saveCardTinted,
  );
});
