import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_video_player/core/theme/app_theme.dart';
import 'package:flutter_video_player/core/utils/duration_formatter.dart';
import 'package:flutter_video_player/presentation/providers/player_provider.dart';
import 'package:flutter_video_player/presentation/widgets/common/sheet_surface.dart';

part 'sleep_timer_step_button.dart';

/// Bottom sheet to set a sleep timer (auto-pause after a delay or at end of
/// video). Reads/drives the player provider directly and ticks once a second
/// so the remaining time stays live.
class SleepTimerSheet extends ConsumerStatefulWidget {
  const SleepTimerSheet({super.key});

  @override
  ConsumerState<SleepTimerSheet> createState() => _SleepTimerSheetState();
}

class _SleepTimerSheetState extends ConsumerState<SleepTimerSheet> {
  Timer? _ticker;
  int _customMinutes = 60;

  static const _presets = [15, 30, 45, 60, 90];

  @override
  void initState() {
    super.initState();
    // Refresh the "remaining" readout once a second while the sheet is open.
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final (:endsAt, :endOfVideo) = ref.watch(playerProvider.select((s) => (
          endsAt: s.sleepTimerEndsAt,
          endOfVideo: s.sleepTimerEndOfVideo,
        )));
    final notifier = ref.read(playerProvider.notifier);
    final active = endsAt != null || endOfVideo;

    Duration? remaining;
    if (endsAt != null) {
      final d = endsAt.difference(DateTime.now());
      remaining = d.isNegative ? Duration.zero : d;
    }

    return SheetSurface(
      child: SingleChildScrollView(
        child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
            child: Row(
              children: [
                Icon(Icons.bedtime_rounded,
                    color: context.colors.accent, size: 18),
                const SizedBox(width: 10),
                Text(
                  'Sleep timer',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: context.colors.textPrimary,
                  ),
                ),
                const Spacer(),
                if (active)
                  Text(
                    endOfVideo
                        ? 'End of video'
                        : remaining != null
                            ? DurationFormatter.format(remaining)
                            : '',
                    style: TextStyle(
                      color: context.colors.accent,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'monospace',
                    ),
                  ),
              ],
            ),
          ),

          Divider(color: context.colors.divider, height: 1),

          // Custom timer
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              children: [
                Icon(Icons.tune_rounded, color: context.colors.textMuted, size: 18),
                const SizedBox(width: 14),
                Text('Custom', style: TextStyle(color: context.colors.textSecondary, fontSize: 13)),
                const Spacer(),
                _StepButton(
                  icon: Icons.remove_rounded,
                  onTap: () {
                    if (_customMinutes > 5) {
                      setState(() => _customMinutes -= 5);
                    }
                  },
                ),
                SizedBox(
                  width: 50,
                  child: Text(
                    '${_customMinutes}m',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: context.colors.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
                _StepButton(
                  icon: Icons.add_rounded,
                  onTap: () {
                    setState(() => _customMinutes += 5);
                  },
                ),
                const SizedBox(width: 16),
                GestureDetector(
                  onTap: () {
                    notifier.setSleepTimer(duration: Duration(minutes: _customMinutes));
                    Navigator.pop(context);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: context.colors.accent,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text('SET', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                  ),
                ),
              ],
            ),
          ),

          Divider(color: context.colors.divider, height: 1),

          for (final m in _presets)
            _row(
              context,
              label: '$m minutes',
              onTap: () {
                notifier.setSleepTimer(duration: Duration(minutes: m));
                Navigator.pop(context);
              },
            ),
          _row(
            context,
            label: 'End of video',
            icon: Icons.movie_outlined,
            isSelected: endOfVideo,
            onTap: () {
              notifier.setSleepTimer(endOfVideo: true);
              Navigator.pop(context);
            },
          ),
          if (active)
            _row(
              context,
              label: 'Turn off',
              icon: Icons.close_rounded,
              danger: true,
              onTap: () {
                notifier.cancelSleepTimer();
                Navigator.pop(context);
              },
            ),

          SizedBox(height: 16 + MediaQuery.of(context).padding.bottom),
        ],
        ),
      ),
    );
  }

  Widget _row(
    BuildContext context, {
    required String label,
    required VoidCallback onTap,
    IconData icon = Icons.timer_outlined,
    bool isSelected = false,
    bool danger = false,
  }) {
    final color = danger
        ? const Color(0xFFE5534B)
        : (isSelected ? context.colors.accent : context.colors.textSecondary);
    return InkWell(
      onTap: onTap,
      splashColor: context.colors.accentSoft,
      highlightColor: Colors.transparent,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(
          children: [
            Icon(icon,
                size: 18,
                color: danger
                    ? const Color(0xFFE5534B)
                    : (isSelected
                        ? context.colors.accent
                        : context.colors.textMuted)),
            const SizedBox(width: 14),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                fontSize: 13,
              ),
            ),
            if (isSelected) ...[
              const Spacer(),
              Icon(Icons.check_rounded, color: context.colors.accent, size: 16),
            ],
          ],
        ),
      ),
    );
  }
}


