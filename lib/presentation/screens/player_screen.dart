import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_video_player/data/models/video_file.dart';
import 'package:flutter_video_player/presentation/providers/player_provider.dart';
import 'package:flutter_video_player/presentation/widgets/player/player_controls_layer.dart';
import 'package:flutter_video_player/presentation/widgets/player/player_gesture_layer.dart';
import 'package:flutter_video_player/presentation/widgets/player/player_lock_layer.dart';
import 'package:flutter_video_player/presentation/widgets/player/player_video_layer.dart';
import 'package:flutter_video_player/presentation/widgets/player/sheets/speed_sheet.dart';
import 'package:flutter_video_player/presentation/widgets/player/overlays/subtitle_overlay.dart';
import 'package:flutter_video_player/presentation/widgets/player/sheets/volume_sheet.dart';
import 'package:flutter_video_player/presentation/widgets/player/sheets/audio_track_sheet.dart';
import 'package:flutter_video_player/presentation/widgets/player/sheets/subtitle_sheet.dart';
import 'package:flutter_video_player/presentation/widgets/player/sheets/sleep_timer_sheet.dart';
import 'package:flutter_video_player/data/services/media_session_service.dart';
import 'package:flutter_video_player/presentation/widgets/player/overlays/auto_play_countdown.dart';
import 'package:flutter_video_player/presentation/widgets/player/overlays/swipe_hud.dart';
import 'package:flutter_video_player/presentation/widgets/player/overlays/zoom_indicator_overlay.dart';

class PlayerScreen extends ConsumerStatefulWidget {
  final String filePath;
  final String fileName;
  final Duration? resumeFrom;
  final List<VideoFile> folderVideos;
  final int initialIndex;

  const PlayerScreen({
    super.key,
    required this.filePath,
    required this.fileName,
    this.resumeFrom,
    this.folderVideos = const [],
    this.initialIndex = -1,
  });

  @override
  ConsumerState<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends ConsumerState<PlayerScreen>
    with TickerProviderStateMixin {
  // ── Lock icon animation ────────────────────────────────────────────────────
  // Driven locally so showing/hiding the lock icon never triggers a state
  // update → no Consumer rebuild → no platform-view re-composite → no white flash.
  late final AnimationController _lockIconCtrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 250),
  );
  late final AnimationController _exitCtrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 160),
  );
  Timer? _lockIconLocalTimer;

  // True once the route is popping. dispose() resets the provider to a fresh
  // PlayerState (isInitialized=false), which would otherwise re-show the
  // loading spinner over the screen while the pop transition is still running —
  // looking like the app "loads" on the way out. While leaving we show the
  // black background instead so the exit is clean and instant.
  bool _leaving = false;
  bool _isExiting = false;

  // Convenience getter — ref.read(playerProvider.notifier) repeated in build()
  // is equivalent each call (provider identity is stable), but a getter makes
  // the intent clear and avoids typos.
  PlayerNotifier get _notifier => ref.read(playerProvider.notifier);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _notifier.init(
        widget.filePath,
        resumeFrom: widget.resumeFrom,
        folderVideos: widget.folderVideos,
        initialIndex: widget.initialIndex,
      );
    });
  }

  @override
  void dispose() {
    _lockIconCtrl.dispose();
    _exitCtrl.dispose();
    _lockIconLocalTimer?.cancel();
    // leaveScreen keeps the player alive when audio mode is on; otherwise it
    // fully disposes. Guarded internally against the double call from PopScope.
    _notifier.leaveScreen();
    super.dispose();
  }

  // ── Lock icon helpers ──────────────────────────────────────────────────────

  /// Show the lock icon using a local AnimationController — never updates
  /// provider state — so the Video platform view is never re-composited.
  void _showLockIconLocal() {
    _lockIconCtrl.forward();
    _lockIconLocalTimer?.cancel();
    _lockIconLocalTimer = Timer(const Duration(seconds: 2), () {
      if (mounted) _lockIconCtrl.reverse();
    });
  }

  void _hideLockIconLocal() {
    _lockIconLocalTimer?.cancel();
    _lockIconCtrl.reverse();
  }

  // ── Sheet helpers ──────────────────────────────────────────────────────────

  void _showSpeedSheet(BuildContext ctx, double speed, int seekInterval) =>
      showModalBottomSheet(
        context: ctx,
        useSafeArea: true,
        // Allow the sheet to take the height SheetSurface asks for so its
        // content scrolls instead of overflowing in landscape.
        isScrollControlled: true,
        // Prevent Flutter from drawing its own system drag handle on top of
        // the sheet's built-in handle, which caused a double-bar appearance.
        showDragHandle: false,
        // The sheet Container already has its own rounded background colour.
        // Without this, the Modal's default white/surface background bleeds
        // through the rounded corners making the sheet look semi-transparent.
        backgroundColor: Colors.transparent,
        builder: (_) => SpeedSheet(
          currentSpeed: speed,
          currentSeekInterval: seekInterval,
          onSelectSpeed: (s) => _notifier.setSpeed(s),
          onSelectSeekInterval: (s) => _notifier.setSeekInterval(s),
        ),
      );

  void _showVolumeSheet(BuildContext ctx, double volume) =>
      showModalBottomSheet(
        context: ctx,
        useSafeArea: true,
        isScrollControlled: true,
        showDragHandle: false,
        backgroundColor: Colors.transparent,
        builder: (_) => VolumeSheet(
          volume: volume,
          onChanged: (v) => _notifier.setVolume(v),
        ),
      );

  void _showAudioTrackSheet(BuildContext ctx) {
    final s = ref.read(playerProvider);
    showModalBottomSheet(
      context: ctx,
      useSafeArea: true,
      isScrollControlled: true,
      showDragHandle: false,
      backgroundColor: Colors.transparent,
      builder: (_) => AudioTrackSheet(
        tracks: s.audioTracks,
        selectedTrack: s.selectedAudioTrack,
        audioEnabled: s.audioEnabled,
        onSelect: (t) => _notifier.setAudioTrack(t),
        onDisable: () => _notifier.disableAudio(),
      ),
    );
  }

  void _showSubtitleSheet(BuildContext ctx) {
    final s = ref.read(playerProvider);
    showModalBottomSheet(
      context: ctx,
      useSafeArea: true,
      isScrollControlled: true,
      showDragHandle: false,
      backgroundColor: Colors.transparent,
      builder: (_) => SubtitleSheet(
        tracks: s.subtitleTracks,
        selectedTrack: s.selectedSubtitleTrack,
        subtitlesEnabled: s.subtitlesEnabled,
        onSelect: (t) => _notifier.setSubtitleTrack(t),
        onToggle: () => _notifier.toggleSubtitles(),
        onLoadExternal: _pickExternalSubtitle,
        delay: s.subtitleDelay,
        onAdjustDelay: (d) => _notifier.adjustSubtitleDelay(d),
        onResetDelay: () => _notifier.setSubtitleDelay(0),
      ),
    );
  }

  void _showSleepTimerSheet(BuildContext ctx) {
    showModalBottomSheet(
      context: ctx,
      useSafeArea: true,
      isScrollControlled: true,
      showDragHandle: false,
      backgroundColor: Colors.transparent,
      builder: (_) => const SleepTimerSheet(),
    );
  }

  Future<void> _enterPip() async {
    // Use the real video aspect ratio so the floating window isn't letterboxed.
    // videoWidth/videoHeight arrive already rotation-corrected from the
    // engine (a portrait recording reports 720x1280), so no swapping here.
    final s = ref.read(playerProvider);
    await MediaSessionService.enterPip(
      width: s.videoWidth,
      height: s.videoHeight,
    );
  }

  Future<void> _pickExternalSubtitle() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['srt', 'vtt', 'ass', 'ssa', 'sub', 'ttml'],
    );
    final path = result?.files.single.path;
    if (path == null) return;
    await _notifier.loadExternalSubtitle(path);
  }

  Future<void> _exitPlayer({bool shouldPop = true}) async {
    if (_isExiting) return;
    _isExiting = true;
    if (mounted) {
      setState(() => _leaving = true);
      await _exitCtrl.forward(from: 0.0);
    }
    await _notifier.leaveScreen();
    if (!mounted) return;
    if (shouldPop && Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return PopScope(
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) {
          // The route is already being popped; only run the cleanup so the
          // screen fades out consistently before the previous route resumes.
          if (!_isExiting) {
            if (mounted) setState(() => _leaving = true);
            await _notifier.leaveScreen();
          }
          return;
        }
        await _exitPlayer();
      },
      child: AnimatedBuilder(
        animation: _exitCtrl,
        builder: (context, child) {
          final progress = 1.0 - _exitCtrl.value;
          return Transform.scale(
            scale: 1.0 - (0.015 * (1.0 - progress)),
            child: Opacity(
              opacity: progress,
              child: child,
            ),
          );
        },
        child: Scaffold(
          backgroundColor: Colors.black,
          body: Consumer(
            builder: (context, ref, child) {
              // Watch only isLocked + controlsVisible.
              // lockIconVisible is intentionally NOT watched here — its
              // show/hide is driven by _lockIconCtrl (an AnimationController
              // local to this State) so it never triggers a Consumer rebuild
              // and therefore never re-composites the Video platform view.
              final (:isLocked, :controlsVisible, :isPipMode) =
                  ref.watch(playerProvider.select((s) => (
                        isLocked: s.isLocked,
                        controlsVisible: s.controlsVisible,
                        isPipMode: s.isPipMode,
                      )));

              // In PiP mode: show only the raw video, everything else is hidden.
              if (isPipMode) return child!;

              return Stack(
                children: [
                  // ── Main gesture layer (only active when NOT locked) ──────────
                  PlayerGestureLayer(
                    child: child!,
                  ),

                  // ── Lock touch-absorber + lock icon ────────────────────────
                  PlayerLockLayer(
                    isLocked: isLocked,
                    iconController: _lockIconCtrl,
                    onTapWhileLocked: _showLockIconLocal,
                    onUnlock: () {
                      _hideLockIconLocal();
                      _notifier.toggleLock();
                    },
                  ),
                ],
              );
            },
            child: Stack(
              children: [
                // ── Video ──────────────────────────────────────────────────
                PlayerVideoLayer(
                  fallbackPath: widget.filePath,
                  leaving: _leaving,
                  onBack: () => _exitPlayer(),
                ),

                // ── Subtitle overlay (styled Flutter text from engine cues) ─
                const SubtitleOverlay(),

                // ── Swipe HUD ──────────────────────────────────────────────
                Consumer(
                  builder: (context, ref, _) {
                    final (:gesture, :value) =
                        ref.watch(playerProvider.select((s) => (
                              gesture: s.swipeGesture,
                              value: s.swipeValue,
                            )));
                    if (gesture == SwipeGesture.none) return const SizedBox();
                    return SwipeHud(gesture: gesture, value: value);
                  },
                ),

                // ── Auto-play countdown ────────────────────────────────────
                Consumer(
                  builder: (context, ref, _) {
                    final (:countdown, :nextVideo) =
                        ref.watch(playerProvider.select((s) => (
                              countdown: s.autoPlayCountdown,
                              nextVideo: s.nextVideo,
                            )));
                    if (countdown == null || nextVideo == null) {
                      return const SizedBox();
                    }
                    return AutoPlayCountdown(
                      countdown: countdown,
                      nextVideoName: nextVideo.name,
                      onCancel: () =>
                          ref.read(playerProvider.notifier).cancelAutoPlay(),
                      onPlayNow: () =>
                          ref.read(playerProvider.notifier).playNext(),
                    );
                  },
                ),

                // ── Zoom indicator — tap to reset ──────────────────────────
                const ZoomIndicatorOverlay(),

                // ── Controls overlay ───────────────────────────────────────
                PlayerControlsLayer(
                  fallbackFileName: widget.fileName,
                  onBack: () => _exitPlayer(),
                  onTogglePlay: _notifier.togglePlay,
                  onCycleFitMode: _notifier.cycleFitMode,
                  onShowSpeed: () {
                    final s = ref.read(playerProvider);
                    _showSpeedSheet(context, s.playbackSpeed, s.seekInterval);
                  },
                  onShowVolume: () => _showVolumeSheet(
                      context, ref.read(playerProvider).volume),
                  onShowAudio: () => _showAudioTrackSheet(context),
                  onShowSubtitle: () => _showSubtitleSheet(context),
                  onSeekBack: () => _notifier
                      .seekRelative(-ref.read(playerProvider).seekInterval),
                  onSeekForward: () => _notifier
                      .seekRelative(ref.read(playerProvider).seekInterval),
                  onToggleFullscreen: _notifier.cycleRotationMode,
                  onSeekStart: _notifier.beginSeek,
                  onSeekUpdate: _notifier.updateSeek,
                  onSeekEnd: _notifier.endSeek,
                  onPlayNext: _notifier.playNext,
                  onPlayPrevious: _notifier.playPrevious,
                  onToggleLock: () {
                    // When locking: show the lock icon locally so the user
                    // knows the screen is now locked, then auto-hide. When
                    // unlocking: PlayerLockLayer's onUnlock already called
                    // _hideLockIconLocal + toggleLock.
                    final willLock = !ref.read(playerProvider).isLocked;
                    _notifier.toggleLock();
                    if (willLock) _showLockIconLocal();
                  },
                  onToggleRepeat: _notifier.cycleLoopMode,
                  onAudioMode: () {
                    // Switch to background audio and leave the screen —
                    // playback keeps going, controlled from the notification /
                    // lock screen.
                    _notifier.enableAudioMode();
                    _exitPlayer();
                  },
                  onSleepTimer: () => _showSleepTimerSheet(context),
                  onPip: () => _enterPip(),
                  onCycleAbRepeat: _notifier.cycleAbRepeat,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
