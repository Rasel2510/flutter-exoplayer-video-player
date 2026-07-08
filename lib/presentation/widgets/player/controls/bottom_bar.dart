part of 'player_controls_overlay.dart';

class _BottomBar extends StatelessWidget {
  final void Function(double) onSeekStart;
  final void Function(double) onSeekUpdate;
  final void Function(double) onSeekEnd;
  final VoidCallback onToggleFullscreen;
  final VoidCallback onCycleFitMode;
  final VoidCallback onPip;
  final VoidCallback onToggleLock;

  const _BottomBar({
    required this.onSeekStart,
    required this.onSeekUpdate,
    required this.onSeekEnd,
    required this.onToggleFullscreen,
    required this.onCycleFitMode,
    required this.onPip,
    required this.onToggleLock,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _PlaybackProgressControls(
            onSeekStart: onSeekStart,
            onSeekUpdate: onSeekUpdate,
            onSeekEnd: onSeekEnd,
          ),
          const SizedBox(height: 8),
          _BottomBarActions(
            onCycleFitMode: onCycleFitMode,
            onToggleFullscreen: onToggleFullscreen,
            onPip: onPip,
            onToggleLock: onToggleLock,
          ),
        ],
      ),
    );
  }
}


