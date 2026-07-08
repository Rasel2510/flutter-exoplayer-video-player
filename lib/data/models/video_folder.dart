import '../core/utils/file_size_formatter.dart';
import 'package:path/path.dart' as p;
import 'video_file.dart';

class VideoFolder {
  final String path;
  final List<VideoFile> videos;

  VideoFolder({required this.path, required this.videos});

  // late final — each of these was previously recomputed on every access.
  // name:      calls p.basename() twice in the old getter.
  // totalSize: folds the entire video list on every access.
  late final String name = _computeName();
  late final int    totalSize      = videos.fold(0, (s, v) => s + v.size);
  late final String totalSizeLabel = FileSizeFormatter.format(totalSize);

  String _computeName() {
    final base = p.basename(path);
    return base.isEmpty ? path : base;
  }

  int get videoCount => videos.length;
}
