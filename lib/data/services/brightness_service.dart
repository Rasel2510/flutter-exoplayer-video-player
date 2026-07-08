import 'package:shared_preferences/shared_preferences.dart';

/// Persists and restores the user's preferred screen brightness.
/// SharedPreferences is cached after the first access.
class BrightnessService {
  BrightnessService._();
  static final instance = BrightnessService._();

  SharedPreferences? _prefs;
  Future<SharedPreferences> get _p async =>
      _prefs ??= await SharedPreferences.getInstance();

  static const _key = 'player_brightness';

  Future<double?> getBrightness() async {
    try {
      final p = await _p;
      return p.containsKey(_key) ? p.getDouble(_key) : null;
    } catch (_) { return null; }
  }

  Future<void> saveBrightness(double brightness) async {
    try { await (await _p).setDouble(_key, brightness); } catch (_) {}
  }
}
