import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';
import 'services/player_preferences_service.dart';
import 'services/volume_service.dart';

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
}
 