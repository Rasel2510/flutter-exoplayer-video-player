import 'package:flutter/material.dart';
import 'package:flutter_video_player/core/theme/app_theme.dart';

/// The Secure Vault's app bar. Swaps between the normal title + actions
/// (select / overflow menu) and the selection-mode title + select-all,
/// mirroring FolderVideosAppBar's pattern.
class VaultAppBar extends StatelessWidget implements PreferredSizeWidget {
  final bool selectionMode;
  final int selectedCount;
  final bool hasVideos;

  final VoidCallback onBack;
  final VoidCallback onExitSelection;
  final VoidCallback onSelectAll;
  final VoidCallback onEnterSelection;
  final VoidCallback onMenu;

  const VaultAppBar({
    super.key,
    required this.selectionMode,
    required this.selectedCount,
    required this.hasVideos,
    required this.onBack,
    required this.onExitSelection,
    required this.onSelectAll,
    required this.onEnterSelection,
    required this.onMenu,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: context.colors.bg,
      scrolledUnderElevation: 0,
      title: Text(
        selectionMode ? '$selectedCount selected' : 'Secure Vault',
        style: TextStyle(
          color: context.colors.textPrimary,
          fontWeight: FontWeight.w600,
        ),
      ),
      leading: IconButton(
        icon: Icon(
          selectionMode ? Icons.close_rounded : Icons.arrow_back_rounded,
          color: context.colors.textPrimary,
        ),
        onPressed: selectionMode ? onExitSelection : onBack,
      ),
      actions: [
        if (selectionMode)
          IconButton(
            icon: Icon(Icons.select_all_rounded, color: context.colors.textPrimary),
            tooltip: 'Select all',
            onPressed: onSelectAll,
          )
        else ...[
          if (hasVideos)
            IconButton(
              icon: Icon(Icons.checklist_rounded, color: context.colors.textPrimary),
              tooltip: 'Select',
              onPressed: onEnterSelection,
            ),
          IconButton(
            icon: Icon(Icons.more_vert_rounded, color: context.colors.textPrimary),
            tooltip: 'Vault settings',
            onPressed: onMenu,
          ),
        ],
      ],
    );
  }
}
