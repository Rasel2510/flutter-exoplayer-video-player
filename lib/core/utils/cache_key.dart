/// Shared video-path sanitisation for on-disk cache keys.
///
/// PositionService, DurationCacheService, and ThumbnailService all key their
/// caches off the video's full path, replacing any character that isn't
/// alphanumeric/dot/underscore/hyphen with '_'. They must stay byte-for-byte
/// identical or the same video would resolve to different cache entries
/// across services.
abstract final class CacheKey {
  static final _sanitiseRe = RegExp(r'[^a-zA-Z0-9._\-]');

  static String sanitise(String videoPath) =>
      videoPath.replaceAll(_sanitiseRe, '_');
}
