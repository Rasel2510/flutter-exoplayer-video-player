import 'package:flutter/services.dart';
import '../core/constants.dart';

/// Manages Android media session (lock screen controls) via platform channel.
class MediaSessionService {
  // FIX #14: use the shared constant instead of a duplicate string literal
  static const _channel = MethodChannel(AppConstants.mediaSessionChannel);

  /// Registers the handler for lock-screen / notification button presses
  /// (play, pause, next, previous) and scrubber seeks dispatched from
  /// MainActivity's MediaSessionCompat.Callback. Overwrites any previous
  /// handler — the channel only ever has one consumer (the active player).
  static void setActionHandler({
    required void Function(String action) onAction,
    required void Function(Duration position) onSeek,
    void Function(bool isPip)? onPipModeChanged,
  }) {
    _channel.setMethodCallHandler((call) async {
      switch (call.method) {
        case 'onMediaAction':
          onAction(call.arguments as String);
        case 'onMediaSeek':
          onSeek(Duration(milliseconds: call.arguments as int));
        case 'onPipModeChanged':
          onPipModeChanged?.call(call.arguments as bool);
      }
    });
  }

  static Future<void> setMetadata({
    required String title,
    required Duration duration,
    String? artPath,
  }) async {
    try {
      await _channel.invokeMethod('setMetadata', {
        'title': title,
        'duration': duration.inMilliseconds,
        // Absolute path to the video's thumbnail jpeg, shown as lock-screen
        // album art. Null when no thumbnail has been generated yet.
        'artPath': artPath,
      });
    } catch (_) {}
  }

  static Future<void> setPlaybackState({
    required bool isPlaying,
    required Duration position,
    required double speed,
  }) async {
    try {
      await _channel.invokeMethod('setPlaybackState', {
        'isPlaying': isPlaying,
        'position': position.inMilliseconds,
        'speed': speed,
      });
    } catch (_) {}
  }

  static Future<void> release() async {
    try {
      await _channel.invokeMethod('release');
    } catch (_) {}
  }

  /// Sends the app to the background (like the Home button) instead of letting
  /// the back button finish the activity — keeps playback alive in audio mode.
  static Future<void> moveTaskToBack() async {
    try {
      await _channel.invokeMethod('moveTaskToBack');
    } catch (_) {}
  }

  /// Enters Android Picture-in-Picture with the given video aspect ratio.
  static Future<void> enterPip({int width = 16, int height = 9}) async {
    try {
      await _channel.invokeMethod('enterPip', {
        'width': width,
        'height': height,
      });
    } catch (_) {}
  }

  /// Toggles `FLAG_SECURE` on the activity window — blocks screenshots and
  /// screen recording, and blanks the app's recent-apps thumbnail. Used to
  /// shield the Secure Vault's contents from anything outside the app.
  static Future<void> setSecureScreen(bool enabled) async {
    try {
      await _channel.invokeMethod('setSecureScreen', {'enabled': enabled});
    } catch (_) {}
  }
}
