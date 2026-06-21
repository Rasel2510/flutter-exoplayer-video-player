import 'package:flutter/material.dart';
import 'centered_prompt.dart';
import 'primary_button.dart';

class PermissionPrompt extends StatelessWidget {
  final VoidCallback onRetry;
  
  const PermissionPrompt({super.key, required this.onRetry});

  @override
  Widget build(BuildContext context) => CenteredPrompt(
        icon: Icons.lock_outline_rounded,
        title: 'Storage access needed',
        subtitle: 'Grant permission to scan your device for videos',
        action: PrimaryButton(label: 'Grant Permission', onTap: onRetry),
      );
}
