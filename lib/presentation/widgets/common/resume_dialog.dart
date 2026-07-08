import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/duration_formatter.dart';

/// FIX #3: Shared resume dialog, eliminating the duplicate implementations
/// that existed in home_screen.dart and folder_videos_screen.dart.
///
/// Returns [Duration.zero] for "start over", the saved [position] for "resume",
/// and [null] if the dialog is dismissed.
class ResumeDialog extends StatelessWidget {
  final Duration position;
  const ResumeDialog({super.key, required this.position});

  /// Convenience static helper — same usage pattern as [showDialog].
  static Future<Duration?> show(BuildContext context, Duration position) {
    return showDialog<Duration>(
      context: context,
      builder: (_) => ResumeDialog(position: position),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Continue watching?'),
      content: Text('Paused at ${DurationFormatter.format(position)}'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, Duration.zero),
          child: Text('Start over',
              style: TextStyle(color: context.colors.textSecondary)),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, position),
          style: FilledButton.styleFrom(
            backgroundColor: context.colors.accent,
            foregroundColor: Colors.white,
            shape: const StadiumBorder(),
            textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
          child: const Text('Resume'),
        ),
      ],
    );
  }
}