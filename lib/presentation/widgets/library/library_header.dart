import 'package:flutter/material.dart';
import 'package:flutter_video_player/core/theme/app_theme.dart';

class LibraryHeader extends StatelessWidget {
  final int folderCount;
  final int? filteredCount;
  final int? storageCount;
  final bool isScanning;
  final bool fromCache;
  final bool searchOpen;
  final TextEditingController searchCtrl;
  final VoidCallback onToggleSearch;
  final VoidCallback? onRescan;

  const LibraryHeader({
    super.key,
    required this.folderCount,
    required this.isScanning,
    required this.fromCache,
    required this.searchOpen,
    required this.searchCtrl,
    required this.onToggleSearch,
    required this.onRescan,
    this.filteredCount,
    this.storageCount,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 6, 8, 2),
          child: Row(
            children: [
              if (filteredCount != null)
                Text(
                  '$filteredCount of $folderCount folder${folderCount == 1 ? '' : 's'}',
                  style: context.textStyles.label,
                )
              else
                Text(
                  '$folderCount folder${folderCount == 1 ? '' : 's'}',
                  style: context.textStyles.label,
                ),
              if (storageCount != null) ...[
                const SizedBox(width: 8),
                Text('· $storageCount storages',
                    style: context.textStyles.caption),
              ],
              const Spacer(),
              if (isScanning)
                const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 1.5),
                ),
              if (fromCache && !isScanning)
                Text('cached', style: context.textStyles.caption),
              // Search toggle
              IconButton(
                icon: Icon(
                  searchOpen ? Icons.search_off_rounded : Icons.search_rounded,
                  size: 20,
                  color: searchOpen
                      ? context.colors.accent
                      : context.colors.textSecondary,
                ),
                onPressed: onToggleSearch,
                tooltip: searchOpen ? 'Close search' : 'Search folders',
                visualDensity: VisualDensity.compact,
              ),
              TextButton(
                onPressed: onRescan,
                style: TextButton.styleFrom(
                  minimumSize: Size.zero,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  'Rescan',
                  style: TextStyle(
                    fontSize: 12,
                    color: isScanning
                        ? context.colors.textMuted
                        : context.colors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ),
        // Animated search bar
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: searchOpen
              ? Padding(
                  key: const ValueKey('search'),
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: TextField(
                    controller: searchCtrl,
                    autofocus: true,
                    textInputAction: TextInputAction.search,
                    style: TextStyle(
                        color: context.colors.textPrimary, fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'Search folders…',
                      prefixIcon: Icon(Icons.search_rounded,
                          size: 18, color: context.colors.textMuted),
                      suffixIcon: ValueListenableBuilder<TextEditingValue>(
                        valueListenable: searchCtrl,
                        builder: (context, value, child) {
                          if (value.text.isEmpty) return const SizedBox.shrink();
                          return IconButton(
                            icon: Icon(Icons.clear_rounded,
                                size: 16, color: context.colors.textMuted),
                            onPressed: searchCtrl.clear,
                          );
                        },
                      ),
                    ),
                  ),
                )
              : const SizedBox(key: ValueKey('no-search'), height: 0),
        ),
      ],
    );
  }
}
