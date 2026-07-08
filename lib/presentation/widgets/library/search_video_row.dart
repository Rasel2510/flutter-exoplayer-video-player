import 'package:flutter/material.dart';
import 'package:flutter_video_player/core/theme/app_theme.dart';
import 'package:flutter_video_player/data/models/video_file.dart';
import 'package:flutter_video_player/presentation/widgets/folder_videos/format_badge.dart';
import 'package:flutter_video_player/presentation/widgets/common/thumbnail_widget.dart';

/// A single video result when searching across every folder in the library
/// (as opposed to [FolderCard], which represents a whole folder match).
class SearchVideoRow extends StatelessWidget {
  final VideoFile video;
  final String folderName;
  final VoidCallback onTap;

  const SearchVideoRow({
    super.key,
    required this.video,
    required this.folderName,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: context.colors.surface,
        borderRadius: AppRadius.md,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          splashColor: context.colors.accentSoft,
          highlightColor: Colors.transparent,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 16, 12),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: AppRadius.sm,
                  child: VideoThumbnailWidget(
                    videoPath: video.path,
                    width: 72,
                    height: 48,
                    duration: video.duration,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        video.name,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: context.colors.textPrimary,
                          height: 1.3,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 5),
                      Row(
                        children: [
                          FormatBadge(video.extensionLabel),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Row(
                              children: [
                                Icon(Icons.folder_outlined,
                                    size: 11, color: context.colors.textMuted),
                                const SizedBox(width: 3),
                                Expanded(
                                  child: Text(
                                    folderName,
                                    style: context.textStyles.caption,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded,
                    size: 18, color: context.colors.textMuted),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

