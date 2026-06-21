import 'package:flutter/material.dart';
import 'package:flutter_video_player/core/theme/app_theme.dart';
import 'package:flutter_video_player/core/utils/duration_formatter.dart';

class ResumePill extends StatelessWidget {
  final Duration position;
  final VoidCallback onTap;

  const ResumePill({super.key, required this.position, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: context.colors.accentSoft,
          borderRadius: AppRadius.xl,
          border: Border.all(color: context.colors.accentGlow, width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.play_arrow_rounded,
                size: 13, color: context.colors.accent),
            const SizedBox(width: 4),
            Text(
              DurationFormatter.format(position),
              style: TextStyle(
                fontSize: 10,
                color: context.colors.accent,
                fontWeight: FontWeight.w600,
                fontFamily: 'monospace',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
