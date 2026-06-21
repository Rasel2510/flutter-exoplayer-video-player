import 'package:flutter/material.dart';
import 'package:flutter_video_player/core/theme/app_theme.dart';

class CenteredPrompt extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget action;

  const CenteredPrompt({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                  color: context.colors.surface, shape: BoxShape.circle),
              child: Icon(icon, size: 28, color: context.colors.textMuted),
            ),
            const SizedBox(height: 20),
            Text(title,
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: context.colors.textPrimary)),
            const SizedBox(height: 6),
            Text(subtitle,
                style: context.textStyles.bodySmall,
                textAlign: TextAlign.center),
            const SizedBox(height: 28),
            action,
          ],
        ),
      ),
    );
  }
}
