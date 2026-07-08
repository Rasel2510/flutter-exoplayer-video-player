import 'package:shared_preferences/shared_preferences.dart';

/// Persists per-session player preferences that survive app restarts:
/// fit mode (FIT / CROP / FILL / AUTO), playback speed, and folder sort order.
///
/// SharedPreferences is resolved once and cached — repeated reads/writes
/// are synchronous map lookups after the first await.
class PlayerPreferencesService {
  PlayerPreferencesService._();
  static final PlayerPreferencesService instance = PlayerPreferencesService._();

  // Cached — only one platform channel call across the app lifetime.
  SharedPreferences? _prefs;
  Future<SharedPreferences> get _p async =>
      _prefs ??= await SharedPreferences.getInstance();

  static const _fitModeKey   = 'player_fit_mode_v1';
  static const _speedKey     = 'player_speed_v1';
  static const _sortByKey    = 'folder_sort_by_v1';
  static const _themeModeKey = 'app_theme_mode_v1';
  static const _loopModeKey  = 'player_loop_mode_v1';
  static const _scanModeKey  = 'library_scan_mode_v1';
  static const _subFontSizeKey   = 'subtitle_font_size_v1';
  static const _subColorIndexKey = 'subtitle_color_index_v1';
  static const _subBackgroundKey = 'subtitle_background_v1';
  static const _subBgColorIndexKey = 'subtitle_bg_color_index_v1';
  static const _subFontIndexKey  = 'subtitle_font_index_v1';
  static const _seekIntervalKey  = 'player_seek_interval_v1';
  static const _folderIconColorIndexKey = 'folder_icon_color_index_v1';
  static const _newBadgeColorIndexKey   = 'new_badge_color_index_v1';
  static const _continueWatchingEnabledKey = 'continue_watching_enabled_v1';

  // ── Fit mode ──────────────────────────────────────────────────────────────

  Future<int> loadFitModeIndex() async {
    try { return (await _p).getInt(_fitModeKey) ?? 0; } catch (_) { return 0; }
  }

  Future<void> saveFitModeIndex(int index) async {
    try { await (await _p).setInt(_fitModeKey, index); } catch (_) {}
  }

  // ── Playback speed ─────────────────────────────────────────────────────────

  Future<double> loadSpeed() async {
    try { return (await _p).getDouble(_speedKey) ?? 1.0; } catch (_) { return 1.0; }
  }

  Future<void> saveSpeed(double speed) async {
    try { await (await _p).setDouble(_speedKey, speed); } catch (_) {}
  }

  // ── Folder sort order ──────────────────────────────────────────────────────

  Future<int> loadSortByIndex() async {
    try { return (await _p).getInt(_sortByKey) ?? 0; } catch (_) { return 0; }
  }

  Future<void> saveSortByIndex(int index) async {
    try { await (await _p).setInt(_sortByKey, index); } catch (_) {}
  }

  // ── Theme mode ─────────────────────────────────────────────────────────────

  Future<int> loadThemeModeIndex() async {
    try { return (await _p).getInt(_themeModeKey) ?? 0; } catch (_) { return 0; }
  }

  Future<void> saveThemeModeIndex(int index) async {
    try { await (await _p).setInt(_themeModeKey, index); } catch (_) {}
  }

  // ── Loop mode ──────────────────────────────────────────────────────────────

  Future<int> loadLoopModeIndex() async {
    try { return (await _p).getInt(_loopModeKey) ?? 0; } catch (_) { return 0; }
  }

  Future<void> saveLoopModeIndex(int index) async {
    try { await (await _p).setInt(_loopModeKey, index); } catch (_) {}
  }

  // ── Library scan mode ──────────────────────────────────────────────────────
  // 0 = hybrid (default), 1 = mediaStore, 2 = fileScanner. See LibraryScanMode.

  // Synchronously-readable copy so the UI and the library load can use the saved
  // mode on the very first frame instead of flashing the default while an async
  // read resolves. Populated by [preload] (called in main before runApp) and
  // kept in sync by [saveScanModeIndex].
  int _scanModeIndexCache = 0;
  int get scanModeIndexCached => _scanModeIndexCache;

  /// Warms the SharedPreferences instance and caches the scan-mode index so it
  /// can be read synchronously from the first frame. Call once during startup.
  Future<void> preload() async {
    try {
      final p = await _p;
      _scanModeIndexCache = p.getInt(_scanModeKey) ?? 0;
      _subtitleFontSizeCache = p.getDouble(_subFontSizeKey) ?? 32.0;
      _subtitleColorIndexCache = p.getInt(_subColorIndexKey) ?? 0;
      _subtitleBackgroundCache = p.getBool(_subBackgroundKey) ?? true;
      _subtitleBgColorIndexCache = p.getInt(_subBgColorIndexKey) ?? 0;
      _subtitleFontIndexCache = p.getInt(_subFontIndexKey) ?? 0;
      _seekIntervalCache = p.getInt(_seekIntervalKey) ?? 10;
      _folderIconColorIndexCache = p.getInt(_folderIconColorIndexKey) ?? 0;
      _newBadgeColorIndexCache = p.getInt(_newBadgeColorIndexKey) ?? 0;
      _continueWatchingEnabledCache = p.getBool(_continueWatchingEnabledKey) ?? true;
    } catch (_) {}
  }

  Future<int> loadScanModeIndex() async {
    try {
      final idx = (await _p).getInt(_scanModeKey) ?? 0;
      _scanModeIndexCache = idx;
      return idx;
    } catch (_) {
      return 0;
    }
  }

  Future<void> saveScanModeIndex(int index) async {
    _scanModeIndexCache = index;
    try { await (await _p).setInt(_scanModeKey, index); } catch (_) {}
  }

  // ── Subtitle style (font size / color / background) ───────────────────────
  // Synchronously-readable so the player can apply the saved style on the
  // very first frame instead of flashing the default. Warmed by [preload].

  double _subtitleFontSizeCache = 32.0;
  int _subtitleColorIndexCache = 0;
  bool _subtitleBackgroundCache = true;
  int _subtitleBgColorIndexCache = 0;
  int _subtitleFontIndexCache = 0;

  double get subtitleFontSizeCached => _subtitleFontSizeCache;
  int get subtitleColorIndexCached => _subtitleColorIndexCache;
  bool get subtitleBackgroundCached => _subtitleBackgroundCache;
  int get subtitleBgColorIndexCached => _subtitleBgColorIndexCache;
  int get subtitleFontIndexCached => _subtitleFontIndexCache;

  Future<void> saveSubtitleFontSize(double size) async {
    _subtitleFontSizeCache = size;
    try { await (await _p).setDouble(_subFontSizeKey, size); } catch (_) {}
  }

  Future<void> saveSubtitleColorIndex(int index) async {
    _subtitleColorIndexCache = index;
    try { await (await _p).setInt(_subColorIndexKey, index); } catch (_) {}
  }

  Future<void> saveSubtitleBackground(bool enabled) async {
    _subtitleBackgroundCache = enabled;
    try { await (await _p).setBool(_subBackgroundKey, enabled); } catch (_) {}
  }

  Future<void> saveSubtitleBgColorIndex(int index) async {
    _subtitleBgColorIndexCache = index;
    try { await (await _p).setInt(_subBgColorIndexKey, index); } catch (_) {}
  }

  Future<void> saveSubtitleFontIndex(int index) async {
    _subtitleFontIndexCache = index;
    try { await (await _p).setInt(_subFontIndexKey, index); } catch (_) {}
  }

  // ── Seek interval ─────────────────────────────────────────────────────────

  int _seekIntervalCache = 10;
  int get seekIntervalCached => _seekIntervalCache;

  Future<void> saveSeekInterval(int seconds) async {
    _seekIntervalCache = seconds;
    try { await (await _p).setInt(_seekIntervalKey, seconds); } catch (_) {}
  }

  // ── Continue Watching visibility toggle ───────────────────────────────────

  bool _continueWatchingEnabledCache = true;
  bool get continueWatchingEnabledCached => _continueWatchingEnabledCache;

  Future<void> saveContinueWatchingEnabled(bool enabled) async {
    _continueWatchingEnabledCache = enabled;
    try { await (await _p).setBool(_continueWatchingEnabledKey, enabled); } catch (_) {}
  }

  // ── Library appearance (folder icon color / new-badge color) ──────────────

  int _folderIconColorIndexCache = 0;
  int _newBadgeColorIndexCache = 0;

  int get folderIconColorIndexCached => _folderIconColorIndexCache;
  int get newBadgeColorIndexCached => _newBadgeColorIndexCache;

  Future<void> saveFolderIconColorIndex(int index) async {
    _folderIconColorIndexCache = index;
    try { await (await _p).setInt(_folderIconColorIndexKey, index); } catch (_) {}
  }

  Future<void> saveNewBadgeColorIndex(int index) async {
    _newBadgeColorIndexCache = index;
    try { await (await _p).setInt(_newBadgeColorIndexKey, index); } catch (_) {}
  }
}
