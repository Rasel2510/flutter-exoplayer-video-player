part of 'player_controls_overlay.dart';

class _BottomBarActions extends ConsumerWidget {
  final VoidCallback onCycleFitMode;
  final VoidCallback onToggleFullscreen;
  final VoidCallback onPip;
  final VoidCallback onToggleLock;

  const _BottomBarActions({
    required this.onCycleFitMode,
    required this.onToggleFullscreen,
    required this.onPip,
    required this.onToggleLock,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final (:fitMode, :rotationMode) = ref.watch(playerProvider.select((s) => (
          fitMode: s.fitMode,
          rotationMode: s.rotationMode,
        )));

    return Row(
      children: [
        // Lock — bottom-left corner.
        _GlassIconButton(
          icon: Icons.lock_open_rounded,
          size: 20,
          onTap: onToggleLock,
          filled: true,
        ),
        const Spacer(),
        // Picture-in-Picture — keep the video playing in a floating window.
        _GlassIconButton(
          icon: Icons.picture_in_picture_alt_rounded,
          size: 20,
          onTap: onPip,
          filled: true,
        ),
        const SizedBox(width: 10),
        _MiniChip(label: fitMode.label, onTap: onCycleFitMode),
        const SizedBox(width: 10),
        _GlassIconButton(
          icon: switch (rotationMode) {
            RotationMode.auto => Icons.screen_rotation_rounded,
            RotationMode.landscape => Icons.stay_current_landscape_rounded,
            RotationMode.portrait => Icons.stay_current_portrait_rounded,
          },
          size: 22,
          onTap: onToggleFullscreen,
          filled: true,
        ),
      ],
    );
  }
}

// ── Custom minimalist slider ──────────────────────────────────────────────────


