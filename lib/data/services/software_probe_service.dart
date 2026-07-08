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
    final controller = VideoController(
      player,
      configuration: const VideoControllerConfiguration(
        enableHardwareAcceleration: false,
      ),
    );
    try {
      final uri = path.startsWith('/') ? 'file://$path' : path;
      await player.open(Media(uri), play: false);
      // Wait until a frame has actually RENDERED — not merely until the
      // demuxer reports dimensions. mpv's screenshot-raw reads the video
      // output's current frame and silently returns null before the first
      // render, and a software 10-bit HEVC decode can take many seconds to
      // produce that first frame even though width/height arrive instantly
      // from the demuxer.
      await controller.waitUntilFirstFrameRendered
          .timeout(const Duration(seconds: 20));
      // Seek a little in so we don't grab a black intro frame.
      if (player.state.duration > const Duration(seconds: 4)) {
        await player.seek(const Duration(seconds: 2));
      }
      // The seeked frame lands asynchronously — poll until the renderer has
      // one to give us instead of betting on a single fixed delay.
      for (var attempt = 0; attempt < 8; attempt++) {
        await Future<void>.delayed(const Duration(milliseconds: 400));
        final shot = await player.screenshot(format: 'image/jpeg');
        if (shot != null && shot.isNotEmpty) return shot;
      }
      return null;
    } catch (_) {
      return null;
    } finally {
      // Disposing the player tears down the controller's renderer too.
      await player.dispose();
    }
  }
}
