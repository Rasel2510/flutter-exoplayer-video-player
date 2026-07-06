import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/player_preferences_service.dart';

final continueWatchingEnabledProvider = StateNotifierProvider<ContinueWatchingEnabledNotifier, bool>((ref) {
  return ContinueWatchingEnabledNotifier();
});

class ContinueWatchingEnabledNotifier extends StateNotifier<bool> {
  ContinueWatchingEnabledNotifier()
      : super(PlayerPreferencesService.instance.continueWatchingEnabledCached);

  Future<void> toggle() async {
    final newValue = !state;
    state = newValue;
    await PlayerPreferencesService.instance.saveContinueWatchingEnabled(newValue);
  }
}
