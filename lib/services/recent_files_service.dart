import 'dart:convert';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/video_file.dart';

class RecentFilesService {
  RecentFilesService._();
  static final instance = RecentFilesService._();

  // Cached — only one platform channel call per app session.
  SharedPreferences? _prefs;
  Future<SharedPreferences> get _p async =>
      _prefs ??= await SharedPreferences.getInstance();

  static const _key      = 'recent_videos';
  static const _maxItems = 20;

  Future<List<VideoFile>> getRecents() async {
    final raw   = (await _p).getStringList(_key) ?? [];
    final files = <VideoFile>[];
    for (final s in raw) {
      try {
        final vf = VideoFile.fromJson(jsonDecode(s));
        if (await File(vf.path).exists()) files.add(vf);
      } catch (_) {}
    }
    return files;
  }

  Future<void> addRecent(VideoFile vf) async {
    final p   = await _p;
    final raw = p.getStringList(_key) ?? [];
    raw.removeWhere((s) {
      try { return VideoFile.fromJson(jsonDecode(s)).path == vf.path; }
      catch (_) { return false; }
    });
    raw.insert(0, jsonEncode(vf.toJson()));
    await p.setStringList(_key, raw.take(_maxItems).toList());
  }

  Future<void> removeRecent(String path) async {
    final p   = await _p;
    final raw = p.getStringList(_key) ?? [];
    raw.removeWhere((s) {
      try { return VideoFile.fromJson(jsonDecode(s)).path == path; }
      catch (_) { return true; }
    });
    await p.setStringList(_key, raw);
  }

  Future<void> clearAll() async {
    await (await _p).remove(_key);
  }
}
