import 'package:flutter/material.dart';
import 'package:flutter_video_player/core/theme/app_theme.dart';

/// Numeric keypad (1-9, 0, backspace) used by the vault PIN screen.
class VaultKeypad extends StatelessWidget {
  final void Function(String) onDigit;
  final VoidCallback onBackspace;
  final bool enabled;

  const VaultKeypad({
    super.key,
    required this.onDigit,
    required this.onBackspace,
    required this.enabled,
  });

  Widget _key(BuildContext context, String label,
      {VoidCallback? onTap, Widget? child}) {
    return Expanded(
      child: AspectRatio(
        aspectRatio: 1.4,
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Material(
            color: Colors.transparent,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: enabled ? onTap : null,
              child: Center(
                child: child ??
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w500,
                        color: context.colors.textPrimary,
                      ),
                    ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const rows = [
      ['1', '2', '3'],
      ['4', '5', '6'],
      ['7', '8', '9'],
    ];

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final row in rows)
          Row(children: [
            for (final d in row) _key(context, d, onTap: () => onDigit(d)),
          ]),
        Row(
          children: [
            const Expanded(child: SizedBox()),
            _key(context, '0', onTap: () => onDigit('0')),
            _key(
              context,
              '',
              onTap: onBackspace,
              child: Icon(Icons.backspace_outlined,
                  size: 20, color: context.colors.textSecondary),
            ),
          ],
        ),
      ],
    );
  }
}
