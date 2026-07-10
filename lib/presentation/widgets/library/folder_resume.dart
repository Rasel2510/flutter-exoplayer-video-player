import 'package:flutter_video_player/data/models/video_file.dart';

/// The most recently watched, still-in-progress video within a folder — used
/// to show a resume pill/FAB for that folder without loading positions for
/// every video eagerly.
class FolderResume {
  final VideoFile video;
  final Duration position;
  const FolderResume(this.video, this.position);
}
