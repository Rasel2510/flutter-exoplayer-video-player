part of '../player_controls_overlay.dart';

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
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Icon(icon, size: 34, color: enabled ? _kWhite60 : _kWhite12),
        ),
      );
}

// ── Bottom bar ────────────────────────────────────────────────────────────────


