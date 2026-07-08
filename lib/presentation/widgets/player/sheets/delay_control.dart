part of 'subtitle_sheet.dart';

class _DelayControl extends StatefulWidget {
  final double delay;
  final void Function(double) onAdjust;
  final VoidCallback onReset;

  const _DelayControl({
    required this.delay,
    required this.onAdjust,
    required this.onReset,
  });

  @override
  State<_DelayControl> createState() => _DelayControlState();
}

class _DelayControlState extends State<_DelayControl> {
  late double _delay = widget.delay;
  static const _step = 0.5;

  void _bump(double delta) {
    setState(() => _delay = (_delay + delta).clamp(-60.0, 60.0));
    widget.onAdjust(delta);
  }

  @override
  Widget build(BuildContext context) {
    final label = _delay == 0
        ? '0.0s'
        : '${_delay > 0 ? '+' : ''}${_delay.toStringAsFixed(1)}s';
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          Icon(Icons.av_timer_rounded,
              color: context.colors.textMuted, size: 18),
          const SizedBox(width: 14),
          Text(
            'Sync delay',
            style: TextStyle(color: context.colors.textSecondary, fontSize: 13),
          ),
          const Spacer(),
          if (_delay != 0)
            GestureDetector(
              onTap: () {
                setState(() => _delay = 0);
                widget.onReset();
              },
              child: Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Text('Reset',
                    style: TextStyle(
                        color: context.colors.textMuted, fontSize: 11)),
              ),
            ),
          _StepButton(icon: Icons.remove_rounded, onTap: () => _bump(-_step)),
          SizedBox(
            width: 56,
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: context.colors.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
                fontFamily: 'monospace',
              ),
            ),
          ),
          _StepButton(icon: Icons.add_rounded, onTap: () => _bump(_step)),
        ],
      ),
    );
  }
}

// ── Subtitle appearance (font size / color / background) ───────────────────────


