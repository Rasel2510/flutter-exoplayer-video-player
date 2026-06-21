abstract final class DurationFormatter {
  static String format(Duration d) {
    // Avoid .toString().padLeft() — each call allocates a new String object.
    // Direct conditional interpolation avoids that allocation entirely.
    final h  = d.inHours;
    final m  = d.inMinutes.remainder(60);
    final s  = d.inSeconds.remainder(60);
    final mm = m < 10 ? '0$m' : '$m';
    final ss = s < 10 ? '0$s' : '$s';
    return h > 0 ? '$h:$mm:$ss' : '$mm:$ss';
  }

  static String timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24)   return '${diff.inHours}h ago';
    if (diff.inDays < 7)     return '${diff.inDays}d ago';
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}
