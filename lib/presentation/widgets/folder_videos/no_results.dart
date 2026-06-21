import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';


class NoResults extends StatelessWidget {
  final String query;

  const NoResults({super.key, required this.query});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.search_off_rounded,
              size: 40, color: context.colors.textMuted),
          const SizedBox(height: 14),
          Text(
            'No videos match "$query"',
            style: TextStyle(color: context.colors.textSecondary, fontSize: 14),
          ),
        ],
      ),
    );
  }
}
