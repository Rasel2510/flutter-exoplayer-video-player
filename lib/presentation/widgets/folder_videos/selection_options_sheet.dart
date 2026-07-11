import 'package:flutter/material.dart';
import 'package:flutter_video_player/core/theme/app_theme.dart';
import 'package:flutter_video_player/presentation/widgets/common/sheet_surface.dart';
import 'option_row.dart';

/// Overflow actions for the current multi-selection, reached via the ⋮ icon
/// beside Share and Move to Vault in the selection app bar — keeps that bar
/// from growing a new icon for every bulk action added later.
class SelectionOptionsSheet extends StatelessWidget {
  final int selectedCount;
  final bool canClearResume;
  final VoidCallback onClearResume;
  final VoidCallback onMoveToAlbum;
  final VoidCallback onCopyToAlbum;

  const SelectionOptionsSheet({
    super.key,
    required this.selectedCount,
    required this.canClearResume,
    required this.onClearResume,
    required this.onMoveToAlbum,
    required this.onCopyToAlbum,
  });

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).padding.bottom;
    return SheetSurface(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 4),
            child: Text(
              '$selectedCount selected',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: context.colors.textPrimary,
              ),
            ),
          ),
          Divider(color: context.colors.divider),
          Padding(
            padding: EdgeInsets.fromLTRB(20, 4, 20, 16 + bottomPad),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                OptionRow(
                  icon: Icons.replay_rounded,
                  label: 'Clear resume position',
                  onTap: canClearResume ? onClearResume : null,
                  color: canClearResume ? null : context.colors.textMuted,
                ),
                OptionRow(
                  icon: Icons.drive_file_move_outline,
                  label: 'Move to album',
                  onTap: onMoveToAlbum,
                ),
                OptionRow(
                  icon: Icons.copy_all_outlined,
                  label: 'Copy to album',
                  onTap: onCopyToAlbum,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
