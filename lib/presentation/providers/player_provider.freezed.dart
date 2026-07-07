// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'player_provider.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$PlayerState {
  bool get isInitialized => throw _privateConstructorUsedError;
  bool get isPlaying =>
      throw _privateConstructorUsedError; // Playback INTENT (playWhenReady). Drives the play/pause button so it stays
// stable during a seek's brief re-buffer (where isPlaying flickers false).
  bool get intendsToPlay => throw _privateConstructorUsedError;
  bool get controlsVisible => throw _privateConstructorUsedError;
  bool get isPipMode => throw _privateConstructorUsedError;
  RotationMode get rotationMode => throw _privateConstructorUsedError;
  bool get isSeeking => throw _privateConstructorUsedError;
  double get seekValue => throw _privateConstructorUsedError;
  Duration get position => throw _privateConstructorUsedError;
  Duration get duration => throw _privateConstructorUsedError;
  double get volume => throw _privateConstructorUsedError;
  double get brightness => throw _privateConstructorUsedError;
  double get playbackSpeed => throw _privateConstructorUsedError;
  FitMode get fitMode => throw _privateConstructorUsedError;
  List<MediaTrack> get audioTracks => throw _privateConstructorUsedError;
  MediaTrack? get selectedAudioTrack =>
      throw _privateConstructorUsedError; // False when the user explicitly disabled the audio track ("Disable" option).
  bool get audioEnabled => throw _privateConstructorUsedError;
  SwipeGesture get swipeGesture => throw _privateConstructorUsedError;
  double get swipeValue => throw _privateConstructorUsedError;
  List<VideoFile> get folderVideos => throw _privateConstructorUsedError;
  int get currentIndex => throw _privateConstructorUsedError;
  List<MediaTrack> get subtitleTracks => throw _privateConstructorUsedError;
  MediaTrack? get selectedSubtitleTrack => throw _privateConstructorUsedError;
  bool get subtitlesEnabled => throw _privateConstructorUsedError;
  bool get isLocked => throw _privateConstructorUsedError;
  bool get lockIconVisible => throw _privateConstructorUsedError;
  bool get hasError => throw _privateConstructorUsedError;
  String? get errorMessage => throw _privateConstructorUsedError;
  int? get autoPlayCountdown => throw _privateConstructorUsedError;
  double get zoomScale => throw _privateConstructorUsedError;
  LoopMode get loopMode =>
      throw _privateConstructorUsedError; // Flutter texture the native ExoPlayer renders into (null until ready).
  int? get textureId =>
      throw _privateConstructorUsedError; // Current subtitle cue text (rendered as a styled Flutter overlay).
  String get currentCue =>
      throw _privateConstructorUsedError; // Last known video dimensions (for PiP aspect ratio).
  int get videoWidth => throw _privateConstructorUsedError;
  int get videoHeight =>
      throw _privateConstructorUsedError; // Sleep timer: wall-clock time at which playback auto-pauses (null = off).
  DateTime? get sleepTimerEndsAt =>
      throw _privateConstructorUsedError; // Sleep timer variant: pause when the current video finishes.
  bool get sleepTimerEndOfVideo =>
      throw _privateConstructorUsedError; // Subtitle sync offset in seconds (+ = subtitles later, − = earlier).
  double get subtitleDelay =>
      throw _privateConstructorUsedError; // True while the user holds to temporarily fast-forward (2× speed).
  bool get holdFastForward =>
      throw _privateConstructorUsedError; // A-B repeat: loop between these two points when both are set.
  Duration? get abRepeatStart => throw _privateConstructorUsedError;
  Duration? get abRepeatEnd =>
      throw _privateConstructorUsedError; // Double-tap seek interval in seconds.
  int get seekInterval =>
      throw _privateConstructorUsedError; // Mini player state.
  bool get isMiniPlayerActive => throw _privateConstructorUsedError;

  /// Create a copy of PlayerState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $PlayerStateCopyWith<PlayerState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PlayerStateCopyWith<$Res> {
  factory $PlayerStateCopyWith(
          PlayerState value, $Res Function(PlayerState) then) =
      _$PlayerStateCopyWithImpl<$Res, PlayerState>;
  @useResult
  $Res call(
      {bool isInitialized,
      bool isPlaying,
      bool intendsToPlay,
      bool controlsVisible,
      bool isPipMode,
      RotationMode rotationMode,
      bool isSeeking,
      double seekValue,
      Duration position,
      Duration duration,
      double volume,
      double brightness,
      double playbackSpeed,
      FitMode fitMode,
      List<MediaTrack> audioTracks,
      MediaTrack? selectedAudioTrack,
      bool audioEnabled,
      SwipeGesture swipeGesture,
      double swipeValue,
      List<VideoFile> folderVideos,
      int currentIndex,
      List<MediaTrack> subtitleTracks,
      MediaTrack? selectedSubtitleTrack,
      bool subtitlesEnabled,
      bool isLocked,
      bool lockIconVisible,
      bool hasError,
      String? errorMessage,
      int? autoPlayCountdown,
      double zoomScale,
      LoopMode loopMode,
      int? textureId,
      String currentCue,
      int videoWidth,
      int videoHeight,
      DateTime? sleepTimerEndsAt,
      bool sleepTimerEndOfVideo,
      double subtitleDelay,
      bool holdFastForward,
      Duration? abRepeatStart,
      Duration? abRepeatEnd,
      int seekInterval,
      bool isMiniPlayerActive});
}

/// @nodoc
class _$PlayerStateCopyWithImpl<$Res, $Val extends PlayerState>
    implements $PlayerStateCopyWith<$Res> {
  _$PlayerStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of PlayerState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? isInitialized = null,
    Object? isPlaying = null,
    Object? intendsToPlay = null,
    Object? controlsVisible = null,
    Object? isPipMode = null,
    Object? rotationMode = null,
    Object? isSeeking = null,
    Object? seekValue = null,
    Object? position = null,
    Object? duration = null,
    Object? volume = null,
    Object? brightness = null,
    Object? playbackSpeed = null,
    Object? fitMode = null,
    Object? audioTracks = null,
    Object? selectedAudioTrack = freezed,
    Object? audioEnabled = null,
    Object? swipeGesture = null,
    Object? swipeValue = null,
    Object? folderVideos = null,
    Object? currentIndex = null,
    Object? subtitleTracks = null,
    Object? selectedSubtitleTrack = freezed,
    Object? subtitlesEnabled = null,
    Object? isLocked = null,
    Object? lockIconVisible = null,
    Object? hasError = null,
    Object? errorMessage = freezed,
    Object? autoPlayCountdown = freezed,
    Object? zoomScale = null,
    Object? loopMode = null,
    Object? textureId = freezed,
    Object? currentCue = null,
    Object? videoWidth = null,
    Object? videoHeight = null,
    Object? sleepTimerEndsAt = freezed,
    Object? sleepTimerEndOfVideo = null,
    Object? subtitleDelay = null,
    Object? holdFastForward = null,
    Object? abRepeatStart = freezed,
    Object? abRepeatEnd = freezed,
    Object? seekInterval = null,
    Object? isMiniPlayerActive = null,
  }) {
    return _then(_value.copyWith(
      isInitialized: null == isInitialized
          ? _value.isInitialized
          : isInitialized // ignore: cast_nullable_to_non_nullable
              as bool,
      isPlaying: null == isPlaying
          ? _value.isPlaying
          : isPlaying // ignore: cast_nullable_to_non_nullable
              as bool,
      intendsToPlay: null == intendsToPlay
          ? _value.intendsToPlay
          : intendsToPlay // ignore: cast_nullable_to_non_nullable
              as bool,
      controlsVisible: null == controlsVisible
          ? _value.controlsVisible
          : controlsVisible // ignore: cast_nullable_to_non_nullable
              as bool,
      isPipMode: null == isPipMode
          ? _value.isPipMode
          : isPipMode // ignore: cast_nullable_to_non_nullable
              as bool,
      rotationMode: null == rotationMode
          ? _value.rotationMode
          : rotationMode // ignore: cast_nullable_to_non_nullable
              as RotationMode,
      isSeeking: null == isSeeking
          ? _value.isSeeking
          : isSeeking // ignore: cast_nullable_to_non_nullable
              as bool,
      seekValue: null == seekValue
          ? _value.seekValue
          : seekValue // ignore: cast_nullable_to_non_nullable
              as double,
      position: null == position
          ? _value.position
          : position // ignore: cast_nullable_to_non_nullable
              as Duration,
      duration: null == duration
          ? _value.duration
          : duration // ignore: cast_nullable_to_non_nullable
              as Duration,
      volume: null == volume
          ? _value.volume
          : volume // ignore: cast_nullable_to_non_nullable
              as double,
      brightness: null == brightness
          ? _value.brightness
          : brightness // ignore: cast_nullable_to_non_nullable
              as double,
      playbackSpeed: null == playbackSpeed
          ? _value.playbackSpeed
          : playbackSpeed // ignore: cast_nullable_to_non_nullable
              as double,
      fitMode: null == fitMode
          ? _value.fitMode
          : fitMode // ignore: cast_nullable_to_non_nullable
              as FitMode,
      audioTracks: null == audioTracks
          ? _value.audioTracks
          : audioTracks // ignore: cast_nullable_to_non_nullable
              as List<MediaTrack>,
      selectedAudioTrack: freezed == selectedAudioTrack
          ? _value.selectedAudioTrack
          : selectedAudioTrack // ignore: cast_nullable_to_non_nullable
              as MediaTrack?,
      audioEnabled: null == audioEnabled
          ? _value.audioEnabled
          : audioEnabled // ignore: cast_nullable_to_non_nullable
              as bool,
      swipeGesture: null == swipeGesture
          ? _value.swipeGesture
          : swipeGesture // ignore: cast_nullable_to_non_nullable
              as SwipeGesture,
      swipeValue: null == swipeValue
          ? _value.swipeValue
          : swipeValue // ignore: cast_nullable_to_non_nullable
              as double,
      folderVideos: null == folderVideos
          ? _value.folderVideos
          : folderVideos // ignore: cast_nullable_to_non_nullable
              as List<VideoFile>,
      currentIndex: null == currentIndex
          ? _value.currentIndex
          : currentIndex // ignore: cast_nullable_to_non_nullable
              as int,
      subtitleTracks: null == subtitleTracks
          ? _value.subtitleTracks
          : subtitleTracks // ignore: cast_nullable_to_non_nullable
              as List<MediaTrack>,
      selectedSubtitleTrack: freezed == selectedSubtitleTrack
          ? _value.selectedSubtitleTrack
          : selectedSubtitleTrack // ignore: cast_nullable_to_non_nullable
              as MediaTrack?,
      subtitlesEnabled: null == subtitlesEnabled
          ? _value.subtitlesEnabled
          : subtitlesEnabled // ignore: cast_nullable_to_non_nullable
              as bool,
      isLocked: null == isLocked
          ? _value.isLocked
          : isLocked // ignore: cast_nullable_to_non_nullable
              as bool,
      lockIconVisible: null == lockIconVisible
          ? _value.lockIconVisible
          : lockIconVisible // ignore: cast_nullable_to_non_nullable
              as bool,
      hasError: null == hasError
          ? _value.hasError
          : hasError // ignore: cast_nullable_to_non_nullable
              as bool,
      errorMessage: freezed == errorMessage
          ? _value.errorMessage
          : errorMessage // ignore: cast_nullable_to_non_nullable
              as String?,
      autoPlayCountdown: freezed == autoPlayCountdown
          ? _value.autoPlayCountdown
          : autoPlayCountdown // ignore: cast_nullable_to_non_nullable
              as int?,
      zoomScale: null == zoomScale
          ? _value.zoomScale
          : zoomScale // ignore: cast_nullable_to_non_nullable
              as double,
      loopMode: null == loopMode
          ? _value.loopMode
          : loopMode // ignore: cast_nullable_to_non_nullable
              as LoopMode,
      textureId: freezed == textureId
          ? _value.textureId
          : textureId // ignore: cast_nullable_to_non_nullable
              as int?,
      currentCue: null == currentCue
          ? _value.currentCue
          : currentCue // ignore: cast_nullable_to_non_nullable
              as String,
      videoWidth: null == videoWidth
          ? _value.videoWidth
          : videoWidth // ignore: cast_nullable_to_non_nullable
              as int,
      videoHeight: null == videoHeight
          ? _value.videoHeight
          : videoHeight // ignore: cast_nullable_to_non_nullable
              as int,
      sleepTimerEndsAt: freezed == sleepTimerEndsAt
          ? _value.sleepTimerEndsAt
          : sleepTimerEndsAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      sleepTimerEndOfVideo: null == sleepTimerEndOfVideo
          ? _value.sleepTimerEndOfVideo
          : sleepTimerEndOfVideo // ignore: cast_nullable_to_non_nullable
              as bool,
      subtitleDelay: null == subtitleDelay
          ? _value.subtitleDelay
          : subtitleDelay // ignore: cast_nullable_to_non_nullable
              as double,
      holdFastForward: null == holdFastForward
          ? _value.holdFastForward
          : holdFastForward // ignore: cast_nullable_to_non_nullable
              as bool,
      abRepeatStart: freezed == abRepeatStart
          ? _value.abRepeatStart
          : abRepeatStart // ignore: cast_nullable_to_non_nullable
              as Duration?,
      abRepeatEnd: freezed == abRepeatEnd
          ? _value.abRepeatEnd
          : abRepeatEnd // ignore: cast_nullable_to_non_nullable
              as Duration?,
      seekInterval: null == seekInterval
          ? _value.seekInterval
          : seekInterval // ignore: cast_nullable_to_non_nullable
              as int,
      isMiniPlayerActive: null == isMiniPlayerActive
          ? _value.isMiniPlayerActive
          : isMiniPlayerActive // ignore: cast_nullable_to_non_nullable
              as bool,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$PlayerStateImplCopyWith<$Res>
    implements $PlayerStateCopyWith<$Res> {
  factory _$$PlayerStateImplCopyWith(
          _$PlayerStateImpl value, $Res Function(_$PlayerStateImpl) then) =
      __$$PlayerStateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {bool isInitialized,
      bool isPlaying,
      bool intendsToPlay,
      bool controlsVisible,
      bool isPipMode,
      RotationMode rotationMode,
      bool isSeeking,
      double seekValue,
      Duration position,
      Duration duration,
      double volume,
      double brightness,
      double playbackSpeed,
      FitMode fitMode,
      List<MediaTrack> audioTracks,
      MediaTrack? selectedAudioTrack,
      bool audioEnabled,
      SwipeGesture swipeGesture,
      double swipeValue,
      List<VideoFile> folderVideos,
      int currentIndex,
      List<MediaTrack> subtitleTracks,
      MediaTrack? selectedSubtitleTrack,
      bool subtitlesEnabled,
      bool isLocked,
      bool lockIconVisible,
      bool hasError,
      String? errorMessage,
      int? autoPlayCountdown,
      double zoomScale,
      LoopMode loopMode,
      int? textureId,
      String currentCue,
      int videoWidth,
      int videoHeight,
      DateTime? sleepTimerEndsAt,
      bool sleepTimerEndOfVideo,
      double subtitleDelay,
      bool holdFastForward,
      Duration? abRepeatStart,
      Duration? abRepeatEnd,
      int seekInterval,
      bool isMiniPlayerActive});
}

/// @nodoc
class __$$PlayerStateImplCopyWithImpl<$Res>
    extends _$PlayerStateCopyWithImpl<$Res, _$PlayerStateImpl>
    implements _$$PlayerStateImplCopyWith<$Res> {
  __$$PlayerStateImplCopyWithImpl(
      _$PlayerStateImpl _value, $Res Function(_$PlayerStateImpl) _then)
      : super(_value, _then);

  /// Create a copy of PlayerState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? isInitialized = null,
    Object? isPlaying = null,
    Object? intendsToPlay = null,
    Object? controlsVisible = null,
    Object? isPipMode = null,
    Object? rotationMode = null,
    Object? isSeeking = null,
    Object? seekValue = null,
    Object? position = null,
    Object? duration = null,
    Object? volume = null,
    Object? brightness = null,
    Object? playbackSpeed = null,
    Object? fitMode = null,
    Object? audioTracks = null,
    Object? selectedAudioTrack = freezed,
    Object? audioEnabled = null,
    Object? swipeGesture = null,
    Object? swipeValue = null,
    Object? folderVideos = null,
    Object? currentIndex = null,
    Object? subtitleTracks = null,
    Object? selectedSubtitleTrack = freezed,
    Object? subtitlesEnabled = null,
    Object? isLocked = null,
    Object? lockIconVisible = null,
    Object? hasError = null,
    Object? errorMessage = freezed,
    Object? autoPlayCountdown = freezed,
    Object? zoomScale = null,
    Object? loopMode = null,
    Object? textureId = freezed,
    Object? currentCue = null,
    Object? videoWidth = null,
    Object? videoHeight = null,
    Object? sleepTimerEndsAt = freezed,
    Object? sleepTimerEndOfVideo = null,
    Object? subtitleDelay = null,
    Object? holdFastForward = null,
    Object? abRepeatStart = freezed,
    Object? abRepeatEnd = freezed,
    Object? seekInterval = null,
    Object? isMiniPlayerActive = null,
  }) {
    return _then(_$PlayerStateImpl(
      isInitialized: null == isInitialized
          ? _value.isInitialized
          : isInitialized // ignore: cast_nullable_to_non_nullable
              as bool,
      isPlaying: null == isPlaying
          ? _value.isPlaying
          : isPlaying // ignore: cast_nullable_to_non_nullable
              as bool,
      intendsToPlay: null == intendsToPlay
          ? _value.intendsToPlay
          : intendsToPlay // ignore: cast_nullable_to_non_nullable
              as bool,
      controlsVisible: null == controlsVisible
          ? _value.controlsVisible
          : controlsVisible // ignore: cast_nullable_to_non_nullable
              as bool,
      isPipMode: null == isPipMode
          ? _value.isPipMode
          : isPipMode // ignore: cast_nullable_to_non_nullable
              as bool,
      rotationMode: null == rotationMode
          ? _value.rotationMode
          : rotationMode // ignore: cast_nullable_to_non_nullable
              as RotationMode,
      isSeeking: null == isSeeking
          ? _value.isSeeking
          : isSeeking // ignore: cast_nullable_to_non_nullable
              as bool,
      seekValue: null == seekValue
          ? _value.seekValue
          : seekValue // ignore: cast_nullable_to_non_nullable
              as double,
      position: null == position
          ? _value.position
          : position // ignore: cast_nullable_to_non_nullable
              as Duration,
      duration: null == duration
          ? _value.duration
          : duration // ignore: cast_nullable_to_non_nullable
              as Duration,
      volume: null == volume
          ? _value.volume
          : volume // ignore: cast_nullable_to_non_nullable
              as double,
      brightness: null == brightness
          ? _value.brightness
          : brightness // ignore: cast_nullable_to_non_nullable
              as double,
      playbackSpeed: null == playbackSpeed
          ? _value.playbackSpeed
          : playbackSpeed // ignore: cast_nullable_to_non_nullable
              as double,
      fitMode: null == fitMode
          ? _value.fitMode
          : fitMode // ignore: cast_nullable_to_non_nullable
              as FitMode,
      audioTracks: null == audioTracks
          ? _value._audioTracks
          : audioTracks // ignore: cast_nullable_to_non_nullable
              as List<MediaTrack>,
      selectedAudioTrack: freezed == selectedAudioTrack
          ? _value.selectedAudioTrack
          : selectedAudioTrack // ignore: cast_nullable_to_non_nullable
              as MediaTrack?,
      audioEnabled: null == audioEnabled
          ? _value.audioEnabled
          : audioEnabled // ignore: cast_nullable_to_non_nullable
              as bool,
      swipeGesture: null == swipeGesture
          ? _value.swipeGesture
          : swipeGesture // ignore: cast_nullable_to_non_nullable
              as SwipeGesture,
      swipeValue: null == swipeValue
          ? _value.swipeValue
          : swipeValue // ignore: cast_nullable_to_non_nullable
              as double,
      folderVideos: null == folderVideos
          ? _value._folderVideos
          : folderVideos // ignore: cast_nullable_to_non_nullable
              as List<VideoFile>,
      currentIndex: null == currentIndex
          ? _value.currentIndex
          : currentIndex // ignore: cast_nullable_to_non_nullable
              as int,
      subtitleTracks: null == subtitleTracks
          ? _value._subtitleTracks
          : subtitleTracks // ignore: cast_nullable_to_non_nullable
              as List<MediaTrack>,
      selectedSubtitleTrack: freezed == selectedSubtitleTrack
          ? _value.selectedSubtitleTrack
          : selectedSubtitleTrack // ignore: cast_nullable_to_non_nullable
              as MediaTrack?,
      subtitlesEnabled: null == subtitlesEnabled
          ? _value.subtitlesEnabled
          : subtitlesEnabled // ignore: cast_nullable_to_non_nullable
              as bool,
      isLocked: null == isLocked
          ? _value.isLocked
          : isLocked // ignore: cast_nullable_to_non_nullable
              as bool,
      lockIconVisible: null == lockIconVisible
          ? _value.lockIconVisible
          : lockIconVisible // ignore: cast_nullable_to_non_nullable
              as bool,
      hasError: null == hasError
          ? _value.hasError
          : hasError // ignore: cast_nullable_to_non_nullable
              as bool,
      errorMessage: freezed == errorMessage
          ? _value.errorMessage
          : errorMessage // ignore: cast_nullable_to_non_nullable
              as String?,
      autoPlayCountdown: freezed == autoPlayCountdown
          ? _value.autoPlayCountdown
          : autoPlayCountdown // ignore: cast_nullable_to_non_nullable
              as int?,
      zoomScale: null == zoomScale
          ? _value.zoomScale
          : zoomScale // ignore: cast_nullable_to_non_nullable
              as double,
      loopMode: null == loopMode
          ? _value.loopMode
          : loopMode // ignore: cast_nullable_to_non_nullable
              as LoopMode,
      textureId: freezed == textureId
          ? _value.textureId
          : textureId // ignore: cast_nullable_to_non_nullable
              as int?,
      currentCue: null == currentCue
          ? _value.currentCue
          : currentCue // ignore: cast_nullable_to_non_nullable
              as String,
      videoWidth: null == videoWidth
          ? _value.videoWidth
          : videoWidth // ignore: cast_nullable_to_non_nullable
              as int,
      videoHeight: null == videoHeight
          ? _value.videoHeight
          : videoHeight // ignore: cast_nullable_to_non_nullable
              as int,
      sleepTimerEndsAt: freezed == sleepTimerEndsAt
          ? _value.sleepTimerEndsAt
          : sleepTimerEndsAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      sleepTimerEndOfVideo: null == sleepTimerEndOfVideo
          ? _value.sleepTimerEndOfVideo
          : sleepTimerEndOfVideo // ignore: cast_nullable_to_non_nullable
              as bool,
      subtitleDelay: null == subtitleDelay
          ? _value.subtitleDelay
          : subtitleDelay // ignore: cast_nullable_to_non_nullable
              as double,
      holdFastForward: null == holdFastForward
          ? _value.holdFastForward
          : holdFastForward // ignore: cast_nullable_to_non_nullable
              as bool,
      abRepeatStart: freezed == abRepeatStart
          ? _value.abRepeatStart
          : abRepeatStart // ignore: cast_nullable_to_non_nullable
              as Duration?,
      abRepeatEnd: freezed == abRepeatEnd
          ? _value.abRepeatEnd
          : abRepeatEnd // ignore: cast_nullable_to_non_nullable
              as Duration?,
      seekInterval: null == seekInterval
          ? _value.seekInterval
          : seekInterval // ignore: cast_nullable_to_non_nullable
              as int,
      isMiniPlayerActive: null == isMiniPlayerActive
          ? _value.isMiniPlayerActive
          : isMiniPlayerActive // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

/// @nodoc

class _$PlayerStateImpl extends _PlayerState {
  const _$PlayerStateImpl(
      {this.isInitialized = false,
      this.isPlaying = false,
      this.intendsToPlay = false,
      this.controlsVisible = true,
      this.isPipMode = false,
      this.rotationMode = RotationMode.auto,
      this.isSeeking = false,
      this.seekValue = 0.0,
      this.position = Duration.zero,
      this.duration = Duration.zero,
      this.volume = 100.0,
      this.brightness = 0.5,
      this.playbackSpeed = 1.0,
      this.fitMode = FitMode.contain,
      final List<MediaTrack> audioTracks = const [],
      this.selectedAudioTrack,
      this.audioEnabled = true,
      this.swipeGesture = SwipeGesture.none,
      this.swipeValue = 0.0,
      final List<VideoFile> folderVideos = const [],
      this.currentIndex = -1,
      final List<MediaTrack> subtitleTracks = const [],
      this.selectedSubtitleTrack,
      this.subtitlesEnabled = true,
      this.isLocked = false,
      this.lockIconVisible = false,
      this.hasError = false,
      this.errorMessage,
      this.autoPlayCountdown,
      this.zoomScale = 1.0,
      this.loopMode = LoopMode.none,
      this.textureId,
      this.currentCue = '',
      this.videoWidth = 16,
      this.videoHeight = 9,
      this.sleepTimerEndsAt,
      this.sleepTimerEndOfVideo = false,
      this.subtitleDelay = 0.0,
      this.holdFastForward = false,
      this.abRepeatStart,
      this.abRepeatEnd,
      this.seekInterval = 10,
      this.isMiniPlayerActive = false})
      : _audioTracks = audioTracks,
        _folderVideos = folderVideos,
        _subtitleTracks = subtitleTracks,
        super._();

  @override
  @JsonKey()
  final bool isInitialized;
  @override
  @JsonKey()
  final bool isPlaying;
// Playback INTENT (playWhenReady). Drives the play/pause button so it stays
// stable during a seek's brief re-buffer (where isPlaying flickers false).
  @override
  @JsonKey()
  final bool intendsToPlay;
  @override
  @JsonKey()
  final bool controlsVisible;
  @override
  @JsonKey()
  final bool isPipMode;
  @override
  @JsonKey()
  final RotationMode rotationMode;
  @override
  @JsonKey()
  final bool isSeeking;
  @override
  @JsonKey()
  final double seekValue;
  @override
  @JsonKey()
  final Duration position;
  @override
  @JsonKey()
  final Duration duration;
  @override
  @JsonKey()
  final double volume;
  @override
  @JsonKey()
  final double brightness;
  @override
  @JsonKey()
  final double playbackSpeed;
  @override
  @JsonKey()
  final FitMode fitMode;
  final List<MediaTrack> _audioTracks;
  @override
  @JsonKey()
  List<MediaTrack> get audioTracks {
    if (_audioTracks is EqualUnmodifiableListView) return _audioTracks;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_audioTracks);
  }

  @override
  final MediaTrack? selectedAudioTrack;
// False when the user explicitly disabled the audio track ("Disable" option).
  @override
  @JsonKey()
  final bool audioEnabled;
  @override
  @JsonKey()
  final SwipeGesture swipeGesture;
  @override
  @JsonKey()
  final double swipeValue;
  final List<VideoFile> _folderVideos;
  @override
  @JsonKey()
  List<VideoFile> get folderVideos {
    if (_folderVideos is EqualUnmodifiableListView) return _folderVideos;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_folderVideos);
  }

  @override
  @JsonKey()
  final int currentIndex;
  final List<MediaTrack> _subtitleTracks;
  @override
  @JsonKey()
  List<MediaTrack> get subtitleTracks {
    if (_subtitleTracks is EqualUnmodifiableListView) return _subtitleTracks;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_subtitleTracks);
  }

  @override
  final MediaTrack? selectedSubtitleTrack;
  @override
  @JsonKey()
  final bool subtitlesEnabled;
  @override
  @JsonKey()
  final bool isLocked;
  @override
  @JsonKey()
  final bool lockIconVisible;
  @override
  @JsonKey()
  final bool hasError;
  @override
  final String? errorMessage;
  @override
  final int? autoPlayCountdown;
  @override
  @JsonKey()
  final double zoomScale;
  @override
  @JsonKey()
  final LoopMode loopMode;
// Flutter texture the native ExoPlayer renders into (null until ready).
  @override
  final int? textureId;
// Current subtitle cue text (rendered as a styled Flutter overlay).
  @override
  @JsonKey()
  final String currentCue;
// Last known video dimensions (for PiP aspect ratio).
  @override
  @JsonKey()
  final int videoWidth;
  @override
  @JsonKey()
  final int videoHeight;
// Sleep timer: wall-clock time at which playback auto-pauses (null = off).
  @override
  final DateTime? sleepTimerEndsAt;
// Sleep timer variant: pause when the current video finishes.
  @override
  @JsonKey()
  final bool sleepTimerEndOfVideo;
// Subtitle sync offset in seconds (+ = subtitles later, − = earlier).
  @override
  @JsonKey()
  final double subtitleDelay;
// True while the user holds to temporarily fast-forward (2× speed).
  @override
  @JsonKey()
  final bool holdFastForward;
// A-B repeat: loop between these two points when both are set.
  @override
  final Duration? abRepeatStart;
  @override
  final Duration? abRepeatEnd;
// Double-tap seek interval in seconds.
  @override
  @JsonKey()
  final int seekInterval;
// Mini player state.
  @override
  @JsonKey()
  final bool isMiniPlayerActive;

  @override
  String toString() {
    return 'PlayerState(isInitialized: $isInitialized, isPlaying: $isPlaying, intendsToPlay: $intendsToPlay, controlsVisible: $controlsVisible, isPipMode: $isPipMode, rotationMode: $rotationMode, isSeeking: $isSeeking, seekValue: $seekValue, position: $position, duration: $duration, volume: $volume, brightness: $brightness, playbackSpeed: $playbackSpeed, fitMode: $fitMode, audioTracks: $audioTracks, selectedAudioTrack: $selectedAudioTrack, audioEnabled: $audioEnabled, swipeGesture: $swipeGesture, swipeValue: $swipeValue, folderVideos: $folderVideos, currentIndex: $currentIndex, subtitleTracks: $subtitleTracks, selectedSubtitleTrack: $selectedSubtitleTrack, subtitlesEnabled: $subtitlesEnabled, isLocked: $isLocked, lockIconVisible: $lockIconVisible, hasError: $hasError, errorMessage: $errorMessage, autoPlayCountdown: $autoPlayCountdown, zoomScale: $zoomScale, loopMode: $loopMode, textureId: $textureId, currentCue: $currentCue, videoWidth: $videoWidth, videoHeight: $videoHeight, sleepTimerEndsAt: $sleepTimerEndsAt, sleepTimerEndOfVideo: $sleepTimerEndOfVideo, subtitleDelay: $subtitleDelay, holdFastForward: $holdFastForward, abRepeatStart: $abRepeatStart, abRepeatEnd: $abRepeatEnd, seekInterval: $seekInterval, isMiniPlayerActive: $isMiniPlayerActive)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PlayerStateImpl &&
            (identical(other.isInitialized, isInitialized) ||
                other.isInitialized == isInitialized) &&
            (identical(other.isPlaying, isPlaying) ||
                other.isPlaying == isPlaying) &&
            (identical(other.intendsToPlay, intendsToPlay) ||
                other.intendsToPlay == intendsToPlay) &&
            (identical(other.controlsVisible, controlsVisible) ||
                other.controlsVisible == controlsVisible) &&
            (identical(other.isPipMode, isPipMode) ||
                other.isPipMode == isPipMode) &&
            (identical(other.rotationMode, rotationMode) ||
                other.rotationMode == rotationMode) &&
            (identical(other.isSeeking, isSeeking) ||
                other.isSeeking == isSeeking) &&
            (identical(other.seekValue, seekValue) ||
                other.seekValue == seekValue) &&
            (identical(other.position, position) ||
                other.position == position) &&
            (identical(other.duration, duration) ||
                other.duration == duration) &&
            (identical(other.volume, volume) || other.volume == volume) &&
            (identical(other.brightness, brightness) ||
                other.brightness == brightness) &&
            (identical(other.playbackSpeed, playbackSpeed) ||
                other.playbackSpeed == playbackSpeed) &&
            (identical(other.fitMode, fitMode) || other.fitMode == fitMode) &&
            const DeepCollectionEquality()
                .equals(other._audioTracks, _audioTracks) &&
            (identical(other.selectedAudioTrack, selectedAudioTrack) ||
                other.selectedAudioTrack == selectedAudioTrack) &&
            (identical(other.audioEnabled, audioEnabled) ||
                other.audioEnabled == audioEnabled) &&
            (identical(other.swipeGesture, swipeGesture) ||
                other.swipeGesture == swipeGesture) &&
            (identical(other.swipeValue, swipeValue) ||
                other.swipeValue == swipeValue) &&
            const DeepCollectionEquality()
                .equals(other._folderVideos, _folderVideos) &&
            (identical(other.currentIndex, currentIndex) ||
                other.currentIndex == currentIndex) &&
            const DeepCollectionEquality()
                .equals(other._subtitleTracks, _subtitleTracks) &&
            (identical(other.selectedSubtitleTrack, selectedSubtitleTrack) ||
                other.selectedSubtitleTrack == selectedSubtitleTrack) &&
            (identical(other.subtitlesEnabled, subtitlesEnabled) ||
                other.subtitlesEnabled == subtitlesEnabled) &&
            (identical(other.isLocked, isLocked) ||
                other.isLocked == isLocked) &&
            (identical(other.lockIconVisible, lockIconVisible) ||
                other.lockIconVisible == lockIconVisible) &&
            (identical(other.hasError, hasError) ||
                other.hasError == hasError) &&
            (identical(other.errorMessage, errorMessage) ||
                other.errorMessage == errorMessage) &&
            (identical(other.autoPlayCountdown, autoPlayCountdown) ||
                other.autoPlayCountdown == autoPlayCountdown) &&
            (identical(other.zoomScale, zoomScale) ||
                other.zoomScale == zoomScale) &&
            (identical(other.loopMode, loopMode) ||
                other.loopMode == loopMode) &&
            (identical(other.textureId, textureId) ||
                other.textureId == textureId) &&
            (identical(other.currentCue, currentCue) ||
                other.currentCue == currentCue) &&
            (identical(other.videoWidth, videoWidth) ||
                other.videoWidth == videoWidth) &&
            (identical(other.videoHeight, videoHeight) ||
                other.videoHeight == videoHeight) &&
            (identical(other.sleepTimerEndsAt, sleepTimerEndsAt) ||
                other.sleepTimerEndsAt == sleepTimerEndsAt) &&
            (identical(other.sleepTimerEndOfVideo, sleepTimerEndOfVideo) ||
                other.sleepTimerEndOfVideo == sleepTimerEndOfVideo) &&
            (identical(other.subtitleDelay, subtitleDelay) ||
                other.subtitleDelay == subtitleDelay) &&
            (identical(other.holdFastForward, holdFastForward) ||
                other.holdFastForward == holdFastForward) &&
            (identical(other.abRepeatStart, abRepeatStart) ||
                other.abRepeatStart == abRepeatStart) &&
            (identical(other.abRepeatEnd, abRepeatEnd) ||
                other.abRepeatEnd == abRepeatEnd) &&
            (identical(other.seekInterval, seekInterval) ||
                other.seekInterval == seekInterval) &&
            (identical(other.isMiniPlayerActive, isMiniPlayerActive) ||
                other.isMiniPlayerActive == isMiniPlayerActive));
  }

  @override
  int get hashCode => Object.hashAll([
        runtimeType,
        isInitialized,
        isPlaying,
        intendsToPlay,
        controlsVisible,
        isPipMode,
        rotationMode,
        isSeeking,
        seekValue,
        position,
        duration,
        volume,
        brightness,
        playbackSpeed,
        fitMode,
        const DeepCollectionEquality().hash(_audioTracks),
        selectedAudioTrack,
        audioEnabled,
        swipeGesture,
        swipeValue,
        const DeepCollectionEquality().hash(_folderVideos),
        currentIndex,
        const DeepCollectionEquality().hash(_subtitleTracks),
        selectedSubtitleTrack,
        subtitlesEnabled,
        isLocked,
        lockIconVisible,
        hasError,
        errorMessage,
        autoPlayCountdown,
        zoomScale,
        loopMode,
        textureId,
        currentCue,
        videoWidth,
        videoHeight,
        sleepTimerEndsAt,
        sleepTimerEndOfVideo,
        subtitleDelay,
        holdFastForward,
        abRepeatStart,
        abRepeatEnd,
        seekInterval,
        isMiniPlayerActive
      ]);

  /// Create a copy of PlayerState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$PlayerStateImplCopyWith<_$PlayerStateImpl> get copyWith =>
      __$$PlayerStateImplCopyWithImpl<_$PlayerStateImpl>(this, _$identity);
}

abstract class _PlayerState extends PlayerState {
  const factory _PlayerState(
      {final bool isInitialized,
      final bool isPlaying,
      final bool intendsToPlay,
      final bool controlsVisible,
      final bool isPipMode,
      final RotationMode rotationMode,
      final bool isSeeking,
      final double seekValue,
      final Duration position,
      final Duration duration,
      final double volume,
      final double brightness,
      final double playbackSpeed,
      final FitMode fitMode,
      final List<MediaTrack> audioTracks,
      final MediaTrack? selectedAudioTrack,
      final bool audioEnabled,
      final SwipeGesture swipeGesture,
      final double swipeValue,
      final List<VideoFile> folderVideos,
      final int currentIndex,
      final List<MediaTrack> subtitleTracks,
      final MediaTrack? selectedSubtitleTrack,
      final bool subtitlesEnabled,
      final bool isLocked,
      final bool lockIconVisible,
      final bool hasError,
      final String? errorMessage,
      final int? autoPlayCountdown,
      final double zoomScale,
      final LoopMode loopMode,
      final int? textureId,
      final String currentCue,
      final int videoWidth,
      final int videoHeight,
      final DateTime? sleepTimerEndsAt,
      final bool sleepTimerEndOfVideo,
      final double subtitleDelay,
      final bool holdFastForward,
      final Duration? abRepeatStart,
      final Duration? abRepeatEnd,
      final int seekInterval,
      final bool isMiniPlayerActive}) = _$PlayerStateImpl;
  const _PlayerState._() : super._();

  @override
  bool get isInitialized;
  @override
  bool
      get isPlaying; // Playback INTENT (playWhenReady). Drives the play/pause button so it stays
// stable during a seek's brief re-buffer (where isPlaying flickers false).
  @override
  bool get intendsToPlay;
  @override
  bool get controlsVisible;
  @override
  bool get isPipMode;
  @override
  RotationMode get rotationMode;
  @override
  bool get isSeeking;
  @override
  double get seekValue;
  @override
  Duration get position;
  @override
  Duration get duration;
  @override
  double get volume;
  @override
  double get brightness;
  @override
  double get playbackSpeed;
  @override
  FitMode get fitMode;
  @override
  List<MediaTrack> get audioTracks;
  @override
  MediaTrack?
      get selectedAudioTrack; // False when the user explicitly disabled the audio track ("Disable" option).
  @override
  bool get audioEnabled;
  @override
  SwipeGesture get swipeGesture;
  @override
  double get swipeValue;
  @override
  List<VideoFile> get folderVideos;
  @override
  int get currentIndex;
  @override
  List<MediaTrack> get subtitleTracks;
  @override
  MediaTrack? get selectedSubtitleTrack;
  @override
  bool get subtitlesEnabled;
  @override
  bool get isLocked;
  @override
  bool get lockIconVisible;
  @override
  bool get hasError;
  @override
  String? get errorMessage;
  @override
  int? get autoPlayCountdown;
  @override
  double get zoomScale;
  @override
  LoopMode
      get loopMode; // Flutter texture the native ExoPlayer renders into (null until ready).
  @override
  int?
      get textureId; // Current subtitle cue text (rendered as a styled Flutter overlay).
  @override
  String get currentCue; // Last known video dimensions (for PiP aspect ratio).
  @override
  int get videoWidth;
  @override
  int get videoHeight; // Sleep timer: wall-clock time at which playback auto-pauses (null = off).
  @override
  DateTime?
      get sleepTimerEndsAt; // Sleep timer variant: pause when the current video finishes.
  @override
  bool
      get sleepTimerEndOfVideo; // Subtitle sync offset in seconds (+ = subtitles later, − = earlier).
  @override
  double
      get subtitleDelay; // True while the user holds to temporarily fast-forward (2× speed).
  @override
  bool
      get holdFastForward; // A-B repeat: loop between these two points when both are set.
  @override
  Duration? get abRepeatStart;
  @override
  Duration? get abRepeatEnd; // Double-tap seek interval in seconds.
  @override
  int get seekInterval; // Mini player state.
  @override
  bool get isMiniPlayerActive;

  /// Create a copy of PlayerState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PlayerStateImplCopyWith<_$PlayerStateImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
