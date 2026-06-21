import 'package:flutter/material.dart';
import 'package:flutter_video_player/core/theme/app_theme.dart';

/// Bottom bar shown in multi-select mode: a single "Delete Selected (N)" action.
/// [onDelete] is null when nothing is selected, which disables the button.
class SelectionDeleteBar extends StatelessWidget {
  final int selectedCount;
  final VoidCallback? onDelete;

  const SelectionDeleteBar({
    super.key,
    required this.selectedCount,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.colors.surface,
        border: Border(top: BorderSide(color: context.colors.divider)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: FilledButton.icon(
            onPressed: onDelete,
            style: FilledButton.styleFrom(
              backgroundColor: context.colors.errorRed,
              foregroundColor: Colors.white,
              disabledBackgroundColor: context.colors.divider,
              disabledForegroundColor: context.colors.textMuted,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: const StadiumBorder(),
            ),
            icon: const Icon(Icons.delete_outline_rounded),
            label: Text(
              'Delete Selected ($selectedCount)',
              style:
                  const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
          ),
        ),
      ),
    );
  }
}
