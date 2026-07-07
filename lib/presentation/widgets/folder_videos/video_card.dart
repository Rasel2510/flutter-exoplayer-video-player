import 'package:flutter/material.dart';
import 'package:flutter_video_player/core/theme/app_theme.dart';
import 'package:flutter_video_player/core/utils/duration_formatter.dart';
import 'package:flutter_video_player/models/video_file.dart';
import '../thumbnail_widget/thumbnail_widget.dart';
import '../animated_squish_card.dart';
import 'format_badge.dart';
import 'new_video_badge.dart';
import 'sort_option.dart';

class VideoCard extends StatelessWidget {
  final VideoFile vf;
  final Duration? savedPos;
  final Duration? totalDur;
  final bool isNew;
  final SortOption sortBy;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final bool selectionMode;
  final bool isSelected;
  final VoidCallback? onSelectToggle;

  const VideoCard({
    super.key,
    required this.vf,
    required this.onTap,
    required this.onLongPress,
    this.savedPos,
    this.totalDur,
    this.isNew = false,
    this.sortBy = SortOption.name,
    this.selectionMode = false,
    this.isSelected = false,
    this.onSelectToggle,
  });

  String get _subtitle {
    switch (sortBy) {
      case SortOption.dateModified:
        final d = vf.modified;
        // Avoid padLeft — direct conditional is allocation-free.
        final mo = d.month < 10 ? '0${d.month}' : '${d.month}';
        final dy = d.day   < 10 ? '0${d.day}'   : '${d.day}';
        return '${d.year}-$mo-$dy';
      case SortOption.duration:
        return totalDur != null
            ? DurationFormatter.format(totalDur!)
            : vf.sizeLabel;
      case SortOption.name:
      case SortOption.size:
        return vf.sizeLabel;
    }
  }

  @override
  Widget build(BuildContext context) {
    final progress = (savedPos != null &&
            totalDur != null &&
            totalDur!.inMilliseconds > 0)
        ? (savedPos!.inMilliseconds / totalDur!.inMilliseconds).clamp(0.0, 1.0)
        : 0.0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: AnimatedSquishCard(
        child: Material(
          color: context.colors.surface,
          borderRadius: AppRadius.md,
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: selectionMode ? onSelectToggle : onTap,
            onLongPress: selectionMode ? onSelectToggle : onLongPress,
            splashColor: context.colors.accentSoft,
            highlightColor: Colors.transparent,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 12, 16, 12),
                  child: Row(
                    children: [
                      AnimatedSize(
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeOutCubic,
                        child: selectionMode
                            ? Padding(
                                padding: const EdgeInsets.only(right: 12),
                                child: AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 150),
                                  transitionBuilder: (child, anim) =>
                                      ScaleTransition(
                                          scale: anim, child: child),
                                  child: Icon(
                                    isSelected
                                        ? Icons.check_circle_rounded
                                        : Icons.circle_outlined,
                                    key: ValueKey(isSelected),
                                    color: isSelected
                                        ? context.colors.accent
                                        : context.colors.textSecondary,
                                    size: 22,
                                  ),
                                ),
                              )
                            : const SizedBox.shrink(),
                      ),
                      Hero(
                        tag: 'video_thumb_${vf.path}',
                        child: ClipRRect(
                          borderRadius: AppRadius.sm,
                          child: VideoThumbnailWidget(
                            videoPath: vf.path,
                            width: 88,
                            height: 58,
                            duration: totalDur,
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              vf.name,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: context.colors.textPrimary,
                                height: 1.3,
                                letterSpacing: -0.1,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (isNew) ...[
                              const SizedBox(height: 3),
                              const NewVideoBadge(),
                            ],
                            const SizedBox(height: 6),
                            Row(children: [
                              FormatBadge(vf.extensionLabel),
                              const SizedBox(width: 8),
                              Text(_subtitle,
                                  style: context.textStyles.caption),
                              if (savedPos != null) ...[
                                const SizedBox(width: 8),
                                Text(
                                  DurationFormatter.format(savedPos!),
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: context.colors.accent,
                                    fontFamily: 'monospace',
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ]),
                          ],
                        ),
                      ),
                      if (!selectionMode)
                        GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: onLongPress,
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Icon(Icons.more_vert_rounded,
                                size: 20, color: context.colors.textMuted),
                          ),
                        ),
                    ],
                  ),
                ),
                if (savedPos != null && progress > 0)
                  LinearProgressIndicator(
                    value: progress,
                    minHeight: 2,
                    backgroundColor: context.colors.progressBg,
                    valueColor:
                        AlwaysStoppedAnimation(context.colors.progressFill),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

