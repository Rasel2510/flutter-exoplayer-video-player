import 'package:flutter/material.dart';
import 'package:flutter_video_player/core/theme/app_theme.dart';

class ScanningScreen extends StatelessWidget {
  final int progress;
  final int storageCount;

  const ScanningScreen(
      {super.key, required this.progress, required this.storageCount});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 36,
            height: 36,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(height: 24),
          Text('Scanning device…',
              style: context.textStyles.body
                  .copyWith(color: context.colors.textSecondary)),
          const SizedBox(height: 6),
          Text('$progress videos found', style: context.textStyles.caption),
          if (storageCount > 1) ...[
            const SizedBox(height: 4),
            Text('$storageCount storages', style: context.textStyles.caption),
          ],
        ],
      ),
    );
  }
}
