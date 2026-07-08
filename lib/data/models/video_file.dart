import 'package:flutter_video_player/core/utils/file_size_formatter.dart';
import 'dart:io';
import 'package:path/path.dart' as p;

class VideoFile {
  final String path;
  final String name;
  final int size; // bytes
  final DateTime modified;
  final Duration? duration;

  VideoFile({
    required this.path,
    required this.name,
    required this.size,
    required this.modified,
    this.duration,
  });

  // Computed once on first access — p.extension() is called for every card in
  // every list build without caching. late final pays the cost exactly once.
  late final String extension      = p.extension(name).toLowerCase();
  late final String extensionLabel = extension.replaceFirst('.', '').toUpperCase();
  late final String sizeLabel      = FileSizeFormatter.format(size);

  // FIX #15: Added .rmvb, .flv, .divx, .vob, .ogv, .m2v, .mxf which are
  // common formats that were previously silently ignored during library scans.
  static bool isVideoFile(String filename) {
    const videoExts = {
      // Common modern formats
      '.mp4', '.mkv', '.mov', '.avi', '.webm',
      // Streaming / broadcast
      '.ts', '.m2ts', '.mts',
      // Legacy / niche
      '.flv', '.wmv', '.m4v', '.3gp', '.3g2',
      '.rmvb', '.rm', '.divx', '.xvid',
      '.vob', '.ogv', '.m2v', '.mxf', '.mpg', '.mpeg',
      // Apple
      '.m4b',
    };
    return videoExts.contains(p.extension(filename).toLowerCase());
  }

  static VideoFile? fromFile(File file) {
    try {
      final stat = file.statSync();
      return VideoFile(
        path: file.path,
        name: p.basename(file.path),
        size: stat.size,
        modified: stat.modified,
      );
    } catch (_) {
      return null;
    }
  }

  VideoFile copyWith({Duration? duration}) => VideoFile(
        path: path,
        name: name,
        size: size,
        modified: modified,
        duration: duration ?? this.duration,
      );

  Map<String, dynamic> toJson() => {
        'path': path,
        'name': name,
        'size': size,
        'modified': modified.millisecondsSinceEpoch,
        if (duration != null) 'duration': duration!.inMilliseconds,
      };

  factory VideoFile.fromJson(Map<String, dynamic> json) => VideoFile(
        path: json['path'] as String,
        name: json['name'] as String,
        size: json['size'] as int,
        modified: DateTime.fromMillisecondsSinceEpoch(json['modified'] as int),
        duration: json['duration'] != null
            ? Duration(milliseconds: json['duration'] as int)
            : null,
      );
}
