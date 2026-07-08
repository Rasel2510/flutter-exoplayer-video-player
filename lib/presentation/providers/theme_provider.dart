import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_video_player/data/services/player_preferences_service.dart';

final themeProvider = StateNotifierProvider<ThemeNotifier, ThemeMode>((ref) {
  return ThemeNotifier();
});

class ThemeNotifier extends StateNotifier<ThemeMode> {
  ThemeNotifier() : super(ThemeMode.system) {
    _load();
  }

  Future<void> _load() async {
    final idx = await PlayerPreferencesService.instance.loadThemeModeIndex();
    state = ThemeMode.values[idx.clamp(0, ThemeMode.values.length - 1)];
  }

  Future<void> setTheme(ThemeMode mode) async {
    state = mode;
    await PlayerPreferencesService.instance.saveThemeModeIndex(mode.index);
  }

  Future<void> toggleTheme() async {
    if (state == ThemeMode.dark) {
      await setTheme(ThemeMode.light);
    } else if (state == ThemeMode.light) {
      await setTheme(ThemeMode.system);
    } else {
      await setTheme(ThemeMode.dark);
    }
  }
} 
