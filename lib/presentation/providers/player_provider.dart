import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:screen_brightness/screen_brightness.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import '../../engine/player_engine.dart';
import '../../engine/exoplayer_engine.dart';
import '../../engine/media_kit_engine.dart';
import '../../models/video_file.dart';
import '../../services/brightness_service.dart';
import '../../services/duration_cache_service.dart';
import '../../services/media_session_service.dart';
import '../../services/player_preferences_service.dart';
import '../../services/position_service.dart';
import '../../services/thumbnail_service.dart';
import '../../services/volume_service.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'player_provider.freezed.dart';

// ── Enums ─────────────────────────────────────────────────────────────────────

enum FitMode { contain, cover, fill, natural }

extension FitModeX on FitMode {
  String get label => switch (this) {
        FitMode.contain => 'FIT',
        FitMode.cover   => 'CROP',
        FitMode.fill    => 'FILL',
        FitMode.natural => 'AUTO',
      };
  FitMode get next => FitMode.values[(index + 1) % FitMode.values.length];
}

enum RotationMode { auto, landscape, portrait }

extension RotationModeX on RotationMode {
  RotationMode get next => switch (this) {
        RotationMode.auto => RotationMode.landscape,
        RotationMode.landscape => RotationMode.portrait,
        RotationMode.portrait => RotationMode.auto,
      };
}

enum SwipeGesture { none, brightness, volume }

// Loop/repeat mode
enum LoopMode { none, loopAll, loopOne }

extension LoopModeX on LoopMode {
  LoopMode get next => LoopMode.values[(index + 1) % LoopMode.values.length];
  bool get isActive => this != LoopMode.none;
  /// Engine repeat-mode code: 0 = off, 1 = one, 2 = all.
  int get repeatCode => switch (this) {
        LoopMode.none => 0,
        LoopMode.loopOne => 1,
        LoopMode.loopAll => 2,
      };
}

// ── State ─────────────────────────────────────────────────────────────────────

@freezed
class PlayerState with _$PlayerState {
  const PlayerState._();

  const factory PlayerState({
    @Default(false) bool isInitialized,
    @Default(false) bool isPlaying,
    // Playback INTENT (playWhenReady). Drives the play/pause button so it stays
    // stable during a seek's brief re-buffer (where isPlaying flickers false).
    @Default(false) bool intendsToPlay,
    @Default(true) bool controlsVisible,
    @Default(false) bool isPipMode,
    @Default(RotationMode.auto) RotationMode rotationMode,
    @Default(false) bool isSeeking,
    @Default(0.0) double seekValue,
    @Default(Duration.zero) Duration position,
    @Default(Duration.zero) Duration duration,
    @Default(100.0) double volume,
    @Default(0.5) double brightness,
    @Default(1.0) double playbackSpeed,
    @Default(FitMode.contain) FitMode fitMode,
    @Default([]) List<MediaTrack> audioTracks,
    MediaTrack? selectedAudioTrack,
    // False when the user explicitly disabled the audio track ("Disable" option).
    @Default(true) bool audioEnabled,
    @Default(SwipeGesture.none) SwipeGesture swipeGesture,
    @Default(0.0) double swipeValue,
    @Default([]) List<VideoFile> folderVideos,
    @Default(-1) int currentIndex,
    @Default([]) List<MediaTrack> subtitleTracks,
    MediaTrack? selectedSubtitleTrack,
    @Default(true) bool subtitlesEnabled,
    @Default(false) bool isLocked,
    @Default(false) bool lockIconVisible,
    @Default(false) bool hasError,
    String? errorMessage,
    int? autoPlayCountdown,
    @Default(1.0) double zoomScale,
    @Default(LoopMode.none) LoopMode loopMode,
    // Flutter texture the native ExoPlayer renders into (null until ready).
    int? textureId,
    // Current subtitle cue text (rendered as a styled Flutter overlay).
    @Default('') String currentCue,
    // Last known video dimensions (for PiP aspect ratio).
    @Default(16) int videoWidth,
    @Default(9) int videoHeight,
    // Sleep timer: wall-clock time at which playback auto-pauses (null = off).
    DateTime? sleepTimerEndsAt,
    // Sleep timer variant: pause when the current video finishes.
    @Default(false) bool sleepTimerEndOfVideo,
    // Subtitle sync offset in seconds (+ = subtitles later, − = earlier).
    @Default(0.0) double subtitleDelay,
    // True while the user holds to temporarily fast-forward (2× speed).
    @Default(false) bool holdFastForward,
    // A-B repeat: loop between these two points when both are set.
    Duration? abRepeatStart,
    Duration? abRepeatEnd,
    // Double-tap seek interval in seconds.
    @Default(10) int seekInterval,
  }) = _PlayerState;

  double get progress => duration.inMilliseconds > 0
      ? (isSeeking
          ? seekValue
          : position.inMilliseconds / duration.inMilliseconds)
      : 0.0;

  bool get hasPrevious => currentIndex > 0;
  bool get hasNext =>
      currentIndex >= 0 && currentIndex < folderVideos.length - 1;

  VideoFile? get currentVideo =>
      currentIndex >= 0 && currentIndex < folderVideos.length
          ? folderVideos[currentIndex]
          : null;

  VideoFile? get nextVideo =>
      hasNext ? folderVideos[currentIndex + 1] : null;
}

// ── Notifier ──────────────────────────────────────────────────────────────────

class PlayerNotifier extends Notifier<PlayerState> {
  PlayerEngine? _engine;
  StreamSubscription<int?>? _textureSub;
  Timer? _hideTimer;
  Timer? _lockIconTimer;
  Timer? _hudTimer;
  Timer? _saveTimer;
  Timer? _autoPlayTimer;
  Timer? _sleepTimer;
  // Speed to restore when the hold-to-fast-forward gesture is released.
  double _preHoldSpeed = 1.0;
  String? _currentPath;
  // Resolved thumbnail path for the current video, used as lock-screen art.
  String? _currentArtPath;

  bool _hasStartedPlaying = false;
  // True once we've switched the current file to the software (media_kit) engine
  // because ExoPlayer couldn't decode it. Guards against a fallback loop.
  bool _usingFallback = false;
  final List<StreamSubscription> _subs = [];

  // Single ScreenBrightness instance — avoids creating a new object every call.
  final _brightness = ScreenBrightness();

  // Guards against notification panel callbacks after dispose begins.
  bool _isDisposing = false;

  // Audio (background) mode. When the user taps the audio button we keep the
  // engine alive after they leave the screen so playback continues like an
  // audio track, controlled from the lock-screen / notification media session.
  bool _audioMode = false;
  bool get audioMode => _audioMode;

  // Set once the screen has been left (popped) so PopScope + State.dispose —
  // which both fire on exit — don't run the teardown twice.
  bool _leftScreen = false;

  DateTime? _lastMediaSessionSync;
  DateTime? _appVolumeChangeAt;

  @override
  PlayerState build() => const PlayerState();

  PlayerEngine? get engine => _engine;
  int? get textureId => _engine?.textureId;

  // The position the current file should resume from. Kept so the software
  // fallback can resume correctly even if ExoPlayer failed before it ever
  // reported a position (state.position would still be 0 in that case).
  Duration? _resumeTarget;

  // ── Init ─────────────────────────────────────────────────────────────────────

  Future<void> init(
    String filePath, {
    Duration? resumeFrom,
    List<VideoFile> folderVideos = const [],
    int initialIndex = -1,
  }) async {
    _isDisposing = false;
    _audioMode = false;
    _leftScreen = false;
    _hasStartedPlaying = false;
    _usingFallback = false;

    final prefsFuture = Future.wait([
      PlayerPreferencesService.instance.loadFitModeIndex(),     // [0]
      PlayerPreferencesService.instance.loadSpeed(),             // [1]
      VolumeService.instance.getDeviceVolume(),                  // [2]
      _brightness.current.catchError((_) => 0.5),               // [3]
      BrightnessService.instance.getBrightness()                 // [4]
          .then<Object?>((v) => v)
          .catchError((_) => null),
      PlayerPreferencesService.instance.loadLoopModeIndex(),     // [5]
    ]);

    _disposeInternal();
    _currentPath = filePath;
    _currentArtPath = null;

    state = PlayerState(
      folderVideos: folderVideos,
      currentIndex: initialIndex,
      seekInterval: PlayerPreferencesService.instance.seekIntervalCached,
    );

    final engine = ExoPlayerEngine();
    _engine = engine;
    // The texture id arrives asynchronously once the native player is created;
    // push it into state so the render widget can mount it.
    state = state.copyWith(textureId: engine.textureId);
    _textureSub = engine.textureIdStream.listen((id) {
      if (!_isDisposing) state = state.copyWith(textureId: id);
    });

    _listenStreams(engine, onReady: () {
      state = state.copyWith(isInitialized: true);
      _startHideTimer();
      _syncMediaSessionMetadata();
    });

    MediaSessionService.setActionHandler(
      onAction: _handleMediaAction,
      onSeek: (pos) => _engine?.seek(pos),
      onPipModeChanged: (isPip) {
        state = state.copyWith(isPipMode: isPip);
      },
    );

    // Open PAUSED so rate/volume/repeat can be applied before audio begins —
    // playback is started only afterwards. `start:` begins decoding AT the
    // resume point instead of playing from 0 then seeking.
    final startAt =
        (resumeFrom != null && resumeFrom > Duration.zero) ? resumeFrom : null;
    _resumeTarget = startAt;
    final openFuture = engine.open(filePath, start: startAt, play: false);

    final results = await prefsFuture;
    final fitModeIdx    = results[0] as int;
    final savedSpeed    = results[1] as double;
    final deviceVol     = results[2] as double;
    final currentBri    = results[3] as double;
    final savedBri      = results[4] as double?;
    final loopModeIdx   = results[5] as int;
    final fitMode       = FitMode.values[fitModeIdx.clamp(0, FitMode.values.length - 1)];
    final loopMode      = LoopMode.values[loopModeIdx.clamp(0, LoopMode.values.length - 1)];

    state = state.copyWith(
      volume: deviceVol * 100,
      fitMode: fitMode,
      playbackSpeed: savedSpeed,
      brightness: savedBri ?? currentBri,
      loopMode: loopMode,
    );

    VolumeService.instance.removeListener();
    VolumeService.instance.addListener((vol) {
      if (_isDisposing) return;
      final last = _appVolumeChangeAt;
      if (last != null &&
          DateTime.now().difference(last) < const Duration(milliseconds: 600)) {
        return;
      }
      if (state.volume <= 100.0) {
        state = state.copyWith(volume: vol * 100);
      }
    });

    await engine.setVolume(100);
    await engine.setRate(savedSpeed);
    await engine.setRepeatMode(loopMode.repeatCode);
    if (savedBri != null) {
      try { await _brightness.setScreenBrightness(savedBri); } catch (_) {}
    }

    await openFuture;
    await _engine?.play();
    WakelockPlus.enable(); // fire-and-forget — never gated the first frame
  }

  // ── Software-decoder fallback ────────────────────────────────────────────────

  /// Swaps the failed ExoPlayer engine for the media_kit (libmpv/FFmpeg) engine
  /// and reopens the current file at the same position. Triggered when ExoPlayer
  /// reports a fatal error — typically a codec the device's MediaCodec can't
  /// decode (e.g. 10-bit HEVC). media_kit decodes in software, like VLC.
  Future<void> _fallbackToSoftware() async {
    if (_usingFallback || _isDisposing) return;
    final path = _currentPath;
    if (path == null) return;
    _usingFallback = true;
    _hasStartedPlaying = false;
    // Prefer how far we actually got; but if ExoPlayer stalled on the bad video
    // decoder and never reported a position, fall back to the original resume
    // target so resuming an HEVC video still lands at the right spot.
    final resumeAt = state.position > Duration.zero
        ? state.position
        : (_resumeTarget ?? Duration.zero);

    // Tear down the ExoPlayer engine + its stream subscriptions and texture.
    _disposeStreams();
    _textureSub?.cancel();
    _textureSub = null;
    final old = _engine;
    _engine = null;
    try { await old?.dispose(); } catch (_) {}

    // Back to "loading" while the software engine prepares (clears the error).
    state = state.copyWith(
      isInitialized: false,
      hasError: false,
      errorMessage: null,
      textureId: null,
    );

    final engine = MediaKitEngine();
    _engine = engine;
    state = state.copyWith(textureId: engine.textureId);
    _textureSub = engine.textureIdStream.listen((id) {
      if (!_isDisposing) state = state.copyWith(textureId: id);
    });

    _listenStreams(engine, onReady: () {
      state = state.copyWith(isInitialized: true);
      _startHideTimer();
      _syncMediaSessionMetadata();
    });

    await engine.setVolume(100);
    await engine.setRate(state.playbackSpeed);
    await engine.setRepeatMode(state.loopMode.repeatCode);
    await engine.open(
      path,
      start: resumeAt > Duration.zero ? resumeAt : null,
      play: true,
    );
  }

  // ── Stream listeners ───────────────────────────────────────────────────────

  void _listenStreams(PlayerEngine engine, {required VoidCallback onReady}) {
    bool frameReady = false;
    void markReady() {
      if (frameReady) return;
      frameReady = true;
      onReady();
    }

    _subs.add(engine.playingStream.listen((v) {
      state = state.copyWith(isPlaying: v);
      if (v) {
        markReady();
        _hasStartedPlaying = true;
      } else if (_hasStartedPlaying && !_isDisposing) {
        _savePosition();
      }
      _syncMediaSessionPlaybackState();
    }));

    _subs.add(engine.intentStream.listen((v) {
      state = state.copyWith(intendsToPlay: v);
    }));

    _subs.add(engine.positionStream.listen((v) {
      state = state.copyWith(position: v);
      final abStart = state.abRepeatStart;
      final abEnd = state.abRepeatEnd;
      if (abStart != null && abEnd != null && v >= abEnd) {
        _engine?.seek(abStart);
      }
      _saveTimer?.cancel();
      _saveTimer = Timer(const Duration(seconds: 3), _savePosition);
      _syncMediaSessionPlaybackState(throttle: true);
    }));

    _subs.add(engine.durationStream.listen((v) {
      if (v <= Duration.zero) return;
      state = state.copyWith(duration: v);
      if (_currentPath != null) {
        DurationCacheService.instance.saveDuration(_currentPath!, v);
      }
      _syncMediaSessionMetadata();
    }));

    _subs.add(engine.rateStream.listen((v) {
      // The engine reports the rate as a float, so a clean 1.2 comes back as
      // 1.2000000476…; snap to 2 decimals so the readouts don't show a long tail.
      final clean = (v * 100).roundToDouble() / 100;
      state = state.copyWith(playbackSpeed: clean);
      _syncMediaSessionPlaybackState();
    }));

    _subs.add(engine.tracksStream.listen((snap) {
      state = state.copyWith(
        audioTracks: snap.audio,
        // Keep the active track for the highlight, but don't clobber the
        // user's "audio disabled" choice (engine reports no active audio then).
        selectedAudioTrack: state.audioEnabled
            ? _findTrack(snap.audio, snap.activeAudioId)
            : null,
        subtitleTracks: snap.subtitle,
        selectedSubtitleTrack:
            _findTrack(snap.subtitle, snap.activeSubtitleId),
      );
    }));

    _subs.add(engine.videoSizeStream.listen((size) {
      if (size.width > 0 && size.height > 0) {
        state = state.copyWith(
            videoWidth: size.width, videoHeight: size.height);
        markReady();
      }
    }));

    _subs.add(engine.cuesStream.listen((text) {
      state = state.copyWith(currentCue: text);
    }));

    _subs.add(engine.completedStream.listen((_) {
      if (_isDisposing) return;
      // A-B repeat takes precedence over everything else: if the clip reaches
      // its end while an A-B loop is active (e.g. B is at/near the end), jump
      // back to A and keep playing instead of advancing / stopping.
      if (state.abRepeatStart != null && state.abRepeatEnd != null) {
        _engine?.seek(state.abRepeatStart!);
        _engine?.play();
        return;
      }
      if (state.sleepTimerEndOfVideo) {
        _engine?.pause();
        state = state.copyWith(sleepTimerEndOfVideo: false);
        return;
      }
      if (state.hasNext) _startAutoPlayCountdown();
    }));

    _subs.add(engine.errorStream.listen((error) {
      if (_isDisposing || error.isEmpty) return;
      // If ExoPlayer (device MediaCodec) can't decode this file, retry it once
      // on the software (libmpv/FFmpeg) engine before showing an error — this is
      // what lets 10-bit HEVC and other codecs VLC plays work here too.
      if (!_usingFallback && _engine is ExoPlayerEngine) {
        _fallbackToSoftware();
        return;
      }
      state = state.copyWith(
        hasError: true,
        errorMessage: error,
        isInitialized: true,
      );
    }));

    // ExoPlayer often does NOT error on an undecodable video track — it just
    // plays the audio and silently drops the picture. This fires when the file
    // has a video track the device can't decode, so we fall back to software
    // (media_kit) instead of leaving the user with sound and a black screen.
    _subs.add(engine.videoUnsupportedStream.listen((_) {
      if (_isDisposing) return;
      if (!_usingFallback && _engine is ExoPlayerEngine) {
        _fallbackToSoftware();
      }
    }));

    Future.delayed(const Duration(seconds: 4), () {
      if (!_isDisposing) markReady();
    });
  }

  MediaTrack? _findTrack(List<MediaTrack> list, String? id) {
    if (id == null) return null;
    for (final t in list) {
      if (t.id == id) return t;
    }
    return null;
  }

  // ── Position save ──────────────────────────────────────────────────────────

  Future<void> _savePosition() async {
    if (_currentPath == null) return;
    await PositionService.instance
        .save(_currentPath!, state.position, state.duration);
  }

  // ── Lock-screen media session ─────────────────────────────────────────────

  void _handleMediaAction(String action) {
    if (_isDisposing || _engine == null) return;
    switch (action) {
      case 'play':
        _engine!.play();
      case 'pause':
        _engine!.pause();
      case 'next':
        playNext();
      case 'previous':
        playPrevious();
    }
  }

  void _syncMediaSessionMetadata() {
    if (_isDisposing) return;
    final path = _currentPath;
    final title = state.currentVideo?.name ??
        (path != null ? p.basename(path) : '');
    MediaSessionService.setMetadata(
      title: title,
      duration: state.duration,
      artPath: _currentArtPath,
    );
    if (path == null || _currentArtPath != null) return;
    ThumbnailService.instance.getThumbnail(path).then((file) {
      if (_isDisposing || file == null || _currentPath != path) return;
      _currentArtPath = file.path;
      MediaSessionService.setMetadata(
        title: title,
        duration: state.duration,
        artPath: file.path,
      );
    });
  }

  void _syncMediaSessionPlaybackState({bool throttle = false}) {
    if (_isDisposing) return;
    if (throttle) {
      final now = DateTime.now();
      if (_lastMediaSessionSync != null &&
          now.difference(_lastMediaSessionSync!) < const Duration(seconds: 1)) {
        return;
      }
      _lastMediaSessionSync = now;
    }
    MediaSessionService.setPlaybackState(
      isPlaying: state.isPlaying,
      position: state.position,
      speed: state.playbackSpeed,
    );
  }

  // ── Auto-play countdown ────────────────────────────────────────────────────

  void _startAutoPlayCountdown() {
    _autoPlayTimer?.cancel();
    int countdown = 5;
    state = state.copyWith(autoPlayCountdown: countdown);

    _autoPlayTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      countdown--;
      if (countdown <= 0) {
        t.cancel();
        state = state.copyWith(autoPlayCountdown: null);
        playNext();
      } else {
        state = state.copyWith(autoPlayCountdown: countdown);
      }
    });
  }

  void cancelAutoPlay() {
    _autoPlayTimer?.cancel();
    state = state.copyWith(autoPlayCountdown: null);
  }

  // ── Next / Previous ────────────────────────────────────────────────────────

  Future<void> playNext() async {
    if (!state.hasNext) return;
    final nextIndex = state.currentIndex + 1;
    await _switchVideo(state.folderVideos[nextIndex].path, nextIndex);
  }

  Future<void> playPrevious() async {
    if (!state.hasPrevious) return;
    final prevIndex = state.currentIndex - 1;
    await _switchVideo(state.folderVideos[prevIndex].path, prevIndex);
  }

  Future<void> _switchVideo(String filePath, int index) async {
    final engine = _engine;
    if (engine == null) return;
    _autoPlayTimer?.cancel();
    await _savePosition();
    _currentPath = filePath;
    _currentArtPath = null;
    _hasStartedPlaying = false;
    // Next/previous start from the beginning — clear the resume target so a
    // software fallback for this file doesn't jump to the previous file's spot.
    _resumeTarget = null;

    state = state.copyWith(
      currentIndex: index,
      isInitialized: false,
      position: Duration.zero,
      duration: Duration.zero,
      isSeeking: false,
      autoPlayCountdown: null,
      hasError: false,
      errorMessage: null,
      zoomScale: 1.0,
      subtitleDelay: 0.0,
      currentCue: '',
      abRepeatStart: null,
      abRepeatEnd: null,
    );

    // Re-subscribe streams for the fresh item (the engine instance is reused).
    _disposeStreams();
    _listenStreams(engine, onReady: () {
      state = state.copyWith(isInitialized: true);
      _startHideTimer();
      _syncMediaSessionMetadata();
    });

    await engine.setVolume(100);
    await engine.setRate(state.playbackSpeed);
    await engine.setRepeatMode(state.loopMode.repeatCode);
    await engine.open(filePath, play: true);
  }

  // ── Gesture lock ──────────────────────────────────────────────────────────

  void toggleLock() {
    final locked = !state.isLocked;
    state = state.copyWith(
      isLocked: locked,
      controlsVisible: !locked,
      lockIconVisible: locked,
    );
    if (locked) {
      _hideTimer?.cancel();
      _startLockIconTimer();
    } else {
      _lockIconTimer?.cancel();
      showControls();
    }
  }

  void _startLockIconTimer() {
    _lockIconTimer?.cancel();
    _lockIconTimer = Timer(const Duration(seconds: 2), () {
      if (state.isLocked && !_isDisposing) {
        state = state.copyWith(lockIconVisible: false);
      }
    });
  }

  void showLockIcon() {
    if (!state.isLocked) return;
    state = state.copyWith(lockIconVisible: true);
    _startLockIconTimer();
  }

  // ── Pinch-to-zoom ─────────────────────────────────────────────────────────

  void setZoomScale(double scale) {
    state = state.copyWith(zoomScale: scale.clamp(0.5, 4.0));
  }

  void resetZoom() => state = state.copyWith(zoomScale: 1.0);

  // ── Loop / repeat ──────────────────────────────────────────────────────────

  void cycleLoopMode() {
    final next = state.loopMode.next;
    state = state.copyWith(loopMode: next);
    PlayerPreferencesService.instance.saveLoopModeIndex(next.index);
    // Don't push the repeat mode to the engine while an A-B loop owns it; the
    // new mode is applied automatically when A-B is cleared.
    _applyEngineRepeatMode();
    showControls();
  }

  // ── Subtitles ──────────────────────────────────────────────────────────────

  void setSubtitleTrack(MediaTrack track) {
    _engine?.selectSubtitleTrack(track.id);
    state = state.copyWith(selectedSubtitleTrack: track, subtitlesEnabled: true);
    showControls();
  }

  void toggleSubtitles() {
    final enabled = !state.subtitlesEnabled;
    if (!enabled) {
      _engine?.selectSubtitleTrack(null);
      state = state.copyWith(subtitlesEnabled: false, currentCue: '');
    } else {
      final target = state.selectedSubtitleTrack ??
          (state.subtitleTracks.isNotEmpty
              ? state.subtitleTracks.first
              : null);
      if (target != null) {
        _engine?.selectSubtitleTrack(target.id);
        state = state.copyWith(
            selectedSubtitleTrack: target, subtitlesEnabled: true);
      } else {
        state = state.copyWith(subtitlesEnabled: true);
      }
    }
    showControls();
  }

  /// Loads an external subtitle file (.srt/.vtt/.ass/…). The native engine adds
  /// it and re-prepares with it selected; the new track then appears in the
  /// tracks stream, which updates the list + selection.
  Future<void> loadExternalSubtitle(String path) async {
    final engine = _engine;
    if (engine == null) return;
    await engine.addExternalSubtitle(path);
    state = state.copyWith(subtitlesEnabled: true);
    showControls();
  }

  // ── Swipe gestures ─────────────────────────────────────────────────────────

  SwipeGesture startSwipe(double dx, double screenWidth) {
    _hudTimer?.cancel();
    final gesture =
        dx < screenWidth / 2 ? SwipeGesture.brightness : SwipeGesture.volume;
    state = state.copyWith(
      swipeGesture: gesture,
      swipeValue: gesture == SwipeGesture.brightness
          ? state.brightness
          : state.volume / 200.0,
    );
    return gesture;
  }

  void updateSwipe(double dy, double screenHeight) {
    if (state.swipeGesture == SwipeGesture.none) return;
    _hudTimer?.cancel();
    final delta = -(dy / (screenHeight * 0.6));
    if (state.swipeGesture == SwipeGesture.brightness) {
      final newBrightness = (state.brightness + delta).clamp(0.0, 1.0);
      _applyBrightness(newBrightness);
      state =
          state.copyWith(brightness: newBrightness, swipeValue: newBrightness);
    } else {
      final newVol = (state.volume + delta * 100).clamp(0.0, 200.0);
      if (newVol <= 100.0) {
        _setDeviceVolume(newVol / 100.0);
        _engine?.setVolume(100);
      } else {
        _setDeviceVolume(1.0);
        _engine?.setVolume(newVol);
      }
      state = state.copyWith(volume: newVol, swipeValue: newVol / 200.0);
    }
  }

  void endSwipe() {
    _hudTimer?.cancel();
    _hudTimer = Timer(const Duration(milliseconds: 1500), () {
      state = state.copyWith(swipeGesture: SwipeGesture.none);
    });
    if (state.swipeGesture == SwipeGesture.brightness) {
      BrightnessService.instance.saveBrightness(state.brightness);
    }
  }

  Future<void> _applyBrightness(double value) async {
    try { await _brightness.setScreenBrightness(value); } catch (_) {}
  }

  void _setDeviceVolume(double v) {
    _appVolumeChangeAt = DateTime.now();
    VolumeService.instance.setDeviceVolume(v);
  }

  // ── Internal cleanup ───────────────────────────────────────────────────────

  void _disposeStreams() {
    _saveTimer?.cancel();
    for (final s in _subs) {
      s.cancel();
    }
    _subs.clear();
  }

  void _disposeInternal() {
    _autoPlayTimer?.cancel();
    _lockIconTimer?.cancel();
    _sleepTimer?.cancel();
    _textureSub?.cancel();
    _textureSub = null;
    _disposeStreams();
    _engine?.dispose();
    _engine = null;
  }

  // ── Controls ───────────────────────────────────────────────────────────────

  void _startHideTimer() {
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(seconds: 3), () {
      if (state.isPlaying && !state.isLocked) {
        state = state.copyWith(controlsVisible: false);
      }
    });
  }

  void showControls() {
    if (state.isLocked) return;
    state = state.copyWith(controlsVisible: true);
    _startHideTimer();
  }

  void hideControls() {
    state = state.copyWith(controlsVisible: false);
    _hideTimer?.cancel();
  }

  void togglePlay() {
    if (_isDisposing || _engine == null) return;
    if (state.autoPlayCountdown != null) cancelAutoPlay();
    try {
      _engine?.playOrPause();
    } catch (_) {}
    showControls();
  }

  void seekRelative(int seconds, {bool revealControls = true}) {
    if (_engine == null) return;
    if (state.autoPlayCountdown != null) cancelAutoPlay();
    final newPos = state.position + Duration(seconds: seconds);
    final target = newPos < Duration.zero
        ? Duration.zero
        : (newPos > state.duration ? state.duration : newPos);
    _engine!.seek(target);
    if (revealControls) showControls();
  }

  void beginSeek(double value) {
    if (state.autoPlayCountdown != null) cancelAutoPlay();
    state = state.copyWith(isSeeking: true, seekValue: value);
  }

  void updateSeek(double value) => state = state.copyWith(seekValue: value);

  void endSeek(double value) {
    if (_engine == null) return;
    if (state.autoPlayCountdown != null) cancelAutoPlay();
    final target =
        Duration(milliseconds: (value * state.duration.inMilliseconds).round());
    // Scrubbing → keyframe-snap seek so the release lands instantly without the
    // exact-seek decode hitch.
    _engine!.seek(target, fast: true);
    state = state.copyWith(isSeeking: false);
    showControls();
  }

  void setVolume(double volume) {
    final clamped = volume.clamp(0.0, 200.0);
    if (clamped <= 100.0) {
      _setDeviceVolume(clamped / 100.0);
      _engine?.setVolume(100);
    } else {
      _setDeviceVolume(1.0);
      _engine?.setVolume(clamped);
    }
    state = state.copyWith(volume: clamped);
  }

  void setSpeed(double speed) {
    final clean = (speed * 100).roundToDouble() / 100;
    _engine?.setRate(clean);
    state = state.copyWith(playbackSpeed: clean);
    PlayerPreferencesService.instance.saveSpeed(clean);
    showControls();
  }

  void setSeekInterval(int seconds) {
    state = state.copyWith(seekInterval: seconds);
    PlayerPreferencesService.instance.saveSeekInterval(seconds);
  }

  // ── Sleep timer ──────────────────────────────────────────────────────────────

  void setSleepTimer({Duration? duration, bool endOfVideo = false}) {
    _sleepTimer?.cancel();
    _sleepTimer = null;
    if (endOfVideo) {
      state = state.copyWith(
          sleepTimerEndsAt: null, sleepTimerEndOfVideo: true);
    } else if (duration != null) {
      _sleepTimer = Timer(duration, _onSleepTimerFired);
      state = state.copyWith(
        sleepTimerEndsAt: DateTime.now().add(duration),
        sleepTimerEndOfVideo: false,
      );
    } else {
      state = state.copyWith(
          sleepTimerEndsAt: null, sleepTimerEndOfVideo: false);
    }
    showControls();
  }

  void cancelSleepTimer() => setSleepTimer();

  void _onSleepTimerFired() {
    _sleepTimer = null;
    _engine?.pause();
    state = state.copyWith(sleepTimerEndsAt: null, sleepTimerEndOfVideo: false);
  }

  // ── Subtitle sync offset ──────────────────────────────────────────────────────

  void setSubtitleDelay(double seconds) {
    final clamped = seconds.clamp(-60.0, 60.0);
    _engine?.setSubtitleDelay(clamped);
    state = state.copyWith(subtitleDelay: clamped);
    showControls();
  }

  void adjustSubtitleDelay(double deltaSeconds) =>
      setSubtitleDelay(state.subtitleDelay + deltaSeconds);

  // ── Hold-to-fast-forward (press and hold for 2×) ──────────────────────────────

  void startHoldFastForward() {
    if (state.holdFastForward || _engine == null) return;
    _preHoldSpeed = state.playbackSpeed;
    _engine!.setRate(2.0);
    state = state.copyWith(holdFastForward: true);
  }

  void endHoldFastForward() {
    if (!state.holdFastForward) return;
    _engine?.setRate(_preHoldSpeed);
    state = state.copyWith(holdFastForward: false);
  }

  // ── A-B repeat ───────────────────────────────────────────────────────────────

  void cycleAbRepeat() {
    if (state.abRepeatStart == null) {
      state = state.copyWith(abRepeatStart: state.position);
    } else if (state.abRepeatEnd == null) {
      if (state.position <= state.abRepeatStart!) {
        state = state.copyWith(abRepeatStart: state.position);
      } else {
        state = state.copyWith(abRepeatEnd: state.position);
        // Both points set: take over end-of-clip handling from the engine's
        // loop mode so REPEAT_MODE_ONE/ALL can't seamlessly jump out of the
        // A-B window before our position check seeks back to A.
        _applyEngineRepeatMode();
        // Engage immediately if we're already past B.
        if (state.position >= state.abRepeatEnd!) {
          _engine?.seek(state.abRepeatStart!);
        }
      }
    } else {
      clearAbRepeat();
    }
    showControls();
  }

  void clearAbRepeat() {
    state = state.copyWith(abRepeatStart: null, abRepeatEnd: null);
    // Restore the user's loop mode now that A-B no longer owns the engine.
    _applyEngineRepeatMode();
  }

  /// While an A-B loop is fully set, the engine's repeat mode is forced off so
  /// the Dart-side A-B seek is the single source of truth for looping;
  /// otherwise the user's selected [LoopMode] is applied.
  void _applyEngineRepeatMode() {
    final abActive = state.abRepeatStart != null && state.abRepeatEnd != null;
    _engine?.setRepeatMode(abActive ? 0 : state.loopMode.repeatCode);
  }

  void setAudioTrack(MediaTrack track) {
    _engine?.selectAudioTrack(track.id);
    state = state.copyWith(selectedAudioTrack: track, audioEnabled: true);
    showControls();
  }

  /// Disable the audio track entirely (silences the stream, distinct from
  /// setting the volume to 0).
  void disableAudio() {
    _engine?.selectAudioTrack(null);
    state = state.copyWith(selectedAudioTrack: null, audioEnabled: false);
    showControls();
  }

  void cycleFitMode() {
    final next = state.fitMode.next;
    state = state.copyWith(fitMode: next, zoomScale: 1.0);
    PlayerPreferencesService.instance.saveFitModeIndex(next.index);
    showControls();
  }

  void cycleRotationMode() {
    final next = state.rotationMode.next;
    state = state.copyWith(rotationMode: next);
    final (orientations, uiMode) = switch (next) {
      RotationMode.landscape => (
        [DeviceOrientation.landscapeLeft, DeviceOrientation.landscapeRight],
        SystemUiMode.immersiveSticky,
      ),
      RotationMode.portrait => (
        [DeviceOrientation.portraitUp, DeviceOrientation.portraitDown],
        SystemUiMode.immersiveSticky,
      ),
      RotationMode.auto => (
        <DeviceOrientation>[],
        SystemUiMode.edgeToEdge,
      ),
    };
    SystemChrome.setPreferredOrientations(orientations);
    SystemChrome.setEnabledSystemUIMode(uiMode);
    showControls();
  }

  // ── Audio (background) mode ─────────────────────────────────────────────────

  void enableAudioMode() {
    _audioMode = true;
  }

  Future<void> leaveScreen() async {
    if (_leftScreen) return;
    _leftScreen = true;
    if (_audioMode) {
      await _detachForAudioMode();
    } else {
      await dispose();
    }
  }

  Future<void> _detachForAudioMode() async {
    _hideTimer?.cancel();
    _lockIconTimer?.cancel();
    _hudTimer?.cancel();
    _saveTimer?.cancel();
    await _savePosition();

    try { await _brightness.resetScreenBrightness(); } catch (_) {}
    await WakelockPlus.disable();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

    _syncMediaSessionMetadata();
    _syncMediaSessionPlaybackState();
  }

  Future<void> dispose() async {
    if (_isDisposing) return;
    _isDisposing = true;
    _autoPlayTimer?.cancel();
    VolumeService.instance.removeListener();
    _hideTimer?.cancel();
    _lockIconTimer?.cancel();
    _hudTimer?.cancel();

    try {
      await _engine?.pause();
    } catch (_) {}

    _saveTimer?.cancel();
    await _savePosition();
    await MediaSessionService.release();

    // Cancel timers + stream subscriptions now (cheap), but DEFER the heavy
    // native ExoPlayer teardown so it doesn't compete with the pop transition
    // on low-end devices. The old engine is captured and disposed a few frames
    // later; a re-open before then makes a fresh engine via init().
    _autoPlayTimer?.cancel();
    _lockIconTimer?.cancel();
    _sleepTimer?.cancel();
    _textureSub?.cancel();
    _textureSub = null;
    _disposeStreams();
    final oldEngine = _engine;
    _engine = null;
    Future.delayed(const Duration(milliseconds: 350), () async {
      try { await oldEngine?.dispose(); } catch (_) {}
    });

    state = const PlayerState();

    try { await _brightness.resetScreenBrightness(); } catch (_) {}
    await WakelockPlus.disable();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  }
}

final playerProvider = NotifierProvider<PlayerNotifier, PlayerState>(
  PlayerNotifier.new,
);
