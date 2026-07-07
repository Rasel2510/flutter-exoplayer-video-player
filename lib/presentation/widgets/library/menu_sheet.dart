import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../providers/continue_watching_provider.dart';
import '../../providers/library_appearance_provider.dart';
import '../../../screens/vault_pin_screen.dart';
import '../../../screens/vault_screen.dart';
import '../../../services/vault_pin_service.dart';
import '../common/sheet_surface.dart';
import '../smooth_page_route.dart';

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
            
            // Secure Vault action. Gated by the vault's OWN PIN (set up on
            // first visit), not the device's screen-lock credential — see
            // VaultPinScreen. The PIN screen is pushed on top of this still-open
            // sheet; only after it reports success do we pop the sheet and
            // push VaultScreen, mirroring how every other async-then-navigate
            // handler in this sheet is guarded by `context.mounted`.
            InkWell(
              onTap: () async {
                final hasPin = await VaultPinService.instance.hasPin();
                if (!context.mounted) return;
                final mode =
                    hasPin ? VaultPinMode.unlock : VaultPinMode.create;
                final unlocked = await Navigator.push<bool>(
                  context,
                  SmoothPageRoute(child: VaultPinScreen(mode: mode)),
                );
                if (unlocked == true && context.mounted) {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    SmoothPageRoute(child: const VaultScreen()),
                  );
                }
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Row(
                  children: [
                    Icon(
                      Icons.lock_rounded,
                      color: context.colors.textSecondary,
                      size: 24,
                    ),
                    const SizedBox(width: 16),
                    Text(
                      'Secure Vault',
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
              label: 'Folder icon color',
              selectedIndex: appearance.folderIconColorIndex,
              themeDefault: context.colors.folderIcon,
              onSelect: appearanceNotifier.setFolderIconColorIndex,
              leadingBuilder: (color) =>
                  Icon(Icons.folder_rounded, color: color, size: 22),
            ),

            // New badge color. Same themeDefault as NewBadge/NewVideoBadge use.
            _AccentColorRow(
              label: 'New badge color',
              selectedIndex: appearance.newBadgeColorIndex,
              themeDefault: context.colors.folderIcon,
              onSelect: appearanceNotifier.setNewBadgeColorIndex,
              // Preview the actual NEW badge chip rather than a generic icon
              // so this row shows exactly what folder/video lists render.
              leadingBuilder: (color) => _NewBadgePreview(color: color),
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
  final String label;
  final int selectedIndex;
  final Color themeDefault;
  final void Function(int index) onSelect;
  final Widget Function(Color color) leadingBuilder;

  const _AccentColorRow({
    required this.label,
    required this.selectedIndex,
    required this.themeDefault,
    required this.onSelect,
    required this.leadingBuilder,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              leadingBuilder(resolveLibraryAccent(selectedIndex, themeDefault)),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(fontSize: 15, color: context.colors.textPrimary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Horizontally scrollable so the swatch strip never overflows the
          // row, no matter how many presets libraryAccentPresets grows to —
          // mirrors the font-chip strip in the subtitle appearance sheet.
          SizedBox(
            height: 26,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              clipBehavior: Clip.none,
              itemCount: libraryAccentPresets.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (_, i) => GestureDetector(
                onTap: () => onSelect(i),
                child: _Swatch(
                  color: resolveLibraryAccent(i, themeDefault),
                  isTheme: libraryAccentPresets[i].color == null,
                  selected: selectedIndex == i,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Mirrors NewBadge/NewVideoBadge's decoration exactly so this settings-row
/// preview is a true WYSIWYG match for the chip shown on folder/video lists.
class _NewBadgePreview extends StatelessWidget {
  final Color color;

  const _NewBadgePreview({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
      ),
      child: Text(
        'NEW',
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w800,
          color: color,
          letterSpacing: 0.8,
        ),
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
