import 'dart:async';

/// A selectable audio or subtitle track exposed by the playback engine.
///
/// Replaces media_kit's `AudioTrack` / `SubtitleTrack` so the rest of the app
/// is engine-agnostic. `id` is the engine's opaque handle for the track
/// (ExoPlayer group/track index encoded as a string).
class MediaTrack {
  final String id;
  final String? title;
  final String? language;

  const MediaTrack({required this.id, this.title, this.language});

  factory MediaTrack.fromMap(Map<dynamic, dynamic> m) => MediaTrack(
        id: m['id'] as String,
        title: m['title'] as String?,
        language: m['language'] as String?,
      );
}

/// Snapshot of the available + currently-active tracks, pushed by the engine
/// whenever the track set or selection changes.
class TrackSnapshot {
  final List<MediaTrack> audio;
  final List<MediaTrack> subtitle;
  final String? activeAudioId;

  /// null = subtitles disabled / none selected.
  final String? activeSubtitleId;

  const TrackSnapshot({
    this.audio = const [],
    this.subtitle = const [],
    this.activeAudioId,
    this.activeSubtitleId,
  });
}

class VideoSize {
  final int width;
  final int height;
  const VideoSize(this.width, this.height);
  static const zero = VideoSize(0, 0);
}

/// Engine-agnostic player interface. The Android implementation
/// ([ExoPlayerEngine]) is backed by a native Media3/ExoPlayer instance that
/// renders into a Flutter texture and reports events over an EventChannel.
abstract class PlayerEngine {
  // ── Event streams ──────────────────────────────────────────────────────────
  Stream<bool> get playingStream;

  /// The user's playback intent (playWhenReady, excluding ended/idle). Unlike
  /// [playingStream] this does NOT flip false during a seek's re-buffer, so it's
  /// the right signal for the play/pause button.
  Stream<bool> get intentStream;
  Stream<Duration> get positionStream;
  Stream<Duration> get durationStream;
  Stream<double> get rateStream;
  Stream<TrackSnapshot> get tracksStream;
  Stream<VideoSize> get videoSizeStream;

  /// Fires when the current item plays to its end.
  Stream<void> get completedStream;

  /// Fires with a human-readable message when playback errors.
  Stream<String> get errorStream;

  /// The active subtitle cue text ('' when none), for rendering as a styled
  /// Flutter overlay (keeps full control over subtitle appearance).
  Stream<String> get cuesStream;

  // ── Render surface ───────────────────────────────────────────────────────
  /// Flutter texture id the video renders into, or null until prepared.
  int? get textureId;
  Stream<int?> get textureIdStream;

  // ── Commands ───────────────────────────────────────────────────────────────
  Future<void> open(String path, {Duration? start, bool play = true});
  Future<void> play();
  Future<void> pause();
  Future<void> playOrPause();
  /// Seek to [position]. Set [fast] for scrubbing — it snaps to the nearest
  /// keyframe (near-instant, no decode hitch) instead of an exact seek.
  Future<void> seek(Duration position, {bool fast = false});
  Future<void> setRate(double rate);

  /// Output volume as a percentage 0–200 (>100 amplifies, like the media_kit
  /// build's volume boost).
  Future<void> setVolume(double percent);

  /// Loop mode: 0 = off, 1 = repeat-one, 2 = repeat-all.
  Future<void> setRepeatMode(int mode);

  /// Pass null to disable the audio track entirely.
  Future<void> selectAudioTrack(String? id);

  /// Pass null to disable subtitles.
  Future<void> selectSubtitleTrack(String? id);

  /// Loads an external subtitle file and returns its new track id (or null on
  /// failure).
  Future<String?> addExternalSubtitle(String path);

  /// Subtitle timing offset in seconds (+ later, − earlier).
  Future<void> setSubtitleDelay(double seconds);

  /// Lightweight metadata-only duration read (no playback/decoding), used by
  /// the library to fill in durations MediaStore didn't provide.
  Future<Duration?> probeDuration(String path);

  Future<void> dispose();
}
