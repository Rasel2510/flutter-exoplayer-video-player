import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/duration_formatter.dart';
import '../../../providers/player_provider.dart';

part 'widgets/top_bar.dart';
part 'widgets/center_controls.dart';
part 'widgets/play_button.dart';
part 'widgets/seek_pill.dart';
part 'widgets/track_button.dart';
part 'widgets/bottom_bar.dart';
part 'widgets/playback_progress_controls.dart';
part 'widgets/bottom_bar_actions.dart';
part 'widgets/minimalist_slider.dart';
part 'widgets/glass_icon_button.dart';
part 'widgets/mini_chip.dart';
part 'widgets/player_chip.dart';
part 'widgets/seek_button.dart';


// ── Design tokens ─────────────────────────────────────────────────────────────

const _kWhite100 = Colors.white;
const _kWhite60 = Color(0x99FFFFFF);
const _kWhite30 = Color(0x4DFFFFFF);
const _kWhite12 = Color(0x1FFFFFFF);
const _kBlack70 = Color(0xB3000000);
const _kBlack40 = Color(0x66000000);
const _kOrange = Color(0xFFFF8C00);

// ── Main overlay ──────────────────────────────────────────────────────────────

class PlayerControlsOverlay extends StatelessWidget {
  final String fileName;
  final VoidCallback onBack;
  final VoidCallback onTogglePlay;
  final VoidCallback onCycleFitMode;
  final VoidCallback onShowSpeed;
  final VoidCallback onShowVolume;
  final VoidCallback onShowAudio;
  final VoidCallback onShowSubtitle;
  final VoidCallback onSeekBack;
  final VoidCallback onSeekForward;
  final VoidCallback onToggleFullscreen;
  final void Function(double) onSeekStart;
  final void Function(double) onSeekUpdate;
  final void Function(double) onSeekEnd;
  final VoidCallback onPlayNext;
  final VoidCallback onPlayPrevious;
  final VoidCallback onToggleLock;
  final VoidCallback onToggleRepeat;
  final VoidCallback onAudioMode;
  final VoidCallback onSleepTimer;
  final VoidCallback onPip;
  final VoidCallback onCycleAbRepeat;

  const PlayerControlsOverlay({
    super.key,
    required this.fileName,
    required this.onBack,
    required this.onTogglePlay,
    required this.onCycleFitMode,
    required this.onShowSpeed,
    required this.onShowVolume,
    required this.onShowAudio,
    required this.onShowSubtitle,
    required this.onSeekBack,
    required this.onSeekForward,
    required this.onToggleFullscreen,
    required this.onSeekStart,
    required this.onSeekUpdate,
    required this.onSeekEnd,
    required this.onPlayNext,
    required this.onPlayPrevious,
    required this.onToggleLock,
    required this.onToggleRepeat,
    required this.onAudioMode,
    required this.onSleepTimer,
    required this.onPip,
    required this.onCycleAbRepeat,
  });

  // FIX #OPT-12: Static const gradient widgets — these decorations never change
  // so creating a new Container on every build() call is wasted allocation.
  static const _kTopGradient = DecoratedBox(
    decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xCC000000), Colors.transparent],
      ),
    ),
  );

  static const _kBottomGradient = DecoratedBox(
    decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.bottomCenter,
        end: Alignment.topCenter,
        colors: [Color(0xCC000000), Colors.transparent],
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: 180,
          child: _kTopGradient,
        ),
        const Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          height: 200,
          child: _kBottomGradient,
        ),
        SafeArea(
          child: Column(
            children: [
              _TopBar(
                fileName: fileName,
                onBack: onBack,
                onShowSpeed: onShowSpeed,
                onShowVolume: onShowVolume,
                onShowAudio: onShowAudio,
                onShowSubtitle: onShowSubtitle,
                onToggleRepeat: onToggleRepeat,
                onAudioMode: onAudioMode,
                onSleepTimer: onSleepTimer,
                onCycleAbRepeat: onCycleAbRepeat,
              ),
              const Spacer(),
              _CenterControls(
                onTogglePlay: onTogglePlay,
                onPlayPrevious: onPlayPrevious,
                onPlayNext: onPlayNext,
                onSeekBack: onSeekBack,
                onSeekForward: onSeekForward,
              ),
              const Spacer(),
              _BottomBar(
                onSeekStart: onSeekStart,
                onSeekUpdate: onSeekUpdate,
                onSeekEnd: onSeekEnd,
                onToggleFullscreen: onToggleFullscreen,
                onCycleFitMode: onCycleFitMode,
                onPip: onPip,
                onToggleLock: onToggleLock,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Top bar ───────────────────────────────────────────────────────────────────
// Two rows — like the "=" sign:
//   Row 1 : [←]  [title …]
//   Row 2 : [🔒] [speed] [🔊] [🎵] [CC] [🔁]



