import 'dart:async';
import 'dart:io';
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
class ThumbnailService {
  ThumbnailService._() {
    // Eagerly kick off cache-dir init — result is memoized in _cacheDir.
    _cacheDir.ignore();
  }
  static final ThumbnailService instance = ThumbnailService._();

  // ── In-memory resolved cache ──────────────────────────────────────────────
  // Maps videoPath → resolved File (or null for known-failed paths).
  // Populated after first successful disk lookup or generation.
  // Subsequent calls return immediately without any async work.
  final Map<String, File?> _resolved = {};

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
    if (_resolved.containsKey(videoPath)) {
      return Future.value(_resolved[videoPath]);
    }
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

      bytes ??= await VideoThumbnail.thumbnailData(
        video: videoPath,
        imageFormat: ImageFormat.JPEG,
        // FIX #THUMB-FAST: 1 s instead of 3 s — most videos have a valid
        // frame at 1 s, cutting extraction latency by ~2/3 on cold start.
        timeMs: 1000,
        maxWidth: 240,
        quality: 72,
      );

      // Last resort: both the system thumbnail and MediaMetadataRetriever frame
      // extraction failed (e.g. an HEVC the device can't decode in hardware).
      // Decode one frame in software via libmpv — same path that lets the
      // player itself show these videos.
      if (bytes == null || bytes.isEmpty) {
        bytes = await SoftwareProbeService.instance.grabThumbnail(videoPath);
      }

      if (bytes == null || bytes.isEmpty) {
        _resolved[videoPath] = null;
        return null;
      }

      await cacheFile.writeAsBytes(bytes, flush: true);
      _resolved[videoPath] = cacheFile;
      return cacheFile;
    } catch (_) {
      _resolved[videoPath] = null;
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

  /// Clears all cached thumbnails from disk and the in-memory resolved map.
  Future<void> clearCache() async {
    _resolved.clear();
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
