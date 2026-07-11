import 'package:flutter/material.dart';
import 'package:flutter_video_player/data/models/video_file.dart';
import 'package:flutter_video_player/presentation/widgets/folder_videos/folder_search_bar.dart';
import 'package:flutter_video_player/presentation/widgets/folder_videos/no_results.dart';
import 'package:flutter_video_player/presentation/widgets/folder_videos/sort_option.dart';
import 'package:flutter_video_player/presentation/widgets/folder_videos/video_card.dart';

class FolderVideosContent extends StatelessWidget {
  final Set<String> newPaths;
  final List<VideoFile> sorted;
  final List<VideoFile> display;
  final VideoFile? last;
  final bool selectionMode;
  final bool searchOpen;
  final TextEditingController searchCtrl;
  final SortOption sortBy;
  final Map<String, Duration> positions;
  final Map<String, Duration> durations;
  final Set<String> selectedPaths;
  final Future<void> Function(VideoFile vf, List<VideoFile> playlist,
      {bool forceResume}) onOpenVideo;
  final void Function(VideoFile vf, List<VideoFile> playlist) onLongPress;
  final void Function(VideoFile vf) onSelectToggle;

  const FolderVideosContent({
    super.key,
    required this.newPaths,
    required this.sorted,
    required this.display,
    required this.last,
    required this.selectionMode,
    required this.searchOpen,
    required this.searchCtrl,
    required this.sortBy,
    required this.positions,
    required this.durations,
    required this.selectedPaths,
    required this.onOpenVideo,
    required this.onLongPress,
    required this.onSelectToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        FolderSearchBar(open: searchOpen, controller: searchCtrl),
        Expanded(
          child: display.isEmpty
              ? (searchOpen && searchCtrl.text.trim().isNotEmpty
                  ? NoResults(query: searchCtrl.text.trim().toLowerCase())
                  : const SizedBox())
              : ListView.builder(
                  padding: EdgeInsets.fromLTRB(
                    16,
                    8,
                    16,
                    (selectionMode ? 88 : (last != null ? 96 : 16)) +
                        MediaQuery.of(context).padding.bottom,
                  ),
                  itemCount: display.length,
                  itemBuilder: (_, i) {
                    final vf = display[i];
                    final savedPos = positions[vf.path];
                    final hasResume =
                        savedPos != null && savedPos > Duration.zero;
                    final isNew = newPaths.contains(vf.path);
                    return RepaintBoundary(
                      key: ValueKey(vf.path),
                      child: VideoCard(
                        vf: vf,
                        savedPos: hasResume ? savedPos : null,
                        totalDur: durations[vf.path],
                        isNew: isNew,
                        sortBy: sortBy,
                        selectionMode: selectionMode,
                        isSelected: selectedPaths.contains(vf.path),
                        onSelectToggle: () => onSelectToggle(vf),
                        onTap: () => onOpenVideo(vf, sorted),
                        onLongPress: () => onLongPress(vf, sorted),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
