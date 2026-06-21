import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class AutoPlayCountdown extends StatelessWidget {
  final int countdown;
  final String nextVideoName;
  final VoidCallback onCancel;
  final VoidCallback onPlayNow;

  const AutoPlayCountdown({
    super.key,
    required this.countdown,
    required this.nextVideoName,
    required this.onCancel,
    required this.onPlayNow,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 100,
      left: 16,
      right: 16,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xD1000000),
          borderRadius: BorderRadius.circular(14),
          border:
              Border.all(color: const Color(0x1EFFFFFF), width: 1),
        ),
        child: Row(
          children: [
            // Countdown ring
            SizedBox(
              width: 44,
              height: 44,
              child: Stack(
                alignment: Alignment.center,
                children: [
                    CircularProgressIndicator(
                      value: countdown / 5.0,
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(context.colors.accent),
                      backgroundColor: Colors.white12,
                    ),
                  Text(
                    '$countdown',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Up next',
                    style: TextStyle(
                      color: Colors.white54,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    nextVideoName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            // Play Now button
            GestureDetector(
              onTap: onPlayNow,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: context.colors.accent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Play',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            // Cancel button
            GestureDetector(
              onTap: onCancel,
              child: Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: const Color(0x1AFFFFFF),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.close_rounded,
                    color: Colors.white70, size: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
