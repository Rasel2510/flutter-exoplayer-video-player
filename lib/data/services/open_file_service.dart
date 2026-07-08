import 'package:flutter/services.dart';
import 'package:flutter_video_player/core/constants.dart';

/// Receives videos opened from outside the app (Android "Open with" / VIEW
/// intents). Used by the home screen to jump straight into the player.
class OpenFileService {
  static const _channel = MethodChannel(AppConstants.openFileChannel);

  /// The video the app was cold-launched with (null if launched normally).
  /// Returns it once, then clears it natively.
  static Future<String?> getInitialFile() async {
    try {
      return await _channel.invokeMethod<String>('getOpenedFile');
    } catch (_) {
      return null;
    }
  }

  /// Registers [onOpen] for videos opened while the app is already running.
  static void setHandler(void Function(String path) onOpen) {
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'onOpenFile' && call.arguments is String) {
        onOpen(call.arguments as String);
      }
    });
  }
}
