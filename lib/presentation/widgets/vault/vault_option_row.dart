import 'package:flutter/material.dart';
import 'package:flutter_video_player/core/theme/app_theme.dart';

/// Row used inside the vault's bottom sheets (per-video options, settings
/// menu) — mirrors folder_videos/OptionRow's look so vault sheets match the
/// rest of the app instead of using default Material chrome.
class VaultOptionRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  const VaultOptionRow({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? context.colors.textPrimary;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.sm,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 14),
          child: Row(
            children: [
              Icon(icon, size: 20, color: c),
              const SizedBox(width: 14),
              Text(label,
                  style: TextStyle(
                      fontSize: 14, color: c, fontWeight: FontWeight.w400)),
            ],
          ),
        ),
      ),
    );
  }
}
