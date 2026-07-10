import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_video_player/data/services/player_preferences_service.dart';
import 'bool_preference_notifier.dart';

/// Visual material used for the player's on-screen control surfaces.
/// [tint] is the default black-glass look (a translucent dark fill); [frosted]
/// renders a real backdrop blur of the video behind each control (iOS-style
/// frosted glass). User-selectable in the Settings sheet.
enum PlayerControlsStyle { tint, frosted }

final controlsStyleProvider = StateNotifierProvider<
    BoolPreferenceNotifier<PlayerControlsStyle>, PlayerControlsStyle>((ref) {
  return BoolPreferenceNotifier<PlayerControlsStyle>(
    initial: PlayerPreferencesService.instance.controlsFrostedCached,
    fromBool: (v) => v ? PlayerControlsStyle.frosted : PlayerControlsStyle.tint,
    toBool: (s) => s == PlayerControlsStyle.frosted,
    save: PlayerPreferencesService.instance.saveControlsFrosted,
  );
});
