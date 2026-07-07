import 'package:flutter/material.dart';
import 'package:flutter_video_player/core/theme/app_theme.dart';

/// Bottom bar shown in multi-select mode: the Delete action. Move-to-Vault
/// lives in the app bar (a lock icon beside the select-all icon) instead of
/// here now, so this is a single full-width button rather than a two-up row.
/// [onDelete] is null when nothing is selected, which disables the button.
class SelectionActionBar extends StatelessWidget {
  final int selectedCount;
  final VoidCallback? onDelete;

  const SelectionActionBar({
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
              minimumSize: const Size.fromHeight(0),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: const StadiumBorder(),
            ),
            icon: const Icon(Icons.delete_outline_rounded, size: 20),
            label: Text(
              'Delete ($selectedCount)',
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
          ),
        ),
      ),
    );
  }
}

