import 'package:flutter/material.dart';
import 'package:flutter_video_player/core/theme/app_theme.dart';
import '../common/sheet_surface.dart';
import 'vault_option_row.dart';

/// The vault's settings menu — Change PIN and Auto-lock timer. Opened from
/// the app bar's overflow icon as a themed bottom sheet (matching every
/// other sheet in the app) instead of a default Material popup menu.
class VaultMenuSheet extends StatelessWidget {
  final VoidCallback onChangePin;
  final VoidCallback onAutoLockTimer;

  const VaultMenuSheet({
    super.key,
    required this.onChangePin,
    required this.onAutoLockTimer,
  });

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).padding.bottom;
    return SheetSurface(
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 4),
              child: Text(
                'Vault settings',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: context.colors.textPrimary,
                ),
              ),
            ),
            Divider(color: context.colors.divider),
            Padding(
              padding: EdgeInsets.fromLTRB(20, 4, 20, 16 + bottomPad),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  VaultOptionRow(
                    icon: Icons.lock_reset_rounded,
                    label: 'Change PIN',
                    onTap: onChangePin,
                  ),
                  VaultOptionRow(
                    icon: Icons.timer_outlined,
                    label: 'Auto-lock timer',
                    onTap: onAutoLockTimer,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
