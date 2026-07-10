import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_video_player/core/theme/app_theme.dart';
import 'package:flutter_video_player/presentation/providers/continue_watching_provider.dart';
import 'package:flutter_video_player/presentation/providers/library_appearance_provider.dart';
import 'package:flutter_video_player/presentation/providers/library_card_style_provider.dart';
import 'package:flutter_video_player/presentation/providers/player_controls_style_provider.dart';
import 'package:flutter_video_player/presentation/screens/vault_pin_screen.dart';
import 'package:flutter_video_player/presentation/screens/vault_screen.dart';
import 'package:flutter_video_player/data/services/vault_pin_service.dart';
import 'package:flutter_video_player/presentation/widgets/common/sheet_surface.dart';
import 'package:flutter_video_player/presentation/widgets/common/smooth_page_route.dart';

/// A beautiful bottom sheet for app settings and overflow actions.
class MenuSheet extends StatelessWidget {
  final VoidCallback onOpenFile;

  const MenuSheet({
    super.key,
    required this.onOpenFile,
  });

  @override
  Widget build(BuildContext context) {
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

            // Each toggle below watches only its own provider inside its own
            // Consumer, so flipping one switch rebuilds just that row instead
            // of the whole sheet (including the two accent-color rows below).
            Consumer(
              builder: (context, ref, _) {
                final enabled = ref.watch(continueWatchingEnabledProvider);
                return _SettingsToggleRow(
                  icon: Icons.history_toggle_off_rounded,
                  activeIcon: Icons.history_rounded,
                  label: 'Continue Watching',
                  subtitle: 'Show your recently watched videos',
                  value: enabled,
                  onToggle: () => ref
                      .read(continueWatchingEnabledProvider.notifier)
                      .toggle(),
                );
              },
            ),

            // Off = flat black tint (default), on = real backdrop-blur glass
            // behind the player buttons.
            Consumer(
              builder: (context, ref, _) {
                final frosted = ref.watch(controlsStyleProvider) ==
                    PlayerControlsStyle.frosted;
                return _SettingsToggleRow(
                  icon: Icons.blur_off_rounded,
                  activeIcon: Icons.blur_on_rounded,
                  label: 'Frosted player controls',
                  subtitle: 'Blur the video behind the player buttons',
                  value: frosted,
                  onToggle: () =>
                      ref.read(controlsStyleProvider.notifier).toggle(),
                );
              },
            ),

            // Off = standard opaque cards (default), on = translucent glass
            // folder/video cards.
            Consumer(
              builder: (context, ref, _) {
                final tinted =
                    ref.watch(cardStyleProvider) == LibraryCardStyle.tinted;
                return _SettingsToggleRow(
                  icon: Icons.dashboard_outlined,
                  activeIcon: Icons.dashboard_rounded,
                  label: 'Tinted card style',
                  subtitle: 'Glassy translucent folder & video cards',
                  value: tinted,
                  onToggle: () =>
                      ref.read(cardStyleProvider.notifier).toggle(),
                );
              },
            ),

            Divider(color: context.colors.divider, height: 1),

            // Folder icon color. themeDefault matches what FolderCard actually
            // falls back to for the "Theme" preset, so the preview ring here
            // shows the same color the icon renders — not a generic accent.
            // Watches only its own field of libraryAppearanceProvider, so
            // picking a new badge color doesn't also rebuild this row.
            Consumer(
              builder: (context, ref, _) {
                final index = ref.watch(libraryAppearanceProvider
                    .select((a) => a.folderIconColorIndex));
                return _AccentColorRow(
                  label: 'Folder icon color',
                  selectedIndex: index,
                  themeDefault: context.colors.folderIcon,
                  onSelect: ref
                      .read(libraryAppearanceProvider.notifier)
                      .setFolderIconColorIndex,
                  leadingBuilder: (color) =>
                      Icon(Icons.folder_rounded, color: color, size: 22),
                );
              },
            ),

            // New badge color. Same themeDefault as NewBadge/NewVideoBadge use.
            Consumer(
              builder: (context, ref, _) {
                final index = ref.watch(libraryAppearanceProvider
                    .select((a) => a.newBadgeColorIndex));
                return _AccentColorRow(
                  label: 'New badge color',
                  selectedIndex: index,
                  themeDefault: context.colors.folderIcon,
                  onSelect: ref
                      .read(libraryAppearanceProvider.notifier)
                      .setNewBadgeColorIndex,
                  // Preview the actual NEW badge chip rather than a generic
                  // icon so this row shows exactly what folder/video lists
                  // render.
                  leadingBuilder: (color) => _NewBadgePreview(color: color),
                );
              },
            ),

            SizedBox(height: 16 + MediaQuery.of(context).padding.bottom),
          ],
        ),
      ),
    );
  }
}

/// A settings row with a leading icon, a label + subtitle, and a trailing
/// switch. Shared by every boolean toggle in this sheet (Continue Watching,
/// Frosted player controls, Tinted card style) so they render identically
/// from one definition instead of three copy-pasted blocks.
class _SettingsToggleRow extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final String subtitle;
  final bool value;
  final VoidCallback onToggle;

  const _SettingsToggleRow({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.subtitle,
    required this.value,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onToggle,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Row(
          children: [
            Icon(
              value ? activeIcon : icon,
              color: value ? context.colors.accent : context.colors.textSecondary,
              size: 24,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 16,
                      color: value
                          ? context.colors.textPrimary
                          : context.colors.textSecondary,
                      fontWeight: value ? FontWeight.w500 : FontWeight.w400,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 12, color: context.colors.textMuted),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            IgnorePointer(
              child: Switch(
                value: value,
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
    );
  }
}

/// A settings row for picking one of [libraryAccentPresets] — an icon + label
/// on the left, a horizontally scrollable strip of color swatches on the
/// right. Mirrors the color-preset pickers already used in the subtitle
/// appearance sheet.
class _AccentColorRow extends StatefulWidget {
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
  State<_AccentColorRow> createState() => _AccentColorRowState();
}

class _AccentColorRowState extends State<_AccentColorRow> {
  final _scrollController = ScrollController();
  // Only fade the trailing edge when the strip actually has more to scroll
  // to — otherwise a layout wide enough to show every preset (tablets,
  // landscape) would dim the last swatch even though nothing is hidden.
  bool _canScroll = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_updateCanScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) => _updateCanScroll());
  }

  @override
  void dispose() {
    _scrollController.removeListener(_updateCanScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _updateCanScroll() {
    if (!_scrollController.hasClients) return;
    final canScroll = _scrollController.position.maxScrollExtent > 0;
    if (canScroll != _canScroll) setState(() => _canScroll = canScroll);
  }

  @override
  Widget build(BuildContext context) {
    final strip = SizedBox(
      height: 26,
      child: ListView.separated(
        controller: _scrollController,
        scrollDirection: Axis.horizontal,
        clipBehavior: Clip.none,
        // Trailing pad so the last swatch can scroll clear of the fade.
        padding: EdgeInsets.only(right: _canScroll ? 28 : 0),
        itemCount: libraryAccentPresets.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (_, i) => GestureDetector(
          onTap: () => widget.onSelect(i),
          child: _Swatch(
            color: resolveLibraryAccent(i, widget.themeDefault),
            isTheme: libraryAccentPresets[i].color == null,
            selected: widget.selectedIndex == i,
          ),
        ),
      ),
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              widget.leadingBuilder(
                  resolveLibraryAccent(widget.selectedIndex, widget.themeDefault)),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  widget.label,
                  style: TextStyle(fontSize: 15, color: context.colors.textPrimary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Horizontally scrollable so the swatch strip never overflows the
          // row, no matter how many presets libraryAccentPresets grows to —
          // mirrors the font-chip strip in the subtitle appearance sheet. The
          // right edge fades out (ShaderMask) only while there's still more
          // to scroll to, so it's a real "more content" hint rather than a
          // permanent dimming of the last swatch.
          _canScroll
              ? ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [Colors.white, Colors.white, Colors.transparent],
                    stops: [0.0, 0.9, 1.0],
                  ).createShader(bounds),
                  blendMode: BlendMode.dstIn,
                  child: strip,
                )
              : strip,
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
