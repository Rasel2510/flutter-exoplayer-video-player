abstract final class FileSizeFormatter {
  static const _kb = 1024;
  static const _mb = 1024 * 1024;
  static const _gb = 1024 * 1024 * 1024;

  static String format(int bytes) {
    if (bytes < _mb) return '${(bytes / _kb).toStringAsFixed(1)} KB';
    if (bytes < _gb) return '${(bytes / _mb).toStringAsFixed(1)} MB';
    return '${(bytes / _gb).toStringAsFixed(2)} GB';
  }
}
