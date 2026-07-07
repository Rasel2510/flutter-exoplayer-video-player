import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_video_player/core/theme/app_theme.dart';
import 'package:flutter_video_player/presentation/providers/library_appearance_provider.dart';

class NewVideoBadge extends ConsumerWidget {
  const NewVideoBadge({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorIndex = ref.watch(
        libraryAppearanceProvider.select((a) => a.newBadgeColorIndex));
    final color = resolveLibraryAccent(colorIndex, context.colors.folderIcon);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        // Tinted from the badge's own accent (not the fixed theme pink) so
        // the chip always matches whatever "New badge color" is selected —
        // this is also exactly what the settings-sheet preview renders.
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
      ),
      child: Text(
        'NEW',
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w800,
          color: color,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}
