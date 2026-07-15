import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';
import 'data/engines/media_kit_engine.dart';
import 'data/services/player_preferences_service.dart';
import 'data/services/volume_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  VolumeService.instance;
  // Warm persisted prefs (scan mode) before the first frame so the saved
  // library scan mode is applied immediately instead of flashing the default.
  await PlayerPreferencesService.instance.preload();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  // Set edge-to-edge at startup so the status bar and nav bar are never
  // covered by a white system overlay on the first frame.
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  runApp(const ProviderScope(child: VideoPlayerApp()));

  // Initialize the MediaKit fallback in the background after the app has
  // fully launched. This avoids a lag spike if a fallback is needed later,
  // without blocking the critical startup path.
  Future.delayed(const Duration(seconds: 2), () {
    MediaKitEngine.ensureInitializedInBackground();
  });
}
 