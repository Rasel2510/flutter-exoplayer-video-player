/// FIX #14: Single source of truth for the media session method channel name.
/// Previously this string was duplicated in both player_provider.dart and
/// media_session_service.dart — a silent breakage risk if one was edited.
abstract final class AppConstants {
  static const mediaSessionChannel =
      'com.example.flutter_video_player/media_session';

  /// Native MediaStore bridge — fast video index + live ContentObserver
  /// notifications so newly downloaded videos appear without a filesystem scan.
  static const mediaStoreChannel =
      'com.example.flutter_video_player/media_store';

  /// Delivers videos opened from outside the app (VIEW intents / "Open with").
  static const openFileChannel =
      'com.example.flutter_video_player/open_file';
}
