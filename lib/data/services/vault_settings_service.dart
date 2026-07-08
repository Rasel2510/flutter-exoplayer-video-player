import 'package:shared_preferences/shared_preferences.dart';

/// Quick-pick presets for the vault's auto-lock duration. The stored value
/// itself is just raw seconds (see [VaultSettingsService]) — these are only
/// shortcuts the picker UI offers; the user can also enter any custom
/// duration that won't match one of these.
enum VaultAutoLockDuration {
  immediate(0, 'Immediately'),
  seconds30(30, '30 seconds'),
  minute1(60, '1 minute'),
  minutes5(300, '5 minutes'),
  minutes15(900, '15 minutes'),
  never(-1, 'Never');

  final int seconds;
  final String label;
  const VaultAutoLockDuration(this.seconds, this.label);

  /// The preset matching an exact seconds value, or null if it's a custom
  /// duration the user typed in themselves.
  static VaultAutoLockDuration? matchSeconds(int seconds) {
    for (final d in values) {
      if (d.seconds == seconds) return d;
    }
    return null;
  }
}

/// Human-readable label for any seconds value, not just the presets in
/// [VaultAutoLockDuration] — used by the custom-time row and confirmation
/// messages.
String formatAutoLockSeconds(int seconds) {
  if (seconds < 0) return 'Never';
  if (seconds == 0) return 'Immediately';
  if (seconds < 60) return '$seconds second${seconds == 1 ? '' : 's'}';
  final minutes = seconds / 60;
  final rounded = minutes.round();
  if (minutes == rounded) return '$rounded minute${rounded == 1 ? '' : 's'}';
  return '${minutes.toStringAsFixed(1)} minutes';
}

class VaultSettingsService {
  VaultSettingsService._();
  static final VaultSettingsService instance = VaultSettingsService._();

  static const _autoLockKey = 'vault_auto_lock_seconds_v1';
  static const _defaultSeconds = 60;

  SharedPreferences? _prefs;
  Future<SharedPreferences> get _p async =>
      _prefs ??= await SharedPreferences.getInstance();

  /// Raw auto-lock duration in seconds; -1 means "never". Not limited to
  /// [VaultAutoLockDuration]'s presets — the user can set any value via the
  /// custom-time entry in the auto-lock sheet.
  Future<int> getAutoLockSeconds() async {
    final p = await _p;
    return p.getInt(_autoLockKey) ?? _defaultSeconds;
  }

  Future<void> setAutoLockSeconds(int seconds) async {
    final p = await _p;
    await p.setInt(_autoLockKey, seconds);
  }
}
