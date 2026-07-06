import 'package:flutter/material.dart';
import 'package:flutter_video_player/core/theme/app_theme.dart';

class NewVideoBadge extends StatelessWidget {
  const NewVideoBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: context.colors.folderTint,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: context.colors.folderIcon.withValues(alpha: 0.3), width: 1),
      ),
      child: Text(
        'NEW',
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w800,
          color: context.colors.folderIcon,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}
