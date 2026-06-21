import 'package:flutter/material.dart';
import 'package:flutter_video_player/core/theme/app_theme.dart';

/// Animated search field for the folder screen — slides in when [open] and
/// collapses to zero height when closed.
class FolderSearchBar extends StatelessWidget {
  final bool open;
  final TextEditingController controller;

  const FolderSearchBar({
    super.key,
    required this.open,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      child: open
          ? Padding(
              key: const ValueKey('search'),
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: TextField(
                controller: controller,
                autofocus: true,
                textInputAction: TextInputAction.search,
                style:
                    TextStyle(color: context.colors.textPrimary, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Search videos…',
                  prefixIcon: Icon(Icons.search_rounded,
                      size: 18, color: context.colors.textMuted),
                  suffixIcon: controller.text.isNotEmpty
                      ? IconButton(
                          icon: Icon(Icons.clear_rounded,
                              size: 16, color: context.colors.textMuted),
                          onPressed: controller.clear,
                        )
                      : null,
                ),
              ),
            )
          : const SizedBox(key: ValueKey('no-search'), height: 0),
    );
  }
}
