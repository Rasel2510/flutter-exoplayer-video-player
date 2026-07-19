import 'dart:async';
import 'dart:typed_data';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'player_engine.dart';

/// [PlayerEngine] backed by media_kit (libmpv + FFmpeg) — the same software
/// decoders VLC uses. Used as the FALLBACK engine for files whose codec the
/// device's MediaCodec (ExoPlayer) can't decode, e.g. some 10-bit HEVC.
///
/// Implements the identical interface as [ExoPlayerEngine] so the rest of the
/// app is unchanged: it renders into the Flutter texture exposed by
/// [VideoController.id] and pushes the same playback events.
class MediaKitEngine implements PlayerEngine {
  final Player _player = Player();

  // CRITICAL: disable hardware acceleration. This engine is the fallback for
  // files the device's MediaCodec can't decode (e.g. 10-bit HEVC). With HW accel
  // on (the default), libmpv would route video through the SAME MediaCodec
  // decoder that already failed — audio would play but the picture stays black.
  // Forcing software decoding makes libmpv use FFmpeg (lavc), exactly like VLC.
  late final VideoController _controller = VideoController(
    _player,
    configuration: const VideoControllerConfiguration(
      enableHardwareAcceleration: false,
    ),
  );

  /// The media_kit render controller — player_screen renders this with the
  /// media_kit `Video` widget (its texture must be displayed that way on Android,
  /// not via a raw Flutter `Texture`).
  VideoController get controller => _controller;

  final _playing = StreamController<bool>.broadcast();
  final _intent = StreamController<bool>.broadcast();
  final _position = StreamController<Duration>.broadcast();
  final _duration = StreamController<Duration>.broadcast();
  final _rate = StreamController<double>.broadcast();
  final _tracks = StreamController<TrackSnapshot>.broadcast();
  final _videoSize = StreamController<VideoSize>.broadcast();
  final _completed = StreamController<void>.broadcast();
  final _error = StreamController<String>.broadcast();
  final _cues = StreamController<String>.broadcast();
  final _texture = StreamController<int?>.broadcast();

  final List<StreamSubscription> _subs = [];

  // Latest known dimensions, so a width-only or height-only update still emits a
  // complete VideoSize.
  int _width = 0;
  int _height = 0;

  // media_kit reports the user's playback intent directly via `playing`; there's
  // no separate buffering flicker to filter, so intent mirrors playing.
  bool _lastIntent = false;

  // Cached track lists so selectAudioTrack/selectSubtitleTrack can resolve an
  // app-facing id back to a media_kit track object.
  List<AudioTrack> _mkAudio = const [];
  List<SubtitleTrack> _mkSubtitle = const [];

  MediaKitEngine() {
    _wire();
  }

  void _wire() {
    _texture.add(_controller.id.value);
    _controller.id.addListener(_onTextureChanged);

    _subs.add(_player.stream.playing.listen((v) {
      _playing.add(v);
      if (v != _lastIntent) {
        _lastIntent = v;
        _intent.add(v);
      }
    }));
    _subs.add(_player.stream.position.listen(_position.add));
    _subs.add(_player.stream.duration.listen((v) {
      if (v > Duration.zero) _duration.add(v);
    }));
    _subs.add(_player.stream.rate.listen((v) => _rate.add(v.toDouble())));
    _subs.add(_player.stream.completed.listen((done) {
      if (done) _completed.add(null);
    }));
    _subs.add(_player.stream.width.listen((w) {
      if (w != null && w > 0) {
        _width = w;
        if (_height > 0) _videoSize.add(VideoSize(_width, _height));
      }
    }));
    _subs.add(_player.stream.height.listen((h) {
      if (h != null && h > 0) {
        _height = h;
        if (_width > 0) _videoSize.add(VideoSize(_width, _height));
      }
    }));
    _subs.add(_player.stream.subtitle.listen((lines) {
      _cues.add(lines.where((l) => l.isNotEmpty).join('\n'));
    }));
    _subs.add(_player.stream.error.listen((e) {
      if (e.isNotEmpty) _error.add(e);
    }));
    _subs.add(_player.stream.tracks.listen(_onTracks));
  }

  void _onTextureChanged() => _texture.add(_controller.id.value);

  void _onTracks(Tracks t) {
    // Drop media_kit's synthetic 'auto'/'no' entries — they aren't real tracks.
    _mkAudio = t.audio.where((a) => a.id != 'auto' && a.id != 'no').toList();
    _mkSubtitle =
        t.subtitle.where((s) => s.id != 'auto' && s.id != 'no').toList();

    final activeAudio = _player.state.track.audio;
    final activeSub = _player.state.track.subtitle;

    _tracks.add(TrackSnapshot(
      audio: _mkAudio
          .map((a) => MediaTrack(id: a.id, title: a.title, language: a.language))
          .toList(growable: false),
      subtitle: _mkSubtitle
          .map((s) => MediaTrack(id: s.id, title: s.title, language: s.language))
          .toList(growable: false),
      activeAudioId: (activeAudio.id == 'auto' || activeAudio.id == 'no')
          ? null
          : activeAudio.id,
      activeSubtitleId: (activeSub.id == 'auto' || activeSub.id == 'no')
          ? null
          : activeSub.id,
    ));
  }

  // ── Streams ────────────────────────────────────────────────────────────────
  @override
  Stream<bool> get playingStream => _playing.stream;
  @override
  Stream<bool> get intentStream => _intent.stream;
  @override
  Stream<Duration> get positionStream => _position.stream;
  @override
  Stream<Duration> get durationStream => _duration.stream;
  @override
  Stream<double> get rateStream => _rate.stream;
  @override
  Stream<TrackSnapshot> get tracksStream => _tracks.stream;
  @override
  Stream<VideoSize> get videoSizeStream => _videoSize.stream;
  @override
  Stream<void> get completedStream => _completed.stream;
  @override
  Stream<String> get errorStream => _error.stream;
  @override
  // media_kit (libmpv/FFmpeg) decodes in software, so it never reports a video
  // track as unsupported — there's nothing to fall back to.
  Stream<void> get videoUnsupportedStream => const Stream.empty();
  @override
  Stream<String> get cuesStream => _cues.stream;
  @override
  Stream<int?> get textureIdStream => _texture.stream;
  @override
  int? get textureId => _controller.id.value;

  // ── Commands ─────────────────────────────────────────────────────────────
  @override
  Future<void> open(String path, {Duration? start, bool play = true}) async {
    final uri = path.startsWith('/') ? 'file://$path' : path;
    await _player.open(Media(uri, start: start), play: play);
  }

  @override
  Future<void> play() => _player.play();
  @override
  Future<void> pause() => _player.pause();
  @override
  Future<void> playOrPause() => _player.playOrPause();
  @override
  Future<void> seek(Duration position, {bool fast = false}) =>
      _player.seek(position);
  @override
  Future<void> setRate(double rate) => _player.setRate(rate);

  @override
  Future<void> setVolume(double percent) =>
      // media_kit volume is 0–100 (and supports >100 boost like the app expects).
      _player.setVolume(percent.clamp(0, 200).toDouble());

  @override
  Future<void> setRepeatMode(int mode) => _player.setPlaylistMode(switch (mode) {
        1 => PlaylistMode.single,
        2 => PlaylistMode.loop,
        _ => PlaylistMode.none,
      });

  @override
  Future<void> selectAudioTrack(String? id) async {
    if (id == null) {
      await _player.setAudioTrack(AudioTrack.no());
      return;
    }
    final t = _mkAudio.where((a) => a.id == id).firstOrNull;
    if (t != null) await _player.setAudioTrack(t);
  }

  @override
  Future<void> selectSubtitleTrack(String? id) async {
    if (id == null) {
      await _player.setSubtitleTrack(SubtitleTrack.no());
      return;
    }
    final t = _mkSubtitle.where((s) => s.id == id).firstOrNull;
    if (t != null) await _player.setSubtitleTrack(t);
  }

  @override
  Future<String?> addExternalSubtitle(String path) async {
    final uri = path.startsWith('/') ? 'file://$path' : path;
    await _player.setSubtitleTrack(SubtitleTrack.uri(uri));
    return 'ext';
  }

  @override
  Future<void> setSubtitleDelay(double seconds) async {
    // libmpv supports a sub-delay property, but media_kit doesn't expose it on
    // every version; accepted as a no-op (matches the ExoPlayer engine).
  }

  /// Captures the currently rendered video frame as JPEG bytes (null if no
  /// frame is available yet). Lets the app reuse the software-decoded frame
  /// for thumbnails / lock-screen art instead of opening a second software
  /// decoder on the same file while it's playing.
  Future<Uint8List?> screenshot() => _player.screenshot(format: 'image/jpeg');

  @override
  Future<Duration?> probeDuration(String path) async => null;

  @override
  Future<void> dispose() async {
    _controller.id.removeListener(_onTextureChanged);
    for (final s in _subs) {
      await s.cancel();
    }
    _subs.clear();
    await _player.dispose();
    _playing.close();
    _intent.close();
    _position.close();
    _duration.close();
    _rate.close();
    _tracks.close();
    _videoSize.close();
    _completed.close();
    _error.close();
    _cues.close();
    _texture.close();
  }
}
