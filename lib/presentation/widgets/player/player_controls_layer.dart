import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_video_player/presentation/providers/player_provider.dart';
import 'controls/player_controls_overlay.dart';

/// Wraps [PlayerControlsOverlay] with its visibility Consumer + fade
/// transition, and forwards every callback the overlay needs.
class PlayerControlsLayer extends ConsumerWidget {
  final String fallbackFileName;
  final VoidCallback onBack;
  final VoidCallback onTogglePlay;
  final VoidCallback onCycleFitMode;
  final VoidCallback onShowSpeed;
  final VoidCallback onShowVolume;
  final VoidCallback onShowAudio;
  final VoidCallback onShowSubtitle;
  final VoidCallback onSeekBack;
  final VoidCallback onSeekForward;
  final VoidCallback onToggleFullscreen;
  final void Function(double) onSeekStart;
  final void Function(double) onSeekUpdate;
  final void Function(double) onSeekEnd;
  final VoidCallback onPlayNext;
  final VoidCallback onPlayPrevious;
  final VoidCallback onToggleLock;
  final VoidCallback onToggleRepeat;
  final VoidCallback onAudioMode;
  final VoidCallback onSleepTimer;
  final VoidCallback onPip;
  final VoidCallback onCycleAbRepeat;

  const PlayerControlsLayer({
    super.key,
    required this.fallbackFileName,
    required this.onBack,
    required this.onTogglePlay,
    required this.onCycleFitMode,
    required this.onShowSpeed,
    required this.onShowVolume,
    required this.onShowAudio,
    required this.onShowSubtitle,
    required this.onSeekBack,
    required this.onSeekForward,
    required this.onToggleFullscreen,
    required this.onSeekStart,
    required this.onSeekUpdate,
    required this.onSeekEnd,
    required this.onPlayNext,
    required this.onPlayPrevious,
    required this.onToggleLock,
    required this.onToggleRepeat,
    required this.onAudioMode,
    required this.onSleepTimer,
    required this.onPip,
    required this.onCycleAbRepeat,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final (
      :isInitialized,
      :hasError,
      :isLocked,
      :controlsVisible,
      :currentVideo
    ) = ref.watch(playerProvider.select((s) => (
          isInitialized: s.isInitialized,
          hasError: s.hasError,
          isLocked: s.isLocked,
          controlsVisible: s.controlsVisible,
          currentVideo: s.currentVideo,
        )));
    if (!isInitialized || hasError) return const SizedBox();
    final displayName = currentVideo?.name ?? fallbackFileName;

    // Keep controls in the widget tree when hidden (opacity=0) so Flutter
    // never tears down the platform-view compositor layer.
    //
    // IMPORTANT: always use the SAME widget type (AnimatedOpacity)
    // regardless of visibility. Switching between AnimatedOpacity and
    // Opacity causes Flutter to rebuild the subtree, which triggers a white
    // compositor-layer flash over the video platform view in release builds
    // — the exact "white screen" seen when tapping the lock icon.
    //
    // Using Duration.zero when hiding gives an instant hide without any
    // intermediate saveLayer, while keeping the widget type stable avoids
    // the destructive rebuild entirely.
    final visible = controlsVisible && !isLocked;
    final child = IgnorePointer(
      ignoring: !visible,
      child: PlayerControlsOverlay(
        fileName: displayName,
        onBack: onBack,
        onTogglePlay: onTogglePlay,
        onCycleFitMode: onCycleFitMode,
        onShowSpeed: onShowSpeed,
        onShowVolume: onShowVolume,
        onShowAudio: onShowAudio,
        onShowSubtitle: onShowSubtitle,
        onSeekBack: onSeekBack,
        onSeekForward: onSeekForward,
        onToggleFullscreen: onToggleFullscreen,
        onSeekStart: onSeekStart,
        onSeekUpdate: onSeekUpdate,
        onSeekEnd: onSeekEnd,
        onPlayNext: onPlayNext,
        onPlayPrevious: onPlayPrevious,
        onToggleLock: onToggleLock,
        onToggleRepeat: onToggleRepeat,
        onAudioMode: onAudioMode,
        onSleepTimer: onSleepTimer,
        onPip: onPip,
        onCycleAbRepeat: onCycleAbRepeat,
      ),
    );
    return AnimatedOpacity(
      opacity: visible ? 1.0 : 0.0,
      // Fade-in when showing; instant (0 ms) when hiding so there is no
      // intermediate compositor layer to flash white.
      duration: visible ? const Duration(milliseconds: 200) : Duration.zero,
      child: child,
    );
  }
}
