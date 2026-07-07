import 'package:flutter/material.dart';
import 'package:flutter_video_player/core/theme/app_theme.dart';

/// The folder screen's app bar. Swaps between the normal title + actions
/// (search / sort / multi-select) and the selection-mode title + select-all.
class FolderVideosAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String folderName;
  final int displayCount;
  final int totalCount;
  final bool isFiltered;
  final String totalSizeLabel;

  final bool selectionMode;
  final int selectedCount;
  final bool searchOpen;

  final VoidCallback onBack;
  final VoidCallback onExitSelection;
  final VoidCallback onSelectAll;
  final VoidCallback onToggleSearch;
  final VoidCallback onShowSort;
  final VoidCallback onEnterSelection;
  // Null when nothing is selected, which disables the button.
  final VoidCallback? onMoveToVault;

  const FolderVideosAppBar({
    super.key,
    required this.folderName,
    required this.displayCount,
    required this.totalCount,
    required this.isFiltered,
    required this.totalSizeLabel,
    required this.selectionMode,
    required this.selectedCount,
    required this.searchOpen,
    required this.onBack,
    required this.onExitSelection,
    required this.onSelectAll,
    required this.onToggleSearch,
    required this.onShowSort,
    required this.onEnterSelection,
    this.onMoveToVault,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final allSelected = selectedCount == displayCount;
    return AppBar(
      leading: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        child: IconButton(
          key: ValueKey('leading_$selectionMode'),
          icon: Icon(
              selectionMode ? Icons.close_rounded : Icons.arrow_back_rounded),
          onPressed: selectionMode ? onExitSelection : onBack,
        ),
      ),
      title: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        child: selectionMode
            ? Text(
                '$selectedCount selected',
                key: const ValueKey('title_sel'),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: context.colors.textPrimary,
                ),
              )
            : Column(
                key: const ValueKey('title_norm'),
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    folderName,
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: context.colors.textPrimary,
                        letterSpacing: -0.2),
                  ),
                  Text(
                    '$displayCount${isFiltered ? ' of $totalCount' : ''} '
                    'video${totalCount == 1 ? '' : 's'}'
                    ' · $totalSizeLabel',
                    style: context.textStyles.caption,
                  ),
                ],
              ),
      ),
      actions: [
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: Row(
            key: ValueKey('actions_$selectionMode'),
            mainAxisSize: MainAxisSize.min,
            children: selectionMode
                ? [
                    IconButton(
                      icon: Icon(
                        allSelected
                            ? Icons.select_all_rounded
                            : Icons.checklist_rounded,
                      ),
                      tooltip: allSelected ? 'Deselect all' : 'Select all',
                      onPressed: onSelectAll,
                    ),
                    IconButton(
                      icon: const Icon(Icons.lock_rounded),
                      tooltip: 'Move to Vault',
                      onPressed: onMoveToVault,
                    ),
                  ]
                : [
                    IconButton(
                      icon: Icon(
                        searchOpen ? Icons.search_off_rounded : Icons.search_rounded,
                        size: 20,
                        color: searchOpen
                            ? context.colors.accent
                            : context.colors.textSecondary,
                      ),
                      tooltip: searchOpen ? 'Close search' : 'Search',
                      onPressed: onToggleSearch,
                    ),
                    IconButton(
                      icon: const Icon(Icons.sort_rounded),
                      tooltip: 'Sort',
                      onPressed: onShowSort,
                    ),
                    IconButton(
                      icon: const Icon(Icons.checklist_rounded),
                      tooltip: 'Select multiple',
                      onPressed: onEnterSelection,
                    ),
                  ],
          ),
        ),
      ],
    );
  }
}
