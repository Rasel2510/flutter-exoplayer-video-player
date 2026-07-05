import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:media_kit_video/media_kit_video.dart';
import '../engine/media_kit_engine.dart';
import '../models/video_file.dart';
import '../services/thumbnail_service.dart';
import '../presentation/providers/player_provider.dart';
import '../presentation/providers/subtitle_style_provider.dart';
import '../presentation/widgets/player/player_controls_overlay/player_controls_overlay.dart';
import '../presentation/widgets/player/speed_sheet.dart';
import '../presentation/widgets/player/volume_sheet/volume_sheet.dart';
import '../presentation/widgets/player/player_gesture_layer.dart';
import '../presentation/widgets/player/audio_track_sheet.dart';
import '../presentation/widgets/player/subtitle_sheet/subtitle_sheet.dart';
import '../presentation/widgets/player/sleep_timer_sheet/sleep_timer_sheet.dart';
import '../services/media_session_service.dart';
import '../presentation/widgets/player/lock_overlay.dart';
import '../presentation/widgets/player/auto_play_countdown.dart';
import '../presentation/widgets/player/error_state.dart';
import '../presentation/widgets/player/swipe_hud.dart';
import '../presentation/widgets/player/zoom_indicator_overlay.dart';

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
  Timer? _lockIconLocalTimer;

  // True once the route is popping. dispose() resets the provider to a fresh
  // PlayerState (isInitialized=false), which would otherwise re-show the
  // loading spinner over the screen while the pop transition is still running —
  // looking like the app "loads" on the way out. While leaving we show the
  // black background instead so the exit is clean and instant.
  bool _leaving = false;

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

  void _showSpeedSheet(BuildContext ctx, double speed, int seekInterval) => showModalBottomSheet(
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

  // ── Fit mode ───────────────────────────────────────────────────────────────
  // Const map avoids a switch allocation on every video Consumer rebuild.
  static const _fitBoxMap = {
    FitMode.contain: BoxFit.contain,
    FitMode.cover: BoxFit.cover,
    FitMode.fill: BoxFit.fill,
    FitMode.natural: BoxFit.scaleDown,
  };
  BoxFit _boxFit(FitMode mode) => _fitBoxMap[mode] ?? BoxFit.contain;

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return PopScope(
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) {
          // Set before leaveScreen() resets the provider state so the rebuild
          // it triggers shows black instead of the loading spinner.
          _leaving = true;
          await _notifier.leaveScreen();
        }
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

                // ── Lock touch-absorber — always in tree, active only when locked ──
                // IgnorePointer switches touch-absorption without adding/removing
                // siblings, so the Video platform view is never re-composited.
                Positioned.fill(
                  child: IgnorePointer(
                    ignoring: !isLocked,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      // When the locked screen is tapped, show the lock icon
                      // via _lockIconCtrl — a purely local animation that never
                      // updates provider state and therefore causes zero rebuilds
                      // (and zero white flashes on the video layer).
                      onTap: isLocked ? _showLockIconLocal : null,
                      onScaleStart: (_) {},
                      onScaleUpdate: (_) {},
                      onScaleEnd: (_) {},
                      child: const SizedBox.expand(),
                    ),
                  ),
                ),

                // ── Lock icon — driven by local AnimationController ───────────
                // FadeTransition + AnimationController never touches provider
                // state, so no Consumer rebuilds, no platform-view re-composite,
                // no white flash when the icon appears/disappears.
                Positioned.fill(
                  child: FadeTransition(
                    opacity: _lockIconCtrl,
                    child: AnimatedBuilder(
                      animation: _lockIconCtrl,
                      builder: (context, child) => IgnorePointer(
                        // Pass taps through when hidden so the touch-absorber
                        // can show the icon on the next tap.
                        ignoring: !isLocked || _lockIconCtrl.value == 0,
                        child: child,
                      ),
                      child: LockOverlay(
                        onUnlock: () {
                          _hideLockIconLocal();
                          _notifier.toggleLock();
                        },
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
          child: Stack(
            children: [
              // ── Video ──────────────────────────────────────────────────
              Consumer(
                builder: (context, ref, _) {
                  final (
                    :isInitialized,
                    :fitMode,
                    :zoomScale,
                    :hasError,
                    :errorMsg,
                    :textureId,
                    :videoWidth,
                    :videoHeight,
                  ) = ref.watch(playerProvider.select((s) => (
                        isInitialized: s.isInitialized,
                        fitMode: s.fitMode,
                        zoomScale: s.zoomScale,
                        hasError: s.hasError,
                        errorMsg: s.errorMessage,
                        textureId: s.textureId,
                        videoWidth: s.videoWidth,
                        videoHeight: s.videoHeight,
                      )));

                  if (hasError) {
                    return ErrorState(
                      message: errorMsg,
                      onRetry: () {
                        // FIX #OPT-1: .let() is a Kotlin idiom; Dart has no such
                        // built-in extension. Use a plain block instead.
                        final n = ref.read(playerProvider.notifier);
                        final s = ref.read(playerProvider);
                        n.init(
                          s.currentVideo?.path ?? widget.filePath,
                          folderVideos: s.folderVideos,
                          initialIndex: s.currentIndex,
                        );
                      },
                      onBack: () => Navigator.pop(context),
                    );
                  }

                  if (!isInitialized || textureId == null) {
                    // While popping, don't flash the spinner over the outgoing
                    // screen — just let the black Scaffold show through.
                    if (_leaving) return const SizedBox.shrink();
                    // Paint the already-cached thumbnail as a poster behind the
                    // spinner so tapping a video shows its frame instantly,
                    // instead of a black gap, while the decoder warms up.
                    final path = ref.read(playerProvider).currentVideo?.path ??
                        widget.filePath;
                    return _LoadingPoster(videoPath: path);
                  }

                  // Render each engine with its proper widget: the software
                  // (media_kit) engine MUST use media_kit's own Video widget —
                  // its Android texture isn't displayable via a raw Texture.
                  // ExoPlayer renders into a Flutter texture; BoxFit is applied by
                  // sizing it to the video's intrinsic aspect ratio in a FittedBox.
                  final engine = ref.read(playerProvider.notifier).engine;
                  Widget video;
                  if (engine is MediaKitEngine) {
                    video = Video(
                      controller: engine.controller,
                      controls: NoVideoControls,
                      fit: _boxFit(fitMode),
                      // The app renders subtitles itself (styled _SubtitleOverlay
                      // fed by cuesStream). Hide media_kit's own SubtitleView or
                      // every cue shows twice.
                      subtitleViewConfiguration:
                          const SubtitleViewConfiguration(visible: false),
                    );
                  } else {
                    final w = videoWidth > 0 ? videoWidth.toDouble() : 16.0;
                    final h = videoHeight > 0 ? videoHeight.toDouble() : 9.0;
                    video = FittedBox(
                      fit: _boxFit(fitMode),
                      clipBehavior: Clip.hardEdge,
                      child: SizedBox(
                        width: w,
                        height: h,
                        child: Texture(textureId: textureId),
                      ),
                    );
                  }
                  if (zoomScale != 1.0) {
                    video = Transform.scale(scale: zoomScale, child: video);
                  }
                  return Positioned.fill(child: Center(child: video));
                },
              ),

              // ── Subtitle overlay (styled Flutter text from engine cues) ─
              const _SubtitleOverlay(),

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
              Consumer(
                builder: (context, ref, _) {
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
                  final displayName = currentVideo?.name ?? widget.fileName;
                  final notifier = ref.read(playerProvider.notifier);

                  // Keep controls in the widget tree when hidden (opacity=0)
                  // so Flutter never tears down the platform-view compositor layer.
                  //
                  // IMPORTANT: always use the SAME widget type (AnimatedOpacity)
                  // regardless of visibility. Switching between AnimatedOpacity
                  // and Opacity causes Flutter to rebuild the subtree, which
                  // triggers a white compositor-layer flash over the video
                  // platform view in release builds — the exact "white screen"
                  // seen when tapping the lock icon.
                  //
                  // Using Duration.zero when hiding gives an instant hide
                  // without any intermediate saveLayer, while keeping the widget
                  // type stable avoids the destructive rebuild entirely.
                  final visible = controlsVisible && !isLocked;
                  final child = IgnorePointer(
                    ignoring: !visible,
                    child: PlayerControlsOverlay(
                      fileName: displayName,
                      onBack: () => Navigator.pop(context),
                      onTogglePlay: notifier.togglePlay,
                      onCycleFitMode: notifier.cycleFitMode,
                      onShowSpeed: () {
                        final s = ref.read(playerProvider);
                        _showSpeedSheet(context, s.playbackSpeed, s.seekInterval);
                      },
                      onShowVolume: () => _showVolumeSheet(
                          context, ref.read(playerProvider).volume),
                      onShowAudio: () => _showAudioTrackSheet(context),
                      onShowSubtitle: () => _showSubtitleSheet(context),
                      onSeekBack: () => notifier.seekRelative(-ref.read(playerProvider).seekInterval),
                      onSeekForward: () => notifier.seekRelative(ref.read(playerProvider).seekInterval),
                      onToggleFullscreen: notifier.cycleRotationMode,
                      onSeekStart: notifier.beginSeek,
                      onSeekUpdate: notifier.updateSeek,
                      onSeekEnd: notifier.endSeek,
                      onPlayNext: notifier.playNext,
                      onPlayPrevious: notifier.playPrevious,
                      onToggleLock: () {
                        // When locking: show the lock icon locally so the
                        // user knows the screen is now locked, then auto-hide.
                        // When unlocking: the LockOverlay.onUnlock callback
                        // already called _hideLockIconLocal + toggleLock.
                        final willLock = !ref.read(playerProvider).isLocked;
                        notifier.toggleLock();
                        if (willLock) _showLockIconLocal();
                      },
                      onToggleRepeat: notifier.cycleLoopMode,
                      onAudioMode: () {
                        // Switch to background audio and leave the screen —
                        // playback keeps going, controlled from the
                        // notification / lock screen.
                        notifier.enableAudioMode();
                        Navigator.pop(context);
                      },
                      onSleepTimer: () => _showSleepTimerSheet(context),
                      onPip: () => _enterPip(),
                      onCycleAbRepeat: notifier.cycleAbRepeat,
                    ),
                  );
                  return AnimatedOpacity(
                    opacity: visible ? 1.0 : 0.0,
                    // Fade-in when showing; instant (0 ms) when hiding so there
                    // is no intermediate compositor layer to flash white.
                    duration: visible
                        ? const Duration(milliseconds: 200)
                        : Duration.zero,
                    child: child,
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Loading poster ─────────────────────────────────────────────────────────────

/// Shown while the native player warms up (before the first frame). Paints the
/// video's already-cached thumbnail as a full-screen poster behind a spinner so
/// the transition into playback feels instant instead of black.
///
/// [ThumbnailService.getThumbnail] returns from its in-memory `_resolved` map
/// when the library already generated the thumbnail (the common case), so the
/// poster appears on the next microtask with no disk hit.
class _LoadingPoster extends StatelessWidget {
  final String videoPath;
  const _LoadingPoster({required this.videoPath});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        FutureBuilder<File?>(
          future: ThumbnailService.instance.getThumbnail(videoPath),
          builder: (context, snap) {
            final file = snap.data;
            if (file == null) return const SizedBox.shrink();
            // contain → same letterboxing the video will use, so there's no
            // jump when the real frame replaces the poster.
            return Image.file(
              file,
              fit: BoxFit.contain,
              gaplessPlayback: true,
              filterQuality: FilterQuality.low,
              // Harvested posters can be full video resolution — cap the
              // decode at screen width so opening a 4K HEVC doesn't spike a
              // huge bitmap decode right as the decoder is warming up.
              cacheWidth: (MediaQuery.sizeOf(context).width *
                      MediaQuery.devicePixelRatioOf(context))
                  .round(),
            );
          },
        ),
        const Center(child: CircularProgressIndicator()),
      ],
    );
  }
}

// ── Subtitle overlay ──────────────────────────────────────────────────────────

/// Renders the active subtitle cue (forwarded from native ExoPlayer) as styled
/// Flutter text, using the same appearance settings as the media_kit build.
/// Rendering subtitles in Flutter (rather than a native view) keeps full control
/// over font size / colour / background.
class _SubtitleOverlay extends ConsumerWidget {
  const _SubtitleOverlay();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final (:cue, :enabled) = ref.watch(playerProvider.select((s) => (
          cue: s.currentCue,
          enabled: s.subtitlesEnabled,
        )));
    if (!enabled || cue.isEmpty) return const SizedBox.shrink();
    final style = ref.watch(subtitleStyleProvider);

    return Positioned(
      left: 16,
      right: 16,
      bottom: 48,
      child: IgnorePointer(
        child: Center(
          child: Container(
            padding: style.background
                ? const EdgeInsets.symmetric(horizontal: 10, vertical: 4)
                : EdgeInsets.zero,
            decoration: style.background
                ? BoxDecoration(
                    color: style.backgroundColor,
                    borderRadius: BorderRadius.circular(6),
                  )
                : null,
            child: Text(
              cue,
              textAlign: TextAlign.center,
              style: TextStyle(
                height: 1.3,
                fontSize: style.fontSize,
                color: style.color,
                fontWeight: FontWeight.bold,
                shadows: style.background
                    ? null
                    : const [
                        Shadow(blurRadius: 4, color: Colors.black),
                        Shadow(blurRadius: 8, color: Colors.black),
                      ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}


