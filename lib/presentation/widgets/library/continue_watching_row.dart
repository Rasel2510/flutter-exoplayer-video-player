import 'package:flutter/material.dart';
import 'package:flutter_video_player/core/theme/app_theme.dart';
import 'package:flutter_video_player/core/utils/duration_formatter.dart';
import 'package:flutter_video_player/data/models/video_file.dart';
import 'package:flutter_video_player/presentation/widgets/common/thumbnail_widget.dart';

/// One partially-watched video surfaced in the Continue Watching row:
/// the recents entry joined with its saved position and (when known) duration.
class ContinueWatchingItem {
  final VideoFile video;
  final Duration position;
  final Duration? duration;

  const ContinueWatchingItem({
    required this.video,
    required this.position,
    this.duration,
  });

  /// 0–1 watched fraction; 0 when the duration isn't known yet.
  double get progress {
    final total = duration?.inMilliseconds ?? 0;
    if (total <= 0) return 0;
    return (position.inMilliseconds / total).clamp(0.0, 1.0);
  }
}

/// Horizontal "Continue Watching" strip shown at the top of the library:
/// recently played videos with a resume point. Tap resumes playback directly
/// (no dialog); long-press removes the entry from the row.
class ContinueWatchingRow extends StatelessWidget {
  final List<ContinueWatchingItem> items;
  final void Function(ContinueWatchingItem item) onTap;
  final void Function(ContinueWatchingItem item) onRemove;

  const ContinueWatchingRow({
    super.key,
    required this.items,
    required this.onTap,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 4, 4, 8),
          child: Text('Continue Watching', style: context.textStyles.label),
        ),
        SizedBox(
          height: 138,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            // Let card shadows/ink splash out of the strip's tight bounds.
            clipBehavior: Clip.none,
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (_, i) {
              final item = items[i];
              return _ContinueWatchingCard(
                item: item,
                onTap: () => onTap(item),
                onLongPress: () => onRemove(item),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
      ],
    );
  }
}

class _ContinueWatchingCard extends StatelessWidget {
  final ContinueWatchingItem item;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const _ContinueWatchingCard({
    required this.item,
    required this.onTap,
    required this.onLongPress,
  });

  String get _caption {
    final dur = item.duration;
    if (dur != null && dur > item.position) {
      return '${DurationFormatter.format(dur - item.position)} left';
    }
    return DurationFormatter.format(item.position);
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 148,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          onLongPress: onLongPress,
          borderRadius: AppRadius.sm,
          splashColor: context.colors.accentSoft,
          highlightColor: Colors.transparent,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: AppRadius.sm,
                child: Stack(
                  children: [
                    VideoThumbnailWidget(
                      videoPath: item.video.path,
                      width: 148,
                      height: 83,
                      duration: item.duration,
                    ),
                    if (item.progress > 0)
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 0,
                        child: LinearProgressIndicator(
                          value: item.progress,
                          minHeight: 3,
                          backgroundColor: context.colors.progressBg,
                          valueColor: AlwaysStoppedAnimation(
                              context.colors.progressFill),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              Text(
                item.video.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: context.colors.textPrimary,
                  height: 1.25,
                  letterSpacing: -0.1,
                ),
              ),
              const SizedBox(height: 3),
              Text(_caption, style: context.textStyles.caption),
            ],
          ),
        ),
      ),
    );
  }
}
