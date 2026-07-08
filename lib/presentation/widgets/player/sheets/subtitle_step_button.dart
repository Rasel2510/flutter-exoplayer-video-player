part of 'subtitle_sheet.dart';

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
        width: 34,
        height: 34,
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

