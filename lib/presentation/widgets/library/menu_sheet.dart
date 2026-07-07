import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../providers/continue_watching_provider.dart';
import '../../providers/library_appearance_provider.dart';
import '../common/sheet_surface.dart';

/// A beautiful bottom sheet for app settings and overflow actions.
class MenuSheet extends ConsumerWidget {
  final VoidCallback onOpenFile;

  const MenuSheet({
    super.key,
    required this.onOpenFile,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cwEnabled = ref.watch(continueWatchingEnabledProvider);
    final appearance = ref.watch(libraryAppearanceProvider);
    final appearanceNotifier = ref.read(libraryAppearanceProvider.notifier);

    return SheetSurface(
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: Row(
                children: [
                  Icon(Icons.settings_rounded,
                      color: context.colors.accent, size: 18),
                  const SizedBox(width: 10),
                  Text(
                    'Settings',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: context.colors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            
            Divider(color: context.colors.divider, height: 1),
            
            // Open File action
            InkWell(
              onTap: () {
                Navigator.pop(context);
                onOpenFile();
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Row(
                  children: [
                    Icon(
                      Icons.add_rounded,
                      color: context.colors.textSecondary,
                      size: 24,
                    ),
                    const SizedBox(width: 16),
                    Text(
                      'Open file...',
                      style: TextStyle(
                        fontSize: 16,
                        color: context.colors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            // Continue Watching toggle
            InkWell(
              onTap: () {
                ref.read(continueWatchingEnabledProvider.notifier).toggle();
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Row(
                  children: [
                    Icon(
                      cwEnabled ? Icons.history_rounded : Icons.history_toggle_off_rounded,
                      color: cwEnabled ? context.colors.accent : context.colors.textSecondary,
                      size: 24,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Continue Watching',
                            style: TextStyle(
                              fontSize: 16,
                              color: cwEnabled ? context.colors.textPrimary : context.colors.textSecondary,
                              fontWeight: cwEnabled ? FontWeight.w500 : FontWeight.w400,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Show your recently watched videos',
                            style: TextStyle(
                              fontSize: 12,
                              color: context.colors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    IgnorePointer(
                      child: Switch(
                        value: cwEnabled,
                        onChanged: (_) {},
                        activeThumbColor: context.colors.surface,
                        activeTrackColor: context.colors.accent,
                        inactiveThumbColor: context.colors.surface,
                        inactiveTrackColor: context.colors.border,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            Divider(color: context.colors.divider, height: 1),

            // Folder icon color. themeDefault matches what FolderCard actually
            // falls back to for the "Theme" preset, so the preview ring here
            // shows the same color the icon renders — not a generic accent.
            _AccentColorRow(
              icon: Icons.folder_rounded,
              label: 'Folder icon color',
              selectedIndex: appearance.folderIconColorIndex,
              themeDefault: context.colors.folderIcon,
              onSelect: appearanceNotifier.setFolderIconColorIndex,
            ),

            // New badge color. Same themeDefault as NewBadge/NewVideoBadge use.
            _AccentColorRow(
              icon: Icons.fiber_new_rounded,
              label: 'New badge color',
              selectedIndex: appearance.newBadgeColorIndex,
              themeDefault: context.colors.folderIcon,
              onSelect: appearanceNotifier.setNewBadgeColorIndex,
            ),

            SizedBox(height: 16 + MediaQuery.of(context).padding.bottom),
          ],
        ),
      ),
    );
  }
}

/// A settings row for picking one of [libraryAccentPresets] — an icon + label
/// on the left, a horizontally scrollable strip of color swatches on the
/// right. Mirrors the color-preset pickers already used in the subtitle
/// appearance sheet.
class _AccentColorRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final int selectedIndex;
  final Color themeDefault;
  final void Function(int index) onSelect;

  const _AccentColorRow({
    required this.icon,
    required this.label,
    required this.selectedIndex,
    required this.themeDefault,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
      child: Row(
        children: [
          Icon(icon, color: context.colors.textSecondary, size: 22),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              label,
              style: TextStyle(fontSize: 15, color: context.colors.textPrimary),
            ),
          ),
          const SizedBox(width: 8),
          for (var i = 0; i < libraryAccentPresets.length; i++)
            Padding(
              padding: const EdgeInsets.only(left: 8),
              child: GestureDetector(
                onTap: () => onSelect(i),
                child: _Swatch(
                  color: resolveLibraryAccent(i, themeDefault),
                  isTheme: libraryAccentPresets[i].color == null,
                  selected: selectedIndex == i,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _Swatch extends StatelessWidget {
  final Color color;
  final bool isTheme;
  final bool selected;

  const _Swatch({
    required this.color,
    required this.isTheme,
    required this.selected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        // The "Theme" swatch is a ring around the current accent rather than
        // a filled dot, so it reads as "follows the app" not "a fixed color".
        border: Border.all(
          color: selected
              ? context.colors.textPrimary
              : (isTheme ? color : context.colors.border),
          width: selected ? 2 : 1,
        ),
      ),
      child: isTheme
          ? Icon(Icons.brightness_6_rounded,
              size: 12, color: context.colors.bg)
          : null,
    );
  }
}
