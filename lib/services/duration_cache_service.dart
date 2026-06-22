import 'dart:async';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/utils/cache_key.dart';
import '../engine/exoplayer_engine.dart';
import '../models/video_file.dart';
import 'software_probe_service.dart';

/// Probes and caches video duration via the native MediaMetadataRetriever.
///
/// FIX #DUR-FAST: Added getFromCacheSync / loadCachedDurations for a
/// zero-async fast path: callers populate the UI immediately with every
/// duration already in SharedPreferences, before any Player probes start.
/// FIX #DUR-PROBE: Probe concurrency capped at 2 simultaneous Players
/// (down from unlimited) to reduce memory pressure on large folders.
class DurationCacheService {
  DurationCacheService._();
  static final instance = DurationCacheService._();

  SharedPreferences? _prefs;
  Future<SharedPreferences> get _p async =>
      _prefs ??= await SharedPreferences.getInstance();

  static const _prefix = 'dur_v2_';

  static String _key(String videoPath) => '$_prefix${CacheKey.sanitise(videoPath)}';

  // ── In-memory duration cache (current session) ────────────────────────────
  // Avoids repeated SharedPreferences reads for the same path in one session.
  final Map<String, Duration?> _memCache = {};

  // ── Probe concurrency cap ─────────────────────────────────────────────────
  // At most 2 Player instances open simultaneously so a large folder with
  // many uncached videos doesn't exhaust memory.
  static const int _kMaxProbes = 2;
  int _activeProbes = 0;
  final List<Completer<void>> _probeWaiters = [];

  Future<void> _acquireProbeSlot() async {
    if (_activeProbes < _kMaxProbes) { _activeProbes++; return; }
    final c = Completer<void>();
    _probeWaiters.add(c);
    await c.future;
  }

  void _releaseProbeSlot() {
    if (_probeWaiters.isNotEmpty) {
      _probeWaiters.removeAt(0).complete();
    } else {
      _activeProbes--;
    }
  }

  // ── Probe dedup ───────────────────────────────────────────────────────────
  final Map<String, Future<Duration?>> _probeInFlight = {};

  // ── Seed from a known source ──────────────────────────────────────────────

  /// Seeds the in-memory cache with durations already known from another source
  /// — chiefly the MediaStore query, which returns DURATION for every indexed
  /// video. Seeding here means those videos resolve instantly via
  /// [loadCachedDurations] / [getFromCacheSync] and never trigger the
  /// heavyweight [Player] probe in [_probe].
  ///
  /// Only fills empty or previously-failed (null) entries, so a value that was
  /// actually probed or persisted is never overwritten. Pure in-memory, no I/O.
  void seedDurations(Iterable<VideoFile> videos) {
    for (final v in videos) {
      final d = v.duration;
      if (d == null || d <= Duration.zero) continue;
      // _memCache[path] is null both when the key is absent and when a prior
      // probe failed — fill both, but leave a real cached duration intact.
      if (_memCache[v.path] == null) _memCache[v.path] = d;
    }
  }

  // ── Fast synchronous read ─────────────────────────────────────────────────

  /// Returns cached duration synchronously if prefs are already loaded.
  /// Returns null otherwise — caller should fall back to getDuration().
  Duration? getFromCacheSync(String videoPath) {
    if (_memCache.containsKey(videoPath)) return _memCache[videoPath];
    final prefs = _prefs;
    if (prefs == null) return null;
    final ms = prefs.getInt(_key(videoPath));
    if (ms != null && ms > 0) {
      final d = Duration(milliseconds: ms);
      _memCache[videoPath] = d;
      return d;
    }
    return null;
  }

  /// Loads all cached durations for a list of paths in a single async call.
  /// Returns a map of path → Duration for every path with a cached value.
  /// Use on screen open to pre-populate the UI before any probing starts.
  Future<Map<String, Duration>> loadCachedDurations(List<String> paths) async {
    final prefs = await _p;
    final result = <String, Duration>{};
    for (final path in paths) {
      if (_memCache.containsKey(path)) {
        final d = _memCache[path];
        if (d != null) result[path] = d;
        continue;
      }
      final ms = prefs.getInt(_key(path));
      if (ms != null && ms > 0) {
        final d = Duration(milliseconds: ms);
        _memCache[path] = d;
        result[path] = d;
      }
    }
    return result;
  }

  /// Returns cached duration, or probes the file if not cached yet.
  Future<Duration?> getDuration(String videoPath) async {
    if (_memCache.containsKey(videoPath)) return _memCache[videoPath];
    final prefs = await _p;
    final cached = prefs.getInt(_key(videoPath));
    if (cached != null && cached > 0) {
      final d = Duration(milliseconds: cached);
      _memCache[videoPath] = d;
      return d;
    }
    return _probeDeduped(videoPath);
  }

  Future<Duration?> _probeDeduped(String videoPath) {
    return _probeInFlight.putIfAbsent(
      videoPath,
      () => _probe(videoPath).whenComplete(() => _probeInFlight.remove(videoPath)),
    );
  }

  Future<Duration?> _probe(String videoPath) async {
    if (!File(videoPath).existsSync()) return null;
    await _acquireProbeSlot();
    try {
      // Native MediaMetadataRetriever read — reads only the container header,
      // never opening a decoder or audio output, so it can't contend with
      // playback the way the media_kit Player probe could.
      var result = await ExoPlayerEngine.probe(videoPath);
      // Fallback: some files (e.g. certain HEVC) can't be opened by
      // MediaMetadataRetriever at all, so it returns null. Read the duration in
      // software via libmpv, which demuxes the container regardless of codec.
      result ??= await SoftwareProbeService.instance.probeDuration(videoPath);
      if (result != null && result > Duration.zero) {
        _memCache[videoPath] = result;
        await _cache(videoPath, result);
      }
      return result;
    } catch (_) {
      return null;
    } finally {
      _releaseProbeSlot();
    }
  }

  Future<void> _cache(String path, Duration d) async {
    await (await _p).setInt(_key(path), d.inMilliseconds);
  }

  Future<void> saveDuration(String videoPath, Duration duration) async {
    if (duration <= Duration.zero) return;
    _memCache[videoPath] = duration;
    await _cache(videoPath, duration);
  }

  /// Removes the cached duration for a single video from memory and disk.
  Future<void> removeDuration(String videoPath) async {
    _memCache.remove(videoPath);
    _probeInFlight.remove(videoPath);
    try {
      await (await _p).remove(_key(videoPath));
    } catch (_) {}
  }

  /// Moves a cached duration from [oldPath] to [newPath] — used when a video
  /// file is renamed on disk, so it doesn't need to be re-probed. Never throws,
  /// and only drops the old key once the new one is written — so a failed write
  /// leaves the cache intact instead of losing the duration entirely.
  Future<void> rename(String oldPath, String newPath) async {
    try {
      final p = await _p;
      final ms = p.getInt(_key(oldPath));
      if (ms != null) {
        await p.setInt(_key(newPath), ms); // write new first
        _memCache[newPath] = Duration(milliseconds: ms);
        _memCache.remove(oldPath);
        _probeInFlight.remove(oldPath);
        await p.remove(_key(oldPath)); // only drop old after new succeeded
      } else {
        final cached = _memCache.remove(oldPath);
        if (cached != null) _memCache[newPath] = cached;
        _probeInFlight.remove(oldPath);
      }
    } catch (_) {}
  }

  Future<List<VideoFile>> enrichAll(List<VideoFile> files) async {
    final p = await _p;
    return files.map((vf) {
      if (vf.duration != null) return vf;
      final ms = p.getInt(_key(vf.path));
      if (ms != null && ms > 0) {
        return vf.copyWith(duration: Duration(milliseconds: ms));
      }
      return vf;
    }).toList();
  }
}
