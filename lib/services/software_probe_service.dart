import 'dart:async';
import 'dart:typed_data';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';

/// Last-resort duration / thumbnail extraction using the libmpv (FFmpeg)
/// backend, for files Android's MediaMetadataRetriever can't open at all —
/// typically the same codecs the device's MediaCodec can't decode (e.g. some
/// 10-bit HEVC). Heavy (spins up a temporary libmpv player), so it's only used
/// after the fast native paths have already failed, and capped to one at a time.
class SoftwareProbeService {
  SoftwareProbeService._();
  static final SoftwareProbeService instance = SoftwareProbeService._();

  // Only one software probe at a time — each opens a full libmpv player.
  Future<void> _gate = Future.value();

  Future<T> _serialize<T>(Future<T> Function() task) {
    final completer = Completer<T>();
    _gate = _gate.then((_) async {
      try {
        completer.complete(await task());
      } catch (e, st) {
        completer.completeError(e, st);
      }
    });
    return completer.future;
  }

  /// Reads the container duration via libmpv (demux only, no decoding needed),
  /// so it works even when the video codec is undecodable on this device.
  Future<Duration?> probeDuration(String path) =>
      _serialize(() => _probeDuration(path));

  Future<Duration?> _probeDuration(String path) async {
    final player = Player();
    StreamSubscription<Duration>? sub;
    try {
      final uri = path.startsWith('/') ? 'file://$path' : path;
      final completer = Completer<Duration>();
      sub = player.stream.duration.listen((d) {
        if (d > Duration.zero && !completer.isCompleted) completer.complete(d);
      });
      await player.open(Media(uri), play: false);
      final d = await completer.future.timeout(
        const Duration(seconds: 10),
        onTimeout: () => player.state.duration,
      );
      return d > Duration.zero ? d : null;
    } catch (_) {
      return null;
    } finally {
      await sub?.cancel();
      await player.dispose();
    }
  }

  /// Decodes a single frame in software and returns it as JPEG bytes, or null on
  /// failure. Uses software decoding so it can grab a frame from codecs the
  /// hardware can't handle.
  Future<Uint8List?> grabThumbnail(String path) =>
      _serialize(() => _grabThumbnail(path));

  Future<Uint8List?> _grabThumbnail(String path) async {
    final player = Player();
    // A controller is required for libmpv to spin up its renderer so a frame is
    // available to screenshot; force software decoding to match the codecs we
    // can't decode in hardware.
    // Created for its side effect: spins up libmpv's renderer so a frame is
    // available to screenshot. Disposing the player tears it down.
    // ignore: unused_local_variable
    final controller = VideoController(
      player,
      configuration: const VideoControllerConfiguration(
        enableHardwareAcceleration: false,
      ),
    );
    try {
      final uri = path.startsWith('/') ? 'file://$path' : path;
      await player.open(Media(uri), play: false);
      // Wait until the video has real dimensions (i.e. a frame can be produced).
      await player.stream.width
          .firstWhere((w) => w != null && w > 0)
          .timeout(const Duration(seconds: 12));
      // Seek a little in so we don't grab a black intro frame, then give the
      // renderer a moment to land on the seeked frame.
      final dur = player.state.duration;
      final at = dur > const Duration(seconds: 4)
          ? const Duration(seconds: 2)
          : Duration.zero;
      await player.seek(at);
      await Future<void>.delayed(const Duration(milliseconds: 600));
      var shot = await player.screenshot(format: 'image/jpeg');
      if (shot == null || shot.isEmpty) {
        // Slow software decodes (large 10-bit HEVC) may not have landed on the
        // seeked frame yet — give it one more beat before giving up.
        await Future<void>.delayed(const Duration(milliseconds: 900));
        shot = await player.screenshot(format: 'image/jpeg');
      }
      return shot;
    } catch (_) {
      return null;
    } finally {
      // Disposing the player tears down the controller's renderer too.
      await player.dispose();
    }
  }
}
