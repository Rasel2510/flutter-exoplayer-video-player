import 'package:flutter/material.dart';
import 'package:flutter_video_player/core/theme/app_theme.dart';

class NoResults extends StatelessWidget {
  final String query;

  const NoResults({super.key, required this.query});

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 80),
          child: Center(
            child: Column(
              children: [
                Icon(Icons.search_off_rounded,
                    size: 40, color: context.colors.textMuted),
                const SizedBox(height: 14),
                Text(
                  'No folders match "$query"',
                  style: TextStyle(
                      color: context.colors.textSecondary, fontSize: 14),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
