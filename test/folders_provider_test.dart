import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_video_player/data/models/video_file.dart';
import 'package:flutter_video_player/data/models/video_folder.dart';
import 'package:flutter_video_player/presentation/providers/folders_provider.dart';

void main() {
  group('pruneNewPathsForRemovedVideos', () {
    test(
        'drops the folder badge when the last new video in that folder is removed',
        () {
      final folder = VideoFolder(
        path: '/storage/emulated/0/Movies/Folder A',
        videos: [
          VideoFile(
            path: '/storage/emulated/0/Movies/Folder A/a.mp4',
            name: 'a.mp4',
            size: 1024,
            modified: DateTime(2024, 1, 1),
          ),
        ],
      );

      final updated = pruneNewPathsForRemovedVideos(
        currentNewPaths: {
          '/storage/emulated/0/Movies/Folder A/a.mp4',
          '/storage/emulated/0/Movies/Folder A',
        },
        folders: [folder],
        removedPaths: ['/storage/emulated/0/Movies/Folder A/a.mp4'],
      );

      expect(updated, isEmpty);
    });
  });
}
