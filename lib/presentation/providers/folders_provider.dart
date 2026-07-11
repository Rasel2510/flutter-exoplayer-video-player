import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_video_player/data/models/video_file.dart';
import 'package:flutter_video_player/data/models/video_folder.dart';
import 'package:flutter_video_player/data/services/duration_cache_service.dart';
import 'package:flutter_video_player/data/services/folder_scanner.dart';
import 'package:flutter_video_player/data/services/media_store_service.dart';
import 'package:flutter_video_player/data/services/player_preferences_service.dart';
import 'scan_mode_provider.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'folders_provider.freezed.dart';

// ── Storage root discovery ────────────────────────────────────────────────────

SharedPreferences? _cachedPrefs;
Future<SharedPreferences> get _p async =>
    _cachedPrefs ??= await SharedPreferences.getInstance();

class _ChangedSignal implements Exception {
  const _ChangedSignal();
}

List<String> _discoverStorageRoots() {
  final roots = <String>[];
  try {
    final storageDir = Directory('/storage');
    if (!storageDir.existsSync()) return ['/storage/emulated/0'];

    for (final entity in storageDir.listSync(followLinks: false)) {
      if (entity is! Directory) continue;
      final name = entity.path.split('/').last;
      if (name == 'self') continue;

      if (name == 'emulated') {
        final internal = Directory('${entity.path}/0');
        if (internal.existsSync()) roots.add(internal.path);
      } else {
        if (entity.existsSync()) roots.add(entity.path);
      }
    }
  } catch (_) {}

  if (roots.isEmpty) roots.add('/storage/emulated/0');
  return roots;
}

// ── Cache helpers ─────────────────────────────────────────────────────────────

const _cacheKey = 'folder_scan_cache_v2';
const _cacheTimeKey = 'folder_scan_time_v2';

// FIX #TTL: Removed 12-hour TTL — cache is now permanent and only replaced
// when a real filesystem change is detected by the background snapshot check.

const _snapshotKey = 'folder_scan_snapshot_v2';
const _seenPathsKey = 'folder_scan_seen_paths_v1';
const _seenPathsInitKey = 'folder_scan_seen_paths_init_v1';

Future<Set<String>?> _loadSeenPaths() async {
  try {
    final prefs = await _p;
    if (prefs.getBool(_seenPathsInitKey) != true) return null;
    final raw = prefs.getString(_seenPathsKey);
    if (raw == null) return {};
    final list = jsonDecode(raw) as List<dynamic>;
    return list.cast<String>().toSet();
  } catch (_) {
    return null;
  }
}

Future<void> _saveSeenPaths(Set<String> paths) async {
  try {
    final prefs = await _p;
    // FIX #3: Write the init flag FIRST. If the app is killed between the two
    // writes, next open reads an empty seenPaths (safe) rather than treating
    // the library as uninitialised and badging every video as new.
    await prefs.setBool(_seenPathsInitKey, true);
    await prefs.setString(_seenPathsKey, jsonEncode(paths.toList()));
  } catch (_) {}
}

// FIX #TTL: No TTL check — always return cached data if present.
Future<List<VideoFolder>?> _loadCache() async {
  try {
    final prefs = await _p;
    final raw = prefs.getString(_cacheKey);
    if (raw == null) return null;
    final list = jsonDecode(raw) as List<dynamic>;
    return list.map((e) => _folderFromMap(e as Map<String, dynamic>)).toList();
  } catch (_) {
    return null;
  }
}

// FIX #ATOMIC: cache and snapshot are always written together.
Future<void> _saveCache(List<VideoFolder> folders) async {
  try {
    final prefs = await _p;
    await prefs.setInt(_cacheTimeKey, DateTime.now().millisecondsSinceEpoch);
    await prefs.setString(
        _cacheKey, jsonEncode(folders.map(_folderToMap).toList()));
    final snapshot = {for (final f in folders) f.path: f.videoCount};
    await prefs.setString(_snapshotKey, jsonEncode(snapshot));
  } catch (_) {}
}

Future<bool> _hasNewContent() async {
  try {
    final prefs = await _p;
    final rawSnapshot = prefs.getString(_snapshotKey);
    if (rawSnapshot == null) return true;

    final oldSnapshot = Map<String, int>.from((jsonDecode(rawSnapshot) as Map)
        .map((k, v) => MapEntry(k as String, v as int)));

    final roots = _discoverStorageRoots();

    final port = ReceivePort();
    await Isolate.spawn(
      _isolateQuickCheck,
      _QuickCheckData(roots, oldSnapshot, port.sendPort),
      // A killed isolate still delivers onExit's null, so port.first can't
      // hang forever waiting on a result that will never come.
      onExit: port.sendPort,
    );
    final first = await port.first;
    // Non-bool means the isolate died without answering — rescan to be safe.
    return first is bool ? first : true;
  } catch (_) {
    return true;
  }
}

// ── Isolate entry point ───────────────────────────────────────────────────────

class _QuickCheckData {
  final List<String> roots;
  final Map<String, int> snapshot;
  final SendPort sendPort;
  _QuickCheckData(this.roots, this.snapshot, this.sendPort);
}

void _isolateQuickCheck(_QuickCheckData data) {
  try {
    final seen = <String>{};
    for (final root in data.roots) {
      _quickScanSync(Directory(root), data.snapshot, seen);
    }
    // Additions and count changes throw _ChangedSignal during the walk, but a
    // folder that was deleted outright (or lost every video) is simply never
    // visited — compare against the snapshot keys to catch deletions too.
    for (final path in data.snapshot.keys) {
      if (!seen.contains(path)) {
        data.sendPort.send(true);
        return;
      }
    }
    data.sendPort.send(false);
  } catch (e) {
    data.sendPort.send(true);
  }
}

void _quickScanSync(
    Directory dir, Map<String, int> snapshot, Set<String> seen) {
  try {
    int videoCount = 0;
    final subs = <Directory>[];

    for (final entity in dir.listSync(followLinks: false)) {
      if (entity is File && VideoFile.isVideoFile(entity.path)) {
        videoCount++;
      } else if (entity is Directory) {
        final name = entity.path.split('/').last;
        if (!name.startsWith('.')) subs.add(entity);
      }
    }

    if (videoCount > 0) {
      seen.add(dir.path);
      final cached = snapshot[dir.path];
      if (cached == null || cached != videoCount) throw const _ChangedSignal();
    }

    for (final sub in subs) {
      _quickScanSync(sub, snapshot, seen);
    }
  } on _ChangedSignal {
    rethrow;
  } catch (_) {}
}

// ── FIX #4: Prune stale paths ─────────────────────────────────────────────────
// seenPaths only ever grows — deleted videos leave their paths in storage
// forever. Intersect with the current scan result to keep the JSON lean.
Set<String> _pruneSeenPaths(Set<String> seen, Set<String> allCurrentPaths) =>
    seen.intersection(allCurrentPaths);

Set<String> pruneNewPathsForRemovedVideos({
  required Set<String> currentNewPaths,
  required List<VideoFolder> folders,
  required List<String> removedPaths,
}) {
  final updated = Set<String>.from(currentNewPaths)
    ..removeAll(removedPaths.toSet());

  for (final folder in folders) {
    final folderStillNew = folder.videos.any((v) => updated.contains(v.path));
    if (!folderStillNew) {
      updated.remove(folder.path);
    }
  }

  return updated;
}

Map<String, dynamic> _folderToMap(VideoFolder f) => {
      'path': f.path,
      'videos': f.videos
          .map((v) => {
                'path': v.path,
                'name': v.name,
                'size': v.size,
                'modified': v.modified.millisecondsSinceEpoch,
              })
          .toList(),
    };

VideoFolder _folderFromMap(Map<String, dynamic> m) => VideoFolder(
      path: m['path'] as String,
      videos: (m['videos'] as List<dynamic>)
          .map((v) => VideoFile(
                path: v['path'] as String,
                name: v['name'] as String,
                size: v['size'] as int,
                modified:
                    DateTime.fromMillisecondsSinceEpoch(v['modified'] as int),
              ))
          .toList(),
    );

// ── State ─────────────────────────────────────────────────────────────────────

@freezed
class FoldersState with _$FoldersState {
  const factory FoldersState({
    @Default([]) List<VideoFolder> folders,
    @Default(false) bool isScanning,
    @Default(0) int scanProgress,
    @Default(false) bool fromCache,
    @Default([]) List<String> storageRoots,
    @Default({}) Set<String> newPaths,
  }) = _FoldersState;
}

// ── Notifier ──────────────────────────────────────────────────────────────────

class FoldersNotifier extends Notifier<FoldersState> {
  final Set<String> _sessionSeenPaths = {};

  // ── MediaStore (Android) live-refresh state ──
  // True once the native ContentObserver is registered.
  bool _watchingMediaStore = false;
  // Guards against overlapping refreshes; _refreshPending re-runs once if a
  // change arrives mid-refresh so we never miss the latest state.
  bool _refreshing = false;
  bool _refreshPending = false;
  // Coalesces the burst of ContentObserver callbacks a single file op emits.
  Timer? _refreshDebounce;

  // The mode in effect for the current results — cached so the live observer
  // can ignore changes when the user has switched to pure file-scanner mode.
  LibraryScanMode _scanMode = LibraryScanMode.hybrid;

  // Battery: the recursive filesystem walk is the only non-trivial cost here,
  // and a resume fires it. Skip it if we walked within this window (unless the
  // caller forces it), so flicking back into the app doesn't re-walk storage.
  DateTime? _lastFilesystemScan;
  static const _minRescanGap = Duration(minutes: 2);

  // MediaStore is Android-only. Off Android we always use the file scanner.
  // Reads the synchronously-cached index (warmed by preload() in main) so the
  // first load already uses the saved mode — no flash of hybrid on cold start.
  LibraryScanMode _resolveScanMode() {
    if (!Platform.isAndroid) return LibraryScanMode.fileScanner;
    final idx = PlayerPreferencesService.instance.scanModeIndexCached;
    return LibraryScanMode
        .values[idx.clamp(0, LibraryScanMode.values.length - 1)];
  }

  @override
  FoldersState build() => const FoldersState();

  Future<void> load({bool forceScan = false}) async {
    if (state.isScanning) return;

    _scanMode = _resolveScanMode();

    // Hybrid / MediaStore: use the MediaStore index (fast) + live observer.
    // Hybrid additionally walks the filesystem to catch .nomedia folders
    // (WhatsApp, Telegram, …) that MediaStore deliberately skips.
    if (_scanMode != LibraryScanMode.fileScanner) {
      _ensureMediaStoreWatch();
      if (!forceScan && state.folders.isEmpty) {
        final cached = await _loadCache();
        if (cached != null && cached.isNotEmpty) {
          await _showCache(cached, _discoverStorageRoots());
        }
      }
      await _mediaStoreRefresh(
        showScanning: state.folders.isEmpty,
        withFilesystemMerge: _scanMode == LibraryScanMode.hybrid,
        forceFilesystem: forceScan,
      );
      return;
    }

    // File-scanner mode (and every non-Android platform): recursive walk only.
    _stopMediaStoreWatch();
    final roots = _discoverStorageRoots();

    if (forceScan) {
      await _fullScan(roots);
      return;
    }

    if (state.folders.isEmpty) {
      final cached = await _loadCache();
      if (cached != null && cached.isNotEmpty) {
        await _showCache(cached, roots);
        _backgroundCheck(roots);
        return;
      }
      await _fullScan(roots);
      return;
    }

    _backgroundCheck(roots);
  }

  /// Re-scans from scratch after the user changes the scan mode in settings.
  Future<void> rescanForModeChange() async {
    _stopMediaStoreWatch();
    state = const FoldersState(); // clean slate so the new method rescans fresh
    await load(forceScan: true);
  }

  // ── MediaStore (Android) ──────────────────────────────────────────────────

  void _ensureMediaStoreWatch() {
    if (_watchingMediaStore) return;
    _watchingMediaStore = true;
    MediaStoreService.setChangeHandler(_onMediaStoreChanged);
    MediaStoreService.startWatching();
  }

  void _stopMediaStoreWatch() {
    if (!_watchingMediaStore) return;
    _watchingMediaStore = false;
    _refreshDebounce?.cancel();
    MediaStoreService.stopWatching();
  }

  void _onMediaStoreChanged() {
    // Ignore live MediaStore changes when the user has opted into pure
    // file-scanner mode (its results would otherwise be overwritten).
    if (_scanMode == LibraryScanMode.fileScanner) return;
    // A single download/delete fires several callbacks — debounce them.
    _refreshDebounce?.cancel();
    _refreshDebounce = Timer(const Duration(milliseconds: 600), () {
      _mediaStoreRefresh(showScanning: false);
    });
  }

  Future<void> _mediaStoreRefresh({
    required bool showScanning,
    bool withFilesystemMerge = false,
    bool forceFilesystem = false,
  }) async {
    if (_refreshing) {
      _refreshPending = true;
      return;
    }
    _refreshing = true;
    try {
      final wasEmpty = state.folders.isEmpty;
      if (showScanning && wasEmpty) {
        state = state.copyWith(
          isScanning: true,
          scanProgress: 0,
          fromCache: false,
          storageRoots: _discoverStorageRoots(),
        );
      }

      final videos = await MediaStoreService.queryVideos();
      // MediaStore already knows each indexed video's duration — seed the cache
      // so the folder screen never spins up a Player just to read it.
      DurationCacheService.instance.seedDurations(videos);
      final mediaByPath = <String, VideoFile>{
        for (final v in videos) v.path: v
      };

      // In hybrid mode, keep the filesystem-only videos already on screen (from
      // cache or a prior walk) — WhatsApp/Telegram, etc. — so a MediaStore-only
      // refresh (including the live observer) never makes them disappear; the
      // authoritative on-disk set is rebuilt by _filesystemMerge. MediaStore-only
      // mode treats MediaStore as the source of truth and preserves nothing.
      final combined = Map<String, VideoFile>.from(mediaByPath);
      if (_scanMode == LibraryScanMode.hybrid) {
        for (final f in state.folders) {
          for (final v in f.videos) {
            combined.putIfAbsent(v.path, () => v);
          }
        }
      }
      await _applyFoldersIfChanged(_groupByFolder(combined.values.toList()));

      // The filesystem walk (the only real battery cost) surfaces WhatsApp/
      // Telegram videos MediaStore can't see. Throttled so back-to-back resumes
      // don't re-walk storage; an empty library or an explicit refresh forces it.
      if (withFilesystemMerge) {
        await _filesystemMerge(
          mediaByPath,
          force: forceFilesystem || wasEmpty,
        );
      }
    } finally {
      _refreshing = false;
      if (_refreshPending) {
        _refreshPending = false;
        await _mediaStoreRefresh(showScanning: false);
      }
    }
  }

  /// Runs the recursive filesystem scan (which ignores `.nomedia`, unlike
  /// MediaStore) and merges any videos MediaStore missed into the library.
  /// [byPath] already holds the MediaStore results, keyed by path, so we only
  /// re-render when the walk actually turns up something extra.
  Future<void> _filesystemMerge(
    Map<String, VideoFile> mediaByPath, {
    required bool force,
  }) async {
    // Battery: skip the walk if we did one recently and nothing is forcing it.
    // The preserved filesystem videos stay on screen (and cached) meanwhile.
    final last = _lastFilesystemScan;
    if (!force &&
        last != null &&
        DateTime.now().difference(last) < _minRescanGap) {
      return;
    }
    _lastFilesystemScan = DateTime.now();

    // Show the same scanning spinner the file-scanner mode shows while the
    // background walk runs — so hybrid also gives the user "scanning" feedback.
    // Cleared by _applyFoldersIfChanged when the walk finishes.
    if (!state.isScanning) {
      state = state.copyWith(isScanning: true);
    }

    // Rebuild the authoritative union: MediaStore ∪ on-disk videos. Starting
    // from MediaStore (rather than the current state) means a deleted WhatsApp
    // file is dropped here instead of lingering forever.
    final combined = Map<String, VideoFile>.from(mediaByPath);
    var progress = 0;
    for (final root in _discoverStorageRoots()) {
      final folders = await FolderScanner.scanFolders(
        root,
        onProgress: (_) {
          progress += 1;
          state = state.copyWith(scanProgress: progress);
        },
      );
      for (final f in folders) {
        for (final v in f.videos) {
          combined.putIfAbsent(v.path, () => v);
        }
      }
    }
    await _applyFoldersIfChanged(_groupByFolder(combined.values.toList()));
  }

  /// Commits [merged] only when the set of videos actually differs from what's
  /// shown — so a no-op rescan doesn't rewrite the cache, recompute badges, or
  /// flicker the UI. (It still clears any lingering "scanning" flag.)
  Future<void> _applyFoldersIfChanged(List<VideoFolder> merged) async {
    if (_sameVideoSet(merged)) {
      if (state.isScanning || state.fromCache) {
        state = state.copyWith(isScanning: false, fromCache: false);
      }
      return;
    }
    await _applyFolders(merged);
  }

  /// True when [merged] contains exactly the same video paths as the current
  /// state (folder grouping/order aside).
  bool _sameVideoSet(List<VideoFolder> merged) {
    final current = <String>{};
    for (final f in state.folders) {
      for (final v in f.videos) {
        current.add(v.path);
      }
    }
    var count = 0;
    for (final f in merged) {
      for (final v in f.videos) {
        count++;
        if (!current.contains(v.path)) return false;
      }
    }
    return count == current.length;
  }

  /// Groups a flat MediaStore video list into folders by parent directory,
  /// matching what the filesystem scanner produces (folder path + sorted list).
  List<VideoFolder> _groupByFolder(List<VideoFile> videos) {
    final Map<String, List<VideoFile>> map = {};
    for (final v in videos) {
      map.putIfAbsent(p.dirname(v.path), () => []).add(v);
    }
    final folders = map.entries.map((e) {
      final vids = e.value;
      final vkeys = {for (final v in vids) v: v.name.toLowerCase()};
      vids.sort((a, b) => vkeys[a]!.compareTo(vkeys[b]!));
      return VideoFolder(path: e.key, videos: vids);
    }).toList();
    final fkeys = {for (final f in folders) f: f.name.toLowerCase()};
    folders.sort((a, b) => fkeys[a]!.compareTo(fkeys[b]!));
    return folders;
  }

  // ── Shared: show cached folders with "new" badges ─────────────────────────

  Future<void> _showCache(List<VideoFolder> cached, List<String> roots) async {
    // FIX #SDCARD: Filter out folders whose storage root no longer exists.
    final validFolders = cached
        .where((f) => roots.any((root) => f.path.startsWith(root)))
        .toList();

    final seenPaths = await _loadSeenPaths();
    final initialised = seenPaths != null && seenPaths.isNotEmpty;
    final newPaths = <String>{};
    if (initialised) {
      for (final f in validFolders) {
        if (!seenPaths.contains(f.path) &&
            !_sessionSeenPaths.contains(f.path)) {
          newPaths.add(f.path);
        }
        for (final v in f.videos) {
          if (!seenPaths.contains(v.path) &&
              !_sessionSeenPaths.contains(v.path)) {
            newPaths.add(v.path);
            newPaths.add(f.path);
          }
        }
      }
    }

    state = state.copyWith(
      folders: validFolders,
      fromCache: true,
      storageRoots: roots,
      newPaths: newPaths,
    );
  }

  Future<void> _backgroundCheck(List<String> roots) async {
    // Battery: the change-check itself walks the tree, so throttle it the same
    // way — a resume within the window skips re-checking entirely.
    final last = _lastFilesystemScan;
    if (last != null && DateTime.now().difference(last) < _minRescanGap) {
      return;
    }
    _lastFilesystemScan = DateTime.now();
    final changed = await _hasNewContent();
    if (changed) await _fullScan(roots);
  }

  Future<void> _fullScan(List<String> roots) async {
    // Mark the walk so the throttle window starts from this scan.
    _lastFilesystemScan = DateTime.now();
    state = state.copyWith(
      isScanning: true,
      folders: state.folders,
      scanProgress: 0,
      fromCache: false,
      storageRoots: roots,
    );

    // FIX #2: Capture which paths were dismissed in this session.
    // We use _sessionSeenPaths instead of trying to deduce it from state.newPaths
    // which was incorrectly marking genuinely new files as dismissed.

    final Map<String, List<VideoFile>> folderMap = {};
    int progress = 0;

    for (final root in roots) {
      final folders = await FolderScanner.scanFolders(
        root,
        onProgress: (n) {
          progress += 1;
          state = state.copyWith(scanProgress: progress);
        },
      );
      for (final f in folders) {
        folderMap.putIfAbsent(f.path, () => []).addAll(f.videos);
      }

      // FIX #SCAN-KILL: Save partial cache after each root so a mid-scan kill
      // doesn't leave the user with a blank library on next open.
      if (folderMap.isNotEmpty) {
        final partial = folderMap.entries
            .map((e) => VideoFolder(path: e.key, videos: e.value))
            .toList();
        _saveCache(partial).ignore();
      }
    }

    final merged = folderMap.entries.map((e) {
      final videos = e.value;
      final vkeys = {for (final v in videos) v: v.name.toLowerCase()};
      videos.sort((a, b) => vkeys[a]!.compareTo(vkeys[b]!));
      return VideoFolder(path: e.key, videos: videos);
    }).toList();
    final fkeys = {for (final f in merged) f: f.name.toLowerCase()};
    merged.sort((a, b) => fkeys[a]!.compareTo(fkeys[b]!));

    await _applyFolders(merged);
  }

  /// Commits a freshly-built folder list: computes "new" badges relative to the
  /// persisted seen-paths, updates state, and saves the cache + seen paths.
  /// Source-agnostic — used by both the filesystem scan and MediaStore refresh.
  Future<void> _applyFolders(List<VideoFolder> merged) async {
    final seenPaths = await _loadSeenPaths();

    // FIX #4: Build current path set and prune stale entries from seenPaths.
    final Set<String> allCurrentPaths = {};
    for (final folder in merged) {
      allCurrentPaths.add(folder.path);
      for (final video in folder.videos) {
        allCurrentPaths.add(video.path);
      }
    }
    final Set<String> alreadySeenPaths =
        seenPaths != null ? _pruneSeenPaths(seenPaths, allCurrentPaths) : {};

    final Set<String> newPaths = {};

    for (final folder in merged) {
      // A path is considered new when ALL of these are true:
      //   1. seenPaths is initialised (null = first install → no badges)
      //   2. seenPaths is not empty (empty first scan → no badges)
      //   3. path is not in seenPaths on disk
      //   4. FIX #2: path was not dismissed in the current session.
      final bool initialised = seenPaths != null && seenPaths.isNotEmpty;

      final folderOnDisk = seenPaths?.contains(folder.path) ?? false;
      final folderDismissedInSession = _sessionSeenPaths.contains(folder.path);

      if (initialised && !folderOnDisk && !folderDismissedInSession) {
        newPaths.add(folder.path);
      } else {
        alreadySeenPaths.add(folder.path);
      }

      for (final video in folder.videos) {
        final videoOnDisk = seenPaths?.contains(video.path) ?? false;
        final videoDismissedInSession = _sessionSeenPaths.contains(video.path);

        if (initialised && !videoOnDisk && !videoDismissedInSession) {
          newPaths.add(video.path);
          newPaths.add(folder.path); // keep folder badge alive too
        } else {
          alreadySeenPaths.add(video.path);
        }
      }
    }

    state = state.copyWith(
      folders: merged,
      isScanning: false,
      fromCache: false,
      newPaths: newPaths,
    );

    await Future.wait([
      _saveSeenPaths(alreadySeenPaths),
      _saveCache(merged),
    ]);
  }

  // ── Mark a video as seen (user opened it) ─────────────────────────────────

  void markSeen(String videoPath) {
    if (!state.newPaths.contains(videoPath)) return;
    final updated = Set<String>.from(state.newPaths)..remove(videoPath);
    _sessionSeenPaths.add(videoPath);

    // FIX #1: Also clear + persist the folder path when the last new video
    // in it is watched. Previously only videoPath was written to disk, so the
    // folder path stayed absent from seenPaths and re-badged on next scan.
    String? clearedFolderPath;
    for (final folder in state.folders) {
      if (folder.videos.any((v) => v.path == videoPath)) {
        final folderStillNew =
            folder.videos.any((v) => updated.contains(v.path));
        if (!folderStillNew) {
          updated.remove(folder.path);
          _sessionSeenPaths.add(folder.path);
          clearedFolderPath = folder.path;
        }
        break;
      }
    }

    state = state.copyWith(newPaths: updated);
    _persistSeenRemoval(videoPath, clearedFolderPath: clearedFolderPath);
  }

  Future<void> _persistSeenRemoval(
    String videoPath, {
    String? clearedFolderPath,
  }) async {
    try {
      final prefs = await _p;
      final raw = prefs.getString(_seenPathsKey);
      if (raw == null) return;
      final set = (jsonDecode(raw) as List<dynamic>).cast<String>().toSet();
      set.add(videoPath);
      // FIX #1: persist folder path too when all its videos are now seen.
      if (clearedFolderPath != null) set.add(clearedFolderPath);
      await prefs.setString(_seenPathsKey, jsonEncode(set.toList()));
    } catch (_) {}
  }

  // ── Remove a single video from state (no rescan needed) ────────────────

  /// Surgically removes a video from the in-memory state and persists the
  /// updated folder list to cache. Avoids an expensive full filesystem rescan.
  void removeVideo(String videoPath) {
    final updatedFolders = state.folders
        .map((folder) {
          final updatedVideos =
              folder.videos.where((v) => v.path != videoPath).toList();
          return VideoFolder(path: folder.path, videos: updatedVideos);
        })
        .where((f) => f.videos.isNotEmpty)
        .toList();

    final updatedNewPaths = pruneNewPathsForRemovedVideos(
      currentNewPaths: state.newPaths,
      folders: updatedFolders,
      removedPaths: [videoPath],
    );

    state = state.copyWith(folders: updatedFolders, newPaths: updatedNewPaths);

    // Persist the updated folder list so the next cold start reflects the
    // deletion without needing a rescan.
    _saveCache(updatedFolders);
  }

  /// Surgically replaces a single video in state with its renamed counterpart
  /// (no rescan needed) and persists the updated folder list to cache.
  void renameVideo(String oldPath, VideoFile renamed) {
    final updatedFolders = state.folders.map((folder) {
      final idx = folder.videos.indexWhere((v) => v.path == oldPath);
      if (idx == -1) return folder;
      final updatedVideos = List<VideoFile>.from(folder.videos);
      updatedVideos[idx] = renamed;
      return VideoFolder(path: folder.path, videos: updatedVideos);
    }).toList();

    final updatedNewPaths = Set<String>.from(state.newPaths)..remove(oldPath);

    state = state.copyWith(folders: updatedFolders, newPaths: updatedNewPaths);
    _saveCache(updatedFolders);
  }

  /// Surgically removes multiple videos from the in-memory state and persists the
  /// updated folder list to cache.
  void removeVideos(List<String> videoPaths) {
    final pathSet = videoPaths.toSet();
    final updatedFolders = state.folders
        .map((folder) {
          final updatedVideos =
              folder.videos.where((v) => !pathSet.contains(v.path)).toList();
          return VideoFolder(path: folder.path, videos: updatedVideos);
        })
        .where((f) => f.videos.isNotEmpty)
        .toList();

    final updatedNewPaths = pruneNewPathsForRemovedVideos(
      currentNewPaths: state.newPaths,
      folders: updatedFolders,
      removedPaths: pathSet.toList(),
    );

    state = state.copyWith(folders: updatedFolders, newPaths: updatedNewPaths);
    _saveCache(updatedFolders);
  }

  void reset() => state = const FoldersState();
}

final foldersProvider = NotifierProvider<FoldersNotifier, FoldersState>(
  FoldersNotifier.new,
);
