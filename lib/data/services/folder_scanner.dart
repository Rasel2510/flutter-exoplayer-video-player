import 'package:path/path.dart' as p;
import 'dart:io';
import 'dart:isolate';
import 'package:flutter_video_player/data/models/video_file.dart';
import 'package:flutter_video_player/data/models/video_folder.dart';

class FolderScanner {
  /// Scans [rootPath] recursively and groups videos by folder, using an isolate.
  static Future<List<VideoFolder>> scanFolders(
    String rootPath, {
    void Function(int found)? onProgress,
  }) async {
    final receivePort = ReceivePort();
    await Isolate.spawn(
      _isolateScanFolders,
      _IsolateScanData(rootPath, receivePort.sendPort),
      // If the isolate dies before sending its result (OOM kill, crash), these
      // still deliver a message so the await-for below can't hang forever —
      // which previously left the library stuck on "scanning".
      onExit: receivePort.sendPort,
      onError: receivePort.sendPort,
    );

    List<VideoFolder>? finalResult;
    await for (final message in receivePort) {
      if (message is int) {
        onProgress?.call(message);
      } else if (message is List<VideoFolder>) {
        finalResult = message;
        receivePort.close();
      } else {
        // onExit (null) or onError payload without a result: isolate is gone.
        receivePort.close();
      }
    }
    return finalResult ?? [];
  }

  static Future<void> _isolateScanFolders(_IsolateScanData data) async {
    final dir = Directory(data.rootPath);
    if (!dir.existsSync()) {
      data.sendPort.send(<VideoFolder>[]);
      return;
    }

    final Map<String, List<VideoFile>> folderMap = {};
    _recurseForFoldersSync(dir, folderMap, 0, (count) {
      data.sendPort.send(count);
    });

    final folders = folderMap.entries.map((e) {
      final videos = e.value;
      final vkeys = {for (final v in videos) v: v.name.toLowerCase()};
      videos.sort((a, b) => vkeys[a]!.compareTo(vkeys[b]!));
      return VideoFolder(path: e.key, videos: videos);
    }).toList();

    final fkeys = {for (final f in folders) f: f.name.toLowerCase()};
    folders.sort((a, b) => fkeys[a]!.compareTo(fkeys[b]!));
    data.sendPort.send(folders);
  }

  static int _recurseForFoldersSync(
    Directory dir,
    Map<String, List<VideoFile>> out,
    int currentTotal,
    void Function(int)? onProgress,
  ) {
    try {
      final List<VideoFile> videosInThisDir = [];
      final List<Directory> subDirs = [];

      for (final entity in dir.listSync(followLinks: false)) {
        if (entity is File && VideoFile.isVideoFile(entity.path)) {
          final vf = VideoFile.fromFile(entity);
          if (vf != null && vf.size >= 1024) videosInThisDir.add(vf);
        } else if (entity is Directory) {
          final name = p.basename(entity.path);
          if (!name.startsWith('.')) subDirs.add(entity);
        }
      }

      if (videosInThisDir.isNotEmpty) {
        out[dir.path] = videosInThisDir;
        currentTotal += videosInThisDir.length;
        if (currentTotal % 25 == 0) onProgress?.call(currentTotal);
      }

      for (final sub in subDirs) {
        currentTotal = _recurseForFoldersSync(sub, out, currentTotal, onProgress);
      }
    } catch (_) {}
    return currentTotal;
  }
}

class _IsolateScanData {
  final String rootPath;
  final SendPort sendPort;
  _IsolateScanData(this.rootPath, this.sendPort);
}
