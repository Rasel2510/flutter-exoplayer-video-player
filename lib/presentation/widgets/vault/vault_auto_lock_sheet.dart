import 'package:flutter/material.dart';
import 'package:flutter_video_player/core/theme/app_theme.dart';
import '../../../services/vault_settings_service.dart';
import '../common/sheet_surface.dart';

/// Duration picker for the vault's auto-lock timer — presets plus a
/// plus/minus stepper for any custom number of minutes (mirrors
/// SleepTimerSheet's custom-timer row). Pops with the chosen seconds value,
/// or null if dismissed without a change.
class VaultAutoLockSheet extends StatefulWidget {
  final int currentSeconds;

  const VaultAutoLockSheet({super.key, required this.currentSeconds});

  @override
  State<VaultAutoLockSheet> createState() => _VaultAutoLockSheetState();
}

class _VaultAutoLockSheetState extends State<VaultAutoLockSheet> {
  late int _customMinutes;

  @override
  void initState() {
    super.initState();
    _customMinutes =
        widget.currentSeconds > 0 ? (widget.currentSeconds / 60).round() : 0;
  }

  @override
  Widget build(BuildContext context) {
    return SheetSurface(
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: Row(
                children: [
                  Icon(Icons.timer_outlined, color: context.colors.accent, size: 18),
                  const SizedBox(width: 10),
                  Text(
                    'Auto-lock vault',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: context.colors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: Text(
                'Re-locks the vault after it has been in the background this long',
                style: TextStyle(fontSize: 12, color: context.colors.textMuted),
              ),
            ),
            Divider(color: context.colors.divider, height: 1),

            // Custom timer
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                children: [
                  Icon(Icons.tune_rounded, color: context.colors.textMuted, size: 18),
                  const SizedBox(width: 14),
                  Text('Custom', style: TextStyle(color: context.colors.textSecondary, fontSize: 13)),
                  const Spacer(),
                  _StepButton(
                    icon: Icons.remove_rounded,
                    onTap: () {
                      if (_customMinutes > 0) setState(() => _customMinutes -= 1);
                    },
                  ),
                  SizedBox(
                    width: 68,
                    child: Text(
                      _customMinutes == 0 ? 'Immediate' : '${_customMinutes}m',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: context.colors.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),
                  _StepButton(
                    icon: Icons.add_rounded,
                    onTap: () => setState(() => _customMinutes += 1),
                  ),
                  const SizedBox(width: 16),
                  GestureDetector(
                    onTap: () => Navigator.pop(context, _customMinutes * 60),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: context.colors.accent,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'SET',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Divider(color: context.colors.divider, height: 1),

            for (final d in VaultAutoLockDuration.values)
              _row(
                context,
                label: d.label,
                isSelected: d.seconds == widget.currentSeconds,
                onTap: () => Navigator.pop(context, d.seconds),
              ),

            SizedBox(height: 16 + MediaQuery.of(context).padding.bottom),
          ],
        ),
      ),
    );
  }

  Widget _row(
    BuildContext context, {
    required String label,
    required VoidCallback onTap,
    bool isSelected = false,
  }) {
    return InkWell(
      onTap: onTap,
      splashColor: context.colors.accentSoft,
      highlightColor: Colors.transparent,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(
          children: [
            Icon(
              Icons.timer_outlined,
              size: 18,
              color: isSelected ? context.colors.accent : context.colors.textMuted,
            ),
            const SizedBox(width: 14),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? context.colors.accent : context.colors.textSecondary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                fontSize: 13,
              ),
            ),
            if (isSelected) ...[
              const Spacer(),
              Icon(Icons.check_rounded, color: context.colors.accent, size: 16),
            ],
          ],
        ),
      ),
    );
  }
}

class _StepButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _StepButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkResponse(
      onTap: onTap,
      radius: 22,
      child: Container(
        width: 32,
        height: 32,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: context.colors.elevated,
          shape: BoxShape.circle,
          border: Border.all(color: context.colors.border),
        ),
        child: Icon(icon, size: 18, color: context.colors.textSecondary),
      ),
    );
  }
}
