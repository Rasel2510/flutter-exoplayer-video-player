import 'package:flutter/material.dart';
import 'centered_prompt.dart';
import 'primary_button.dart';

class EmptyLibrary extends StatelessWidget {
  final VoidCallback onScan;
  
  const EmptyLibrary({super.key, required this.onScan});

  @override
  Widget build(BuildContext context) => CenteredPrompt(
        icon: Icons.video_library_outlined,
        title: 'No videos found',
        subtitle: 'Pull down to refresh, or tap below to scan',
        action: PrimaryButton(label: 'Scan now', onTap: onScan),
      );
}
