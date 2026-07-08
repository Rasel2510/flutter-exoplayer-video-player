import 'package:flutter/material.dart';
import 'package:flutter_video_player/core/theme/app_theme.dart';

class ErrorState extends StatelessWidget {
  final String? message;
  final VoidCallback onRetry;
  final VoidCallback onBack;

  const ErrorState({
    super.key,
    this.message,
    required this.onRetry,
    required this.onBack,
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
                color: context.colors.errorBg,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.error_outline_rounded,
                  size: 30, color: context.colors.errorRed),
            ),
            const SizedBox(height: 20),
            const Text(
              'Unable to play video',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600),
            ),
            if (message != null) ...[
              const SizedBox(height: 8),
              Text(
                message!,
                textAlign: TextAlign.center,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white54,
                  fontSize: 12,
                ),
              ),
            ],
            const SizedBox(height: 28),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                OutlinedButton(
                  onPressed: onBack,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white70,
                    side: const BorderSide(color: Colors.white24),
                    shape: const StadiumBorder(),
                  ),
                  child: const Text('Go back'),
                ),
                const SizedBox(width: 12),
                FilledButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: const Text('Retry'),
                  style: FilledButton.styleFrom(
                    backgroundColor: context.colors.accent,
                    shape: const StadiumBorder(),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
