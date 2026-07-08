import 'package:flutter_video_player/core/theme/app_theme.dart';
import 'package:flutter/material.dart';

class FormatBadge extends StatelessWidget {
  final String ext;

  const FormatBadge(this.ext, {super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
          color: context.colors.accentSoft, borderRadius: AppRadius.xs),
      child: Text(
        ext,
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w700,
          color: context.colors.accent,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
