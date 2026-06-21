import 'package:flutter/material.dart';
import 'package:flutter_video_player/core/theme/app_theme.dart';
import 'package:flutter_video_player/models/video_file.dart';
import '../common/sheet_surface.dart';
import 'option_row.dart';

class VideoOptionsSheet extends StatelessWidget {
  final VideoFile vf;
  final bool hasResume;
  final VoidCallback onPlay;
  final VoidCallback onShare;
  final VoidCallback onRename;
  final VoidCallback onDetails;
  final VoidCallback onSelect;
  final VoidCallback onCopyPath;
  final VoidCallback? onClearResume;
  final VoidCallback onDelete;

  const VideoOptionsSheet({
    super.key,
    required this.vf,
    required this.hasResume,
    required this.onPlay,
    required this.onShare,
    required this.onRename,
    required this.onDetails,
    required this.onSelect,
    required this.onCopyPath,
    this.onClearResume,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).padding.bottom;
    return SheetSurface(
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
          // ── File name ────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 4),
            child: Text(
              vf.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: context.colors.textPrimary,
              ),
            ),
          ),

          Divider(color: context.colors.divider),

          // ── Actions ──────────────────────────────────────────────────────
          Padding(
            padding: EdgeInsets.fromLTRB(20, 4, 20, 16 + bottomPad),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                OptionRow(
                    icon: Icons.play_arrow_rounded,
                    label: 'Play',
                    onTap: onPlay),
                OptionRow(
                    icon: Icons.share_rounded,
                    label: 'Share',
                    onTap: onShare),
                OptionRow(
                    icon: Icons.edit_outlined,
                    label: 'Rename',
                    onTap: onRename),
                OptionRow(
                    icon: Icons.info_outline_rounded,
                    label: 'Details',
                    onTap: onDetails),
                OptionRow(
                    icon: Icons.checklist_rounded,
                    label: 'Select',
                    onTap: onSelect),
                OptionRow(
                    icon: Icons.copy_rounded,
                    label: 'Copy path',
                    onTap: onCopyPath),
                if (hasResume && onClearResume != null)
                  OptionRow(
                      icon: Icons.replay_rounded,
                      label: 'Clear resume position',
                      onTap: onClearResume!),
                OptionRow(
                    icon: Icons.delete_outline_rounded,
                    label: 'Delete',
                    color: context.colors.errorRed,
                    onTap: onDelete),
              ],
            ),
          ),
        ],
        ),
      ),
    );
  }
}
