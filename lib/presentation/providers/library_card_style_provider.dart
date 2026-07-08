import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_video_player/data/services/player_preferences_service.dart';

/// Visual material used for the folder/video cards in the library. [standard]
/// is the default opaque surface; [tinted] gives them a translucent
/// glass look (subtle top sheen + hairline edge) matching the player's tint
/// controls. User-selectable in the Settings sheet.
enum LibraryCardStyle { standard, tinted }

final cardStyleProvider =
    StateNotifierProvider<CardStyleNotifier, LibraryCardStyle>((ref) {
  return CardStyleNotifier();
});

class CardStyleNotifier extends StateNotifier<LibraryCardStyle> {
  CardStyleNotifier()
      : super(PlayerPreferencesService.instance.cardTintedCached
            ? LibraryCardStyle.tinted
            : LibraryCardStyle.standard);

  bool get isTinted => state == LibraryCardStyle.tinted;

  Future<void> setTinted(bool tinted) async {
    state = tinted ? LibraryCardStyle.tinted : LibraryCardStyle.standard;
    await PlayerPreferencesService.instance.saveCardTinted(tinted);
  }

  Future<void> toggle() => setTinted(!isTinted);
}
