part of '../player_controls_overlay.dart';

class _MiniChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final Color? color;
  const _MiniChip({required this.label, required this.onTap, this.color});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
          decoration: BoxDecoration(
            color: _kBlack40,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: color ?? _kWhite12),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: color ?? _kWhite100,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.4,
            ),
          ),
        ),
      );
}

// ── Public exports ────────────────────────────────────────────────────────────


