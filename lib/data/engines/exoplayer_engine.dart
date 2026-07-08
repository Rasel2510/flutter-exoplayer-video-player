import 'dart:async';
import 'package:flutter/services.dart';
import 'player_engine.dart';

/// [PlayerEngine] backed by a native Media3/ExoPlayer instance.
///
/// Commands go out over a shared MethodChannel keyed by player id; the native
/// side renders into a Flutter texture and pushes playback events back over a
/// per-instance EventChannel. Duration probing is a stateless metadata read
/// (MediaMetadataRetriever) that never creates a player.
class ExoPlayerEngine implements PlayerEngine {
  static const MethodChannel _methods = MethodChannel('exo/methods');

  /// Stateless duration read via the native MediaMetadataRetriever — does NOT
  /// create a player, so it never contends with playback. Used by the library's
  /// duration cache for videos MediaStore didn't already report a length for.
  static Future<Duration?> probe(String path) async {
    try {
      final ms = await _methods.invokeMethod<int>('probeDuration', {'path': path});
      if (ms == null || ms <= 0) return null;
      return Duration(milliseconds: ms);
    } catch (_) {
      return null;
    }
  }

  int? _playerId;
  int? _textureId;
  StreamSubscription<dynamic>? _eventSub;

  // Gates every command until the native player exists.
  final Completer<void> _ready = Completer<void>();

  final _playing = StreamController<bool>.broadcast();
  final _intent = StreamController<bool>.broadcast();
  final _position = StreamController<Duration>.broadcast();
  final _duration = StreamController<Duration>.broadcast();
  final _rate = StreamController<double>.broadcast();
  final _tracks = StreamController<TrackSnapshot>.broadcast();
  final _videoSize = StreamController<VideoSize>.broadcast();
  final _completed = StreamController<void>.broadcast();
  final _error = StreamController<String>.broadcast();
  final _videoUnsupported = StreamController<void>.broadcast();
  final _cues = StreamController<String>.broadcast();
  final _texture = StreamController<int?>.broadcast();

  ExoPlayerEngine() {
    _create();
  }

  Future<void> _create() async {
    try {
      final res = await _methods
          .invokeMapMethod<String, dynamic>('create');
      _playerId = res!['playerId'] as int;
      _textureId = res['textureId'] as int;
      _texture.add(_textureId);
      _eventSub = EventChannel('exo/events/$_playerId')
          .receiveBroadcastStream()
          .listen(_onEvent, onError: (Object e) => _error.add('$e'));
      if (!_ready.isCompleted) _ready.complete();
    } catch (e) {
      if (!_ready.isCompleted) _ready.completeError(e);
      _error.add('$e');
    }
  }

  void _onEvent(dynamic event) {
    if (event is! Map) return;
    switch (event['event'] as String?) {
      case 'playing':
        _playing.add(event['value'] as bool);
      case 'intent':
        _intent.add(event['value'] as bool);
      case 'position':
        _position.add(Duration(milliseconds: event['value'] as int));
      case 'duration':
        _duration.add(Duration(milliseconds: event['value'] as int));
      case 'rate':
        _rate.add((event['value'] as num).toDouble());
      case 'videoSize':
        _videoSize.add(VideoSize(
          event['width'] as int,
          event['height'] as int,
          event['rotation'] as int? ?? 0,
        ));
      case 'completed':
        _completed.add(null);
      case 'error':
        _error.add(event['message'] as String? ?? 'Playback error');
      case 'videoUnsupported':
        _videoUnsupported.add(null);
      case 'cues':
        _cues.add(event['text'] as String? ?? '');
      case 'tracks':
        _tracks.add(TrackSnapshot(
          audio: _trackList(event['audio']),
          subtitle: _trackList(event['subtitle']),
          activeAudioId: event['activeAudio'] as String?,
          activeSubtitleId: event['activeSubtitle'] as String?,
        ));
    }
  }

  List<MediaTrack> _trackList(dynamic raw) {
    if (raw is! List) return const [];
    return raw
        .map((e) => MediaTrack.fromMap(e as Map))
        .toList(growable: false);
  }

  Future<T?> _invoke<T>(String method, [Map<String, dynamic>? args]) async {
    await _ready.future;
    return _methods.invokeMethod<T>(method, {
      'playerId': _playerId,
      ...?args,
    });
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
  Stream<void> get videoUnsupportedStream => _videoUnsupported.stream;
  @override
  Stream<void> get completedStream => _completed.stream;
  @override
  Stream<String> get errorStream => _error.stream;
  @override
  Stream<String> get cuesStream => _cues.stream;
  @override
  Stream<int?> get textureIdStream => _texture.stream;
  @override
  int? get textureId => _textureId;

  // ── Commands ─────────────────────────────────────────────────────────────
  @override
  Future<void> open(String path, {Duration? start, bool play = true}) =>
      _invoke('open', {
        'path': path,
        'start': start?.inMilliseconds ?? 0,
        'play': play,
      });

  @override
  Future<void> play() => _invoke('play');
  @override
  Future<void> pause() => _invoke('pause');
  @override
  Future<void> playOrPause() => _invoke('playOrPause');
  @override
  Future<void> seek(Duration position, {bool fast = false}) =>
      _invoke('seek', {'position': position.inMilliseconds, 'fast': fast});
  @override
  Future<void> setRate(double rate) => _invoke('setRate', {'rate': rate});
  @override
  Future<void> setVolume(double percent) =>
      _invoke('setVolume', {'percent': percent});
  @override
  Future<void> setRepeatMode(int mode) =>
      _invoke('setRepeatMode', {'mode': mode});
  @override
  Future<void> selectAudioTrack(String? id) =>
      _invoke('selectAudioTrack', {'id': id});
  @override
  Future<void> selectSubtitleTrack(String? id) =>
      _invoke('selectSubtitleTrack', {'id': id});
  @override
  Future<String?> addExternalSubtitle(String path) =>
      _invoke<String>('addExternalSubtitle', {'path': path});
  @override
  Future<void> setSubtitleDelay(double seconds) =>
      _invoke('setSubtitleDelay', {'seconds': seconds});

  /// Stateless — does not touch the player instance, so it's safe to call
  /// concurrently for many files without contending with playback.
  @override
  Future<Duration?> probeDuration(String path) async {
    try {
      final ms = await _methods
          .invokeMethod<int>('probeDuration', {'path': path});
      if (ms == null || ms <= 0) return null;
      return Duration(milliseconds: ms);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> dispose() async {
    await _eventSub?.cancel();
    try {
      if (_playerId != null) {
        await _methods.invokeMethod('dispose', {'playerId': _playerId});
      }
    } catch (_) {}
    _playing.close();
    _intent.close();
    _position.close();
    _duration.close();
    _rate.close();
    _tracks.close();
    _videoSize.close();
    _completed.close();
    _error.close();
    _videoUnsupported.close();
    _cues.close();
    _texture.close();
  }
}
