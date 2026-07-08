part of 'player_controls_overlay.dart';

class _TrackButton extends StatelessWidget {
  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;
  const _TrackButton(
      {required this.icon, required this.enabled, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: enabled ? onTap : null,
        behavior: HitTestBehavior.opaque,
        child: Container(
          width: 42,
          height: 42,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: _kBlack40,
            border: Border.fromBorderSide(BorderSide(color: _kWhite12)),
          ),
          child: Icon(icon, size: 26, color: enabled ? _kWhite90 : _kWhite12),
        ),
      );
}

// ── Bottom bar ────────────────────────────────────────────────────────────────


