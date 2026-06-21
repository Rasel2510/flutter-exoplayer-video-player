import '../../../core/utils/duration_formatter.dart';
import 'package:flutter/material.dart';

class ResumeFab extends StatelessWidget {
  final Duration position;
  final VoidCallback onTap;

  const ResumeFab({super.key, required this.position, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.extended(
      onPressed: onTap,
      icon: const Icon(Icons.play_arrow_rounded, size: 22),
      label: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Resume',
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.2)),
          Text(
            DurationFormatter.format(position),
            style: const TextStyle(
              fontSize: 10,
              fontFamily: 'monospace',
              fontWeight: FontWeight.w400,
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }
}
