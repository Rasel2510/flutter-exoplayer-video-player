import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/video_file.dart';

class VaultService {
  VaultService._();
  static final VaultService instance = VaultService._();

  final LocalAuthentication _auth = LocalAuthentication();

  static const String _vaultDbKey = 'vault_database';
  Map<String, String> _db = {}; // Maps vaultFilePath -> originalPath
  bool _initialized = false;

  // ── Move concurrency cap ───────────────────────────────────────────────────
  // A move can fall back to copy()+delete() for cross-partition moves (e.g.
  // SD card -> internal vault folder) — genuine byte-for-byte I/O. Unbounded
  // parallel copies buy no real throughput on cheap eMMC controllers (which
  // largely serialize concurrent writes anyway), hold multiple copy buffers
  // in RAM at once, and add sustained multi-threaded I/O pressure that's more
  // likely to thermal-throttle a budget SoC than one steady stream. Capping
  // at 2 — same convention as DurationCacheService's probe limit — still lets
  // cheap same-partition renames overlap their (near-free) syscall latency
  // without piling up heavy copies.
  static const int _kMaxConcurrentMoves = 2;
  int _activeMoves = 0;
  final List<Completer<void>> _moveWaiters = [];

  Future<void> _acquireMoveSlot() async {
    if (_activeMoves < _kMaxConcurrentMoves) {
      _activeMoves++;
      return;
    }
    final c = Completer<void>();
    _moveWaiters.add(c);
    await c.future;
  }

  void _releaseMoveSlot() {
    if (_moveWaiters.isNotEmpty) {
      _moveWaiters.removeAt(0).complete();
    } else {
      _activeMoves--;
    }
  }
  
  Future<void> init() async {
    if (_initialized) return;
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_vaultDbKey);
    if (jsonStr != null) {
      _db = Map<String, String>.from(jsonDecode(jsonStr));
    }
    _initialized = true;
  }

  Future<void> _saveDb() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_vaultDbKey, jsonEncode(_db));
  }

  Future<Directory> get _vaultDir async {
    final dir = await getApplicationSupportDirectory();
    final vaultDir = Directory(p.join(dir.path, 'vault'));
    if (!await vaultDir.exists()) {
      await vaultDir.create(recursive: true);
    }
    return vaultDir;
  }

  Future<bool> authenticate() async {
    try {
      final isAvailable = await _auth.canCheckBiometrics || await _auth.isDeviceSupported();
      if (!isAvailable) return true; // If device has no secure lock, allow access (or could implement custom PIN).
      return await _auth.authenticate(
        localizedReason: 'Please authenticate to access the Secure Vault',
      );
    } on PlatformException catch (_) {
      return false;
    }
  }

  Future<void> _safeMove(File source, String targetPath) async {
    try {
      await source.rename(targetPath);
    } catch (_) {
      // Fallback for cross-partition moves (e.g., SD card to internal storage)
      await source.copy(targetPath);
      await source.delete();
    }
  }

  Future<VideoFile?> moveToVault(VideoFile video) async {
    await init();
    final vaultVideo = await _moveOneToVault(video, await _vaultDir);
    if (vaultVideo != null) await _saveDb();
    return vaultVideo;
  }


  /// Moves every video's file with bounded concurrency (see
  /// [_kMaxConcurrentMoves]) and persists the vault database exactly once at
  /// the end, instead of once per video. A single-video vault action
  /// re-resolving the vault directory and rewriting the whole (growing)
  /// database to SharedPreferences on every item made selecting N videos
  /// cost N serial renames + N full-map prefs writes.
  Future<List<VideoFile>> moveManyToVault(List<VideoFile> videos) async {
    await init();
    final dir = await _vaultDir;
    final results = await Future.wait(
      videos.map((v) => _moveOneToVaultBounded(v, dir)),
    );
    await _saveDb();
    return results.whereType<VideoFile>().toList();
  }

  Future<VideoFile?> _moveOneToVaultBounded(
      VideoFile video, Directory dir) async {
    await _acquireMoveSlot();
    try {
      return await _moveOneToVault(video, dir);
    } finally {
      _releaseMoveSlot();
    }
  }

  Future<VideoFile?> _moveOneToVault(VideoFile video, Directory dir) async {
    try {
      final file = File(video.path);
      if (!await file.exists()) return null;

      final uniqueId =
          '${DateTime.now().microsecondsSinceEpoch}_${video.path.hashCode}';
      final vaultPath = p.join(dir.path, 'vault_$uniqueId.vault');

      await _safeMove(file, vaultPath);
      _db[vaultPath] = video.path;

      return VideoFile(
        path: vaultPath,
        name: video.name, // Keep original name internally
        size: video.size,
        modified: video.modified,
        duration: video.duration,
      );
    } catch (_) {
      return null;
    }
  }

  Future<bool> restoreFromVault(VideoFile vaultVideo) async {
    await init();
    final ok = await _restoreOne(vaultVideo);
    await _saveDb();
    return ok;
  }

  /// Restores every video with bounded concurrency (mirrors [moveManyToVault]
  /// — a restore can also fall back to copy()+delete() for a cross-partition
  /// original location) and saves the database once at the end. Returns the
  /// vault paths that were successfully restored.
  Future<List<String>> restoreManyFromVault(List<VideoFile> vaultVideos) async {
    await init();
    final results = await Future.wait(vaultVideos.map((v) async {
      await _acquireMoveSlot();
      try {
        return (await _restoreOne(v)) ? v.path : null;
      } finally {
        _releaseMoveSlot();
      }
    }));
    await _saveDb();
    return results.whereType<String>().toList();
  }

  Future<bool> _restoreOne(VideoFile vaultVideo) async {
    try {
      final vaultFile = File(vaultVideo.path);
      if (!await vaultFile.exists()) {
        _db.remove(vaultVideo.path);
        return false;
      }

      final originalPath = _db[vaultVideo.path];
      if (originalPath == null) return false;

      final targetDir = Directory(p.dirname(originalPath));
      if (!await targetDir.exists()) {
        await targetDir.create(recursive: true);
      }

      await _safeMove(vaultFile, originalPath);
      _db.remove(vaultVideo.path);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> deleteFromVault(VideoFile vaultVideo) async {
    await init();
    await _deleteOne(vaultVideo);
    await _saveDb();
  }

  /// Deletes every video with bounded concurrency and saves the database once
  /// at the end, instead of once per video.
  Future<void> deleteManyFromVault(List<VideoFile> vaultVideos) async {
    await init();
    await Future.wait(vaultVideos.map((v) async {
      await _acquireMoveSlot();
      try {
        await _deleteOne(v);
      } finally {
        _releaseMoveSlot();
      }
    }));
    await _saveDb();
  }

  Future<void> _deleteOne(VideoFile vaultVideo) async {
    try {
      final vaultFile = File(vaultVideo.path);
      if (await vaultFile.exists()) {
        await vaultFile.delete();
      }
      _db.remove(vaultVideo.path);
    } catch (_) {}
  }

  Future<List<VideoFile>> getVaultVideos() async {
    await init();

    // Stat every entry concurrently instead of one file at a time — this
    // runs after every vault add/restore/delete plus once on screen open, so
    // a serial loop re-blocks through the whole vault on every action.
    final entries = _db.entries.toList();
    final stats = await Future.wait(entries.map((e) async {
      final file = File(e.key);
      return (await file.exists()) ? await file.stat() : null;
    }));

    final videos = <VideoFile>[];
    final keysToRemove = <String>[];
    for (var i = 0; i < entries.length; i++) {
      final stat = stats[i];
      if (stat == null) {
        keysToRemove.add(entries[i].key);
        continue;
      }
      videos.add(VideoFile(
        path: entries[i].key,
        name: p.basename(entries[i].value),
        size: stat.size,
        modified: stat.modified,
      ));
    }

    if (keysToRemove.isNotEmpty) {
      for (final k in keysToRemove) {
        _db.remove(k);
      }
      await _saveDb();
    }

    // Sort by name descending
    videos.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return videos;
  }
}
