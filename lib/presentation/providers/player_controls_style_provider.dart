import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_video_player/data/services/player_preferences_service.dart';

/// Visual material used for the player's on-screen control surfaces.
/// [tint] is the default black-glass look (a translucent dark fill); [frosted]
/// renders a real backdrop blur of the video behind each control (iOS-style
/// frosted glass). User-selectable in the Settings sheet.
enum PlayerControlsStyle { tint, frosted }

final controlsStyleProvider =
    StateNotifierProvider<ControlsStyleNotifier, PlayerControlsStyle>((ref) {
  return ControlsStyleNotifier();
});

class ControlsStyleNotifier extends StateNotifier<PlayerControlsStyle> {
  ControlsStyleNotifier()
      : super(PlayerPreferencesService.instance.controlsFrostedCached
            ? PlayerControlsStyle.frosted
            : PlayerControlsStyle.tint);

  bool get isFrosted => state == PlayerControlsStyle.frosted;

  Future<void> setFrosted(bool frosted) async {
    state = frosted ? PlayerControlsStyle.frosted : PlayerControlsStyle.tint;
    await PlayerPreferencesService.instance.saveControlsFrosted(frosted);
  }

  Future<void> toggle() => setFrosted(!isFrosted);
}
