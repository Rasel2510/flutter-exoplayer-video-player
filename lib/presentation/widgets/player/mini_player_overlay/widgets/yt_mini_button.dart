import 'package:flutter/material.dart';

/// YouTube-style transparent icon button for the mini player.
class YtMiniButton extends StatelessWidget {
  final IconData icon;
  final double size;
  final VoidCallback onTap;

  const YtMiniButton({
    super.key,
    required this.icon,
    required this.size,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Icon(icon, size: size, color: Colors.white),
      ),
    );
  }
}
