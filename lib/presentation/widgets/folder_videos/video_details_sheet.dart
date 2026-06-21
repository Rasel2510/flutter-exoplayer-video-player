import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_video_player/core/theme/app_theme.dart';
import 'package:flutter_video_player/models/video_file.dart';
import '../../../core/utils/duration_formatter.dart';
import '../common/sheet_surface.dart';

/// Bottom-sheet showing a video's metadata (name, format, size, duration, date,
/// path). Pure presentation — pass the known [duration] (null shows "Unknown").
class VideoDetailsSheet extends StatelessWidget {
  final VideoFile vf;
  final Duration? duration;

  const VideoDetailsSheet({super.key, required this.vf, this.duration});

  @override
  Widget build(BuildContext context) {
    final durStr =
        duration != null ? DurationFormatter.format(duration!) : 'Unknown';
    final dateStr =
        '${vf.modified.year}-${vf.modified.month.toString().padLeft(2, '0')}-${vf.modified.day.toString().padLeft(2, '0')} '
        '${vf.modified.hour.toString().padLeft(2, '0')}:${vf.modified.minute.toString().padLeft(2, '0')}';

    return SheetSurface(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
            20, 0, 20, 20 + MediaQuery.of(context).padding.bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info_outline_rounded,
                    color: context.colors.accent, size: 22),
                const SizedBox(width: 10),
                Text(
                  'Video Details',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: context.colors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _item(context, 'Name', vf.name),
            _item(context, 'Format', vf.extensionLabel),
            _item(context, 'Size', vf.sizeLabel),
            _item(context, 'Duration', durStr),
            _item(context, 'Date Modified', dateStr),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _item(context, 'Path', vf.path)),
                const SizedBox(width: 8),
                IconButton(
                  icon: Icon(Icons.copy_rounded,
                      color: context.colors.textSecondary, size: 18),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: vf.path));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Path copied to clipboard'),
                        duration: Duration(seconds: 1),
                      ),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _item(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: context.colors.textMuted,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: context.colors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
