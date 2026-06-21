part of '../volume_sheet.dart';

class _PresetButton extends StatelessWidget {
  final String label;
  final bool active;
  final bool isBoost;
  final Color? accent;
  final Color accentSoft;
  final Color border;
  final Color muted;
  final VoidCallback onTap;

  const _PresetButton({
    required this.label,
    required this.active,
    required this.isBoost,
    required this.accent,
    required this.accentSoft,
    required this.border,
    required this.muted,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: active ? accentSoft : Colors.transparent,
          border: Border.all(
            color: active
                ? (accent ?? border)
                : isBoost
                    ? const Color(0xFFFF8C00).withValues(alpha: 0.2)
                    : border,
          ),
          borderRadius: AppRadius.sm,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'monospace',
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: active
                ? (accent ?? muted)
                : isBoost
                    ? const Color(0xFFFF8C00).withValues(alpha: 0.6)
                    : muted,
          ),
        ),
      ),
    );
  }
}
