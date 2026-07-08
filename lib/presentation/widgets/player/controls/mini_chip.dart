part of 'player_controls_overlay.dart';

class _MiniChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final Color? color;
  const _MiniChip({required this.label, required this.onTap, this.color});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          height: 32,
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 13),
          decoration: BoxDecoration(
            color: _kBlack40,
            // Stadium shape to match the circular glass buttons beside it.
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color ?? _kWhite12),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: color ?? _kWhite100,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
            ),
          ),
        ),
      );
}

// ── Public exports ────────────────────────────────────────────────────────────


