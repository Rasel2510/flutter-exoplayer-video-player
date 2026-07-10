import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_video_player/presentation/providers/player_controls_style_provider.dart';
import 'package:flutter_video_player/presentation/widgets/common/glass_surface.dart';

class LockOverlay extends ConsumerWidget {
  final VoidCallback onUnlock;

  const LockOverlay({super.key, required this.onUnlock});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final frosted =
        ref.watch(controlsStyleProvider) == PlayerControlsStyle.frosted;
    return SafeArea(
      child: Align(
        alignment: Alignment.centerLeft,
        child: Padding(
          padding: const EdgeInsets.only(left: 20),
          child: GestureDetector(
            onTap: onUnlock,
            child: GlassSurface(
              style: frosted ? GlassStyle.frosted : GlassStyle.tint,
              padding: const EdgeInsets.all(12),
              child: const Icon(
                Icons.lock_rounded,
                color: Colors.white,
                size: 22,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
