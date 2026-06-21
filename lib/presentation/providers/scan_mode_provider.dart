import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/player_preferences_service.dart';

/// How the library discovers videos (Android). See [scanModeProvider].
///
/// • [hybrid] — MediaStore (fast + live) plus a background filesystem walk that
///   catches .nomedia folders (WhatsApp, Telegram). Best balance. Default.
/// • [mediaStore] — MediaStore only: fastest and fully live, but won't show
///   WhatsApp/.nomedia videos.
/// • [fileScanner] — recursive filesystem walk only: complete (incl. WhatsApp)
///   but slower and without live updates.
enum LibraryScanMode { hybrid, mediaStore, fileScanner }

extension LibraryScanModeInfo on LibraryScanMode {
  String get label => switch (this) {
        LibraryScanMode.hybrid => 'Hybrid',
        LibraryScanMode.mediaStore => 'MediaStore',
        LibraryScanMode.fileScanner => 'File scanner',
      };

  String get description => switch (this) {
        LibraryScanMode.hybrid =>
          'Fast, live updates, and finds WhatsApp/Telegram videos. Recommended.',
        LibraryScanMode.mediaStore =>
          'Fastest — new videos appear instantly, but WhatsApp/.nomedia videos won\'t show.',
        LibraryScanMode.fileScanner =>
          'Scans every folder, incl. WhatsApp. Complete but slower, no live updates.',
      };
}

final scanModeProvider =
    StateNotifierProvider<ScanModeNotifier, LibraryScanMode>((ref) {
  return ScanModeNotifier();
});

class ScanModeNotifier extends StateNotifier<LibraryScanMode> {
  // Seed from the synchronously-cached value (warmed by preload() in main) so
  // the correct mode is shown on the first frame — no flash of the default.
  ScanModeNotifier() : super(_initial());

  static LibraryScanMode _initial() {
    final idx = PlayerPreferencesService.instance.scanModeIndexCached;
    return LibraryScanMode.values[
        idx.clamp(0, LibraryScanMode.values.length - 1)];
  }

  Future<void> set(LibraryScanMode mode) async {
    if (mode == state) return;
    state = mode;
    await PlayerPreferencesService.instance.saveScanModeIndex(mode.index);
  }
}
