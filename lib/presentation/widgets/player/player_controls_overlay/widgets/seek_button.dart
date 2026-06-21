part of '../player_controls_overlay.dart';

class SeekButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const SeekButton({super.key, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            color: _kBlack40,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: _kWhite12),
          ),
          child: Text(
            label,
            style: const TextStyle(
              color: _kWhite60,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      );
}

