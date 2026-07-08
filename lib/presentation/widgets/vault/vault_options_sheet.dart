import 'package:flutter/material.dart';
import 'package:flutter_video_player/core/theme/app_theme.dart';
import 'package:flutter_video_player/data/models/video_file.dart';
import 'package:flutter_video_player/presentation/widgets/common/sheet_surface.dart';
import 'vault_option_row.dart';

/// Per-item bottom sheet for a vault video: Play, Restore, Select, Delete.
/// Mirrors VideoOptionsSheet's structure and chrome (SheetSurface + rows) so
/// the vault matches the rest of the app's bottom sheets.
class VaultOptionsSheet extends StatelessWidget {
  final VideoFile vf;
  final VoidCallback onPlay;
  final VoidCallback onRestore;
  final VoidCallback onSelect;
  final VoidCallback onDelete;

  const VaultOptionsSheet({
    super.key,
    required this.vf,
    required this.onPlay,
    required this.onRestore,
    required this.onSelect,
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
            Padding(
              padding: EdgeInsets.fromLTRB(20, 4, 20, 16 + bottomPad),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  VaultOptionRow(
                    icon: Icons.play_arrow_rounded,
                    label: 'Play',
                    onTap: onPlay,
                  ),
                  VaultOptionRow(
                    icon: Icons.restore_rounded,
                    label: 'Restore from Vault',
                    color: context.colors.accent,
                    onTap: onRestore,
                  ),
                  VaultOptionRow(
                    icon: Icons.check_circle_outline_rounded,
                    label: 'Select',
                    onTap: onSelect,
                  ),
                  VaultOptionRow(
                    icon: Icons.delete_outline_rounded,
                    label: 'Delete permanently',
                    color: context.colors.errorRed,
                    onTap: onDelete,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
