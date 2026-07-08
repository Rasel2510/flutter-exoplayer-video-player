import 'package:flutter/material.dart';

/// YouTube-style transparent icon button for the mini player.
class YtMiniButton extends StatelessWidget {
  final IconData? icon;
  final Widget? child;
  final double size;
  final VoidCallback onTap;

  const YtMiniButton({
    super.key,
    this.icon,
    this.child,
    required this.size,
    required this.onTap,
  }) : assert(icon != null || child != null,
            'Either icon or child must be provided');

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: child ?? Icon(icon!, size: size, color: Colors.white),
      ),
    );
  }
}
