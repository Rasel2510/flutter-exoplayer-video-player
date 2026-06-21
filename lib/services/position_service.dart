import 'package:shared_preferences/shared_preferences.dart';
import '../core/utils/cache_key.dart';
import 'duration_cache_service.dart';

/// Saves and restores the last playback position for each video file.
class PositionService {
  PositionService._();
  static final PositionService instance = PositionService._();

  // Cached — only one platform channel call per app session.
  SharedPreferences? _prefs;
  Future<SharedPreferences> get _p async =>
      _prefs ??= await SharedPreferences.getInstance();

  static const _prefix    = 'pos_v2_';
  static const _minSaveMs = 5000;
  static const _nearEndMs = 5000;

  static String _key(String videoPath) => '$_prefix${CacheKey.sanitise(videoPath)}';

  Future<void> save(String videoPath, Duration position, Duration duration) async {
    final ms      = position.inMilliseconds;
    final totalMs = duration.inMilliseconds;
    if (totalMs <= 0 || ms < _minSaveMs) return;
    final p = await _p;
    if (totalMs - ms < _nearEndMs) {
      await p.remove(_key(videoPath));
      return;
    }
    // Persist position and duration cache in parallel.
    await Future.wait([
      p.setInt(_key(videoPath), ms),
      DurationCacheService.instance
          .saveDuration(videoPath, Duration(milliseconds: totalMs)),
    ]);
  }

  Future<Duration?> load(String videoPath) async {
    final ms = (await _p).getInt(_key(videoPath));
    if (ms == null || ms < _minSaveMs) return null;
    return Duration(milliseconds: ms);
  }

  Future<void> clear(String videoPath) async {
    await (await _p).remove(_key(videoPath));
  }

  Future<bool> hasSaved(String videoPath) async {
    final ms = (await _p).getInt(_key(videoPath));
    return ms != null && ms >= _minSaveMs;
  }

  /// Moves a saved position from [oldPath] to [newPath] — used when a video
  /// file is renamed on disk, so its resume point isn't lost. Never throws, and
  /// only drops the old key once the new one is written so a failed write keeps
  /// the resume point intact.
  Future<void> rename(String oldPath, String newPath) async {
    try {
      final p = await _p;
      final ms = p.getInt(_key(oldPath));
      if (ms == null) return;
      await p.setInt(_key(newPath), ms); // write new first
      await p.remove(_key(oldPath)); // only drop old after new succeeded
    } catch (_) {}
  }
}
