import 'package:flutter/material.dart';
import 'package:flutter_video_player/core/theme/app_theme.dart';
import 'package:flutter_video_player/data/models/video_folder.dart';

/// A single destination row in the Move/Copy-to-album folder picker.
class AlbumFolderRow extends StatelessWidget {
  final VideoFolder folder;
  final bool selected;
  final VoidCallback onTap;

  const AlbumFolderRow({
    super.key,
    required this.folder,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Row(
            children: [
              Icon(
                Icons.folder_rounded,
                color: selected
                    ? context.colors.accent
                    : context.colors.textMuted,
                size: 22,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      folder.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: context.colors.textPrimary,
                      ),
                    ),
                    Text(
                      '${folder.videoCount} video${folder.videoCount == 1 ? '' : 's'}',
                      style: context.textStyles.caption,
                    ),
                  ],
                ),
              ),
              if (selected)
                Icon(Icons.check_circle_rounded,
                    color: context.colors.accent, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}
