import 'package:flutter/material.dart';
import 'package:flutter_video_player/core/theme/app_theme.dart';

/// Bottom bar shown in the vault's multi-select mode: Restore and Delete
/// permanently. Mirrors SelectionActionBar's layout (used for the regular
/// folder video list) but with vault-specific actions/labels.
class VaultSelectionBar extends StatelessWidget {
  final int selectedCount;
  final VoidCallback? onRestore;
  final VoidCallback? onDelete;

  const VaultSelectionBar({
    super.key,
    required this.selectedCount,
    required this.onRestore,
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
          child: Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: onRestore,
                  style: FilledButton.styleFrom(
                    backgroundColor: context.colors.accent,
                    foregroundColor: context.colors.bg,
                    disabledBackgroundColor: context.colors.divider,
                    disabledForegroundColor: context.colors.textMuted,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: const StadiumBorder(),
                  ),
                  icon: const Icon(Icons.restore_rounded, size: 20),
                  label: Text(
                    'Restore ($selectedCount)',
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  onPressed: onDelete,
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: context.colors.divider,
                    disabledForegroundColor: context.colors.textMuted,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: const StadiumBorder(),
                  ),
                  icon: const Icon(Icons.delete_outline_rounded, size: 20),
                  label: const Text(
                    'Delete',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
