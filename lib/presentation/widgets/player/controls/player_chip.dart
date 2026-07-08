part of 'player_controls_overlay.dart';

class PlayerChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const PlayerChip({super.key, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) => _MiniChip(label: label, onTap: onTap);
}


