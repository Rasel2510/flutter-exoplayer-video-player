import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import '../core/utils/cache_key.dart';
import 'media_store_service.dart';
import 'software_probe_service.dart';

/// Generates and caches video thumbnails to disk.
///
/// FIX #THUMB-FAST: Added _resolved in-memory map — paths already generated
/// this session return synchronously-fast without re-awaiting _cacheDir or
/// hitting the filesystem again.
/// FIX #THUMB-INIT: _cacheDir is eagerly initialized at construction so the
/// first getThumbnail call doesn't pay the getTemporaryDirectory() cost.
final class ThumbnailService {
  ThumbnailService._() {
    // Eagerly kick off cache-dir init — result is memoized in _cacheDir.
    _cacheDir.ignore();
  }
  static final ThumbnailService instance = ThumbnailService._();

  // ── In-memory resolved cache ──────────────────────────────────────────────
  // Maps videoPath → resolved File. Populated after first successful disk
  // lookup or generation. Subsequent calls return immediately without any
  // async work. Successes only — failures live in _failures with a cooldown.
  final Map<String, File> _resolved = {};

  // ── Failure tracking ──────────────────────────────────────────────────────
  // A failed generation is retried after a cooldown instead of being cached as
  // a permanent null: the software probe can lose a one-off race (e.g. time
  // out while the same file is busy playing in the fallback engine), and one
  // lost race shouldn't blank that video's thumbnail for the whole session.
  static const Duration _kRetryCooldown = Duration(seconds: 45);
  static const int _kMaxAttempts = 4;
  final Map<String, ({int attempts, DateTime lastTry})> _failures = {};

  bool _failureBlocked(String videoPath) {
    final f = _failures[videoPath];
    if (f == null) return false;
    if (f.attempts >= _kMaxAttempts) return true;
    return DateTime.now().difference(f.lastTry) < _kRetryCooldown;
  }

  void _recordFailure(String videoPath) {
    final f = _failures[videoPath];
    _failures[videoPath] =
        (attempts: (f?.attempts ?? 0) + 1, lastTry: DateTime.now());
  }

  // ── Concurrency semaphore ─────────────────────────────────────────────────
  static const int _kMaxConcurrent = 6;
  int _activeCount = 0;
  final List<Completer<void>> _waiters = [];

  Future<void> _acquire() async {
    if (_activeCount < _kMaxConcurrent) {
      _activeCount++;
      return;
    }
    final completer = Completer<void>();
    _waiters.add(completer);
    await completer.future;
  }

  void _release() {
    if (_waiters.isNotEmpty) {
      _waiters.removeAt(0).complete();
    } else {
      _activeCount--;
    }
  }

  // ── Late-arrival notifications ────────────────────────────────────────────
  // Fired when a thumbnail becomes available for a path that may already have
  // been reported as failed — e.g. harvested from the playing fallback engine
  // after the library list gave up. List screens stay mounted beneath the
  // player route, so their widgets listen to this to repaint in place.
  final _updates = StreamController<String>.broadcast();
  Stream<String> get updates => _updates.stream;

  // ── In-flight dedup ───────────────────────────────────────────────────────
  final Map<String, Future<File?>> _inFlight = {};

  // Eagerly initialized — avoids getTemporaryDirectory() cost on first call.
  late final Future<Directory> _cacheDir = _initCacheDir();

  static Future<Directory> _initCacheDir() async {
    final base = await getApplicationSupportDirectory();
    final dir = Directory(p.join(base.path, 'vid_thumbs'));
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  Future<File?> getThumbnail(String videoPath) {
    // Fast path: already resolved this session — return immediately.
    final resolved = _resolved[videoPath];
    if (resolved != null) return Future.value(resolved);
    // Known-failed and still inside the cooldown (or out of attempts).
    if (_failureBlocked(videoPath)) return Future.value(null);
    return _inFlight.putIfAbsent(videoPath, () => _generate(videoPath));
  }

  Future<File?> _generate(String videoPath) async {
    await _acquire();
    try {
      final cacheFile = await _cacheFileFor(videoPath);

      if (await cacheFile.exists()) {
        _resolved[videoPath] = cacheFile;
        return cacheFile;
      }

      // Fast path: reuse the system's pre-generated thumbnail for MediaStore-
      // indexed videos (Camera/Downloads/etc.) instead of decoding a frame.
      // Returns null for .nomedia videos (WhatsApp) → falls through to extract.
      var bytes = await MediaStoreService.thumbnailBytes(videoPath, 240, 240);

      if (bytes == null || bytes.isEmpty) {
        try {
          bytes = await VideoThumbnail.thumbnailData(
            video: videoPath,
            imageFormat: ImageFormat.JPEG,
            // FIX #THUMB-FAST: 1 s instead of 3 s — most videos have a valid
            // frame at 1 s, cutting extraction latency by ~2/3 on cold start.
            timeMs: 1000,
            maxWidth: 240,
            quality: 72,
          );
        } catch (_) {
          // MediaMetadataRetriever THROWS (rather than returning null) for
          // codecs it can't decode — e.g. 10-bit HEVC. Must fall through to
          // the software probe below, not abort the whole waterfall.
          bytes = null;
        }
      }

      // Last resort: both the system thumbnail and MediaMetadataRetriever frame
      // extraction failed (e.g. an HEVC the device can't decode in hardware).
      // Decode one frame in software via libmpv — same path that lets the
      // player itself show these videos.
      if (bytes == null || bytes.isEmpty) {
        try {
          bytes = await SoftwareProbeService.instance.grabThumbnail(videoPath);
        } catch (_) {
          bytes = null;
        }
      }

      if (bytes == null || bytes.isEmpty) {
        _recordFailure(videoPath);
        return null;
      }

      await cacheFile.writeAsBytes(bytes, flush: true);
      _resolved[videoPath] = cacheFile;
      _failures.remove(videoPath);
      return cacheFile;
    } catch (_) {
      _recordFailure(videoPath);
      return null;
    } finally {
      _release();
      _inFlight.remove(videoPath);
    }
  }

  Future<File> _cacheFileFor(String videoPath) async {
    final dir = await _cacheDir;
    final sanitised = CacheKey.sanitise(videoPath);
    return File(p.join(dir.path, '$sanitised.jpg'));
  }

  /// Whether a thumbnail for [videoPath] is already available (memory or disk)
  /// WITHOUT triggering generation.
  Future<bool> hasCached(String videoPath) async {
    if (_resolved.containsKey(videoPath)) return true;
    try {
      return await (await _cacheFileFor(videoPath)).exists();
    } catch (_) {
      return false;
    }
  }

  /// Stores externally captured [bytes] as [videoPath]'s cached thumbnail —
  /// used by the player to reuse a frame grabbed from the already-playing
  /// software engine for files whose codec the native extractors can't decode,
  /// instead of opening a second software decoder on the same file.
  Future<File?> storeThumbnailBytes(String videoPath, Uint8List bytes) async {
    if (bytes.isEmpty) return null;
    try {
      final cacheFile = await _cacheFileFor(videoPath);
      await cacheFile.writeAsBytes(bytes, flush: true);
      _resolved[videoPath] = cacheFile;
      _failures.remove(videoPath);
      _updates.add(videoPath);
      return cacheFile;
    } catch (_) {
      return null;
    }
  }

  /// Clears all cached thumbnails from disk and the in-memory resolved map.
  Future<void> clearCache() async {
    _resolved.clear();
    _failures.clear();
    try {
      final dir = await _cacheDir;
      if (await dir.exists()) {
        await for (final f in dir.list()) {
          if (f is File) await f.delete();
        }
      }
    } catch (_) {}
  }

  /// Removes the cached thumbnail for a single video from memory and disk.
  Future<void> removeThumbnail(String videoPath) async {
    _resolved.remove(videoPath);
    _failures.remove(videoPath);
    _inFlight.remove(videoPath);
    try {
      final cacheFile = await _cacheFileFor(videoPath);
      if (await cacheFile.exists()) await cacheFile.delete();
    } catch (_) {}
  }

  /// Moves a cached thumbnail from [oldPath] to [newPath] — used when a video
  /// file is renamed on disk, so the thumbnail doesn't need to regenerate.
  Future<void> rename(String oldPath, String newPath) async {
    final resolved = _resolved.remove(oldPath);
    _failures.remove(oldPath);
    _inFlight.remove(oldPath);
    try {
      final oldFile = await _cacheFileFor(oldPath);
      if (await oldFile.exists()) {
        final newFile = await _cacheFileFor(newPath);
        _resolved[newPath] = await oldFile.rename(newFile.path);
        return;
      }
    } catch (_) {}
    if (resolved != null) _resolved[newPath] = resolved;
  }
}
