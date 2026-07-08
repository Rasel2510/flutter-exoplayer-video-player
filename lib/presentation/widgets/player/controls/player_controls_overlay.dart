import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_video_player/core/theme/app_theme.dart';
import 'package:flutter_video_player/core/utils/duration_formatter.dart';
import 'package:flutter_video_player/presentation/providers/player_controls_style_provider.dart';
import 'package:flutter_video_player/presentation/providers/player_provider.dart';

part 'top_bar.dart';
part 'center_controls.dart';
part 'play_button.dart';
part 'seek_pill.dart';
part 'track_button.dart';
part 'bottom_bar.dart';
part 'playback_progress_controls.dart';
part 'bottom_bar_actions.dart';
part 'minimalist_slider.dart';
part 'glass_icon_button.dart';
part 'glass_surface.dart';
part 'mini_chip.dart';
part 'player_chip.dart';
part 'seek_button.dart';


// ── Design tokens ─────────────────────────────────────────────────────────────

const _kWhite100 = Colors.white;
const _kWhite90 = Color(0xE6FFFFFF);
const _kWhite60 = Color(0x99FFFFFF);
const _kWhite30 = Color(0x4DFFFFFF);
const _kWhite20 = Color(0x33FFFFFF);
const _kWhite12 = Color(0x1FFFFFFF);
const _kBlack40 = Color(0x66000000);
const _kOrange = Color(0xFFFF8C00);

// Shared across every frosted surface (ImageFilter is immutable) so we don't
// allocate a new blur handle per button on each rebuild.
final ImageFilter _kFrostFilter =
    ImageFilter.blur(sigmaX: 18.0, sigmaY: 18.0);

// Glass surface fills. A light sheen at the top edge (simulating rim light on
// glass) eases into a darker body that keeps white icons legible over bright
// frames — the iOS control-centre recipe. Frosted variants sit over a live
// blur so their bodies are lighter (more video colour shows through); tint
// variants are darker since there's no blur to add depth.
const _kFrostGradient = LinearGradient(
  begin: Alignment.topCenter,
  end: Alignment.bottomCenter,
  colors: [Color(0x40FFFFFF), Color(0x1F000000), Color(0x42000000)],
  stops: [0.0, 0.45, 1.0],
);
const _kFrostGradientStrong = LinearGradient(
  begin: Alignment.topCenter,
  end: Alignment.bottomCenter,
  colors: [Color(0x4DFFFFFF), Color(0x3D000000), Color(0x5C000000)],
  stops: [0.0, 0.45, 1.0],
);
const _kTintGradient = LinearGradient(
  begin: Alignment.topCenter,
  end: Alignment.bottomCenter,
  colors: [Color(0x24FFFFFF), Color(0x4D000000), Color(0x6B000000)],
  stops: [0.0, 0.4, 1.0],
);
const _kTintGradientStrong = LinearGradient(
  begin: Alignment.topCenter,
  end: Alignment.bottomCenter,
  colors: [Color(0x2EFFFFFF), Color(0x8C000000), Color(0xB3000000)],
  stops: [0.0, 0.4, 1.0],
);

/// Inherited style marker read by every [_GlassSurface] so the control
/// material (black tint vs frosted blur) is switched from one place without
/// threading the style through every widget constructor.
class _GlassStyleScope extends InheritedWidget {
  final PlayerControlsStyle style;
  const _GlassStyleScope({required this.style, required super.child});

  static PlayerControlsStyle of(BuildContext context) =>
      context
          .dependOnInheritedWidgetOfExactType<_GlassStyleScope>()
          ?.style ??
      PlayerControlsStyle.tint;

  @override
  bool updateShouldNotify(_GlassStyleScope oldWidget) =>
      style != oldWidget.style;
}

// ── Main overlay ──────────────────────────────────────────────────────────────

class PlayerControlsOverlay extends StatelessWidget {
  final PlayerControlsStyle controlsStyle;
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
    required this.controlsStyle,
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
  // Three stops give an eased falloff — the old two-stop scrim faded
  // linearly, which reads as a visible hard band over bright frames.
  static const _kTopGradient = DecoratedBox(
    decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xD9000000), Color(0x4D000000), Colors.transparent],
        stops: [0.0, 0.55, 1.0],
      ),
    ),
  );

  static const _kBottomGradient = DecoratedBox(
    decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.bottomCenter,
        end: Alignment.topCenter,
        colors: [Color(0xD9000000), Color(0x4D000000), Colors.transparent],
        stops: [0.0, 0.55, 1.0],
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    Widget content = Stack(
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

    // In frosted mode, a single BackdropGroup lets every _GlassSurface share
    // one backdrop blur pass instead of one per button.
    if (controlsStyle == PlayerControlsStyle.frosted) {
      content = BackdropGroup(child: content);
    }

    // _GlassStyleScope hands the chosen style down to every _GlassSurface
    // without threading it through each widget's constructor.
    return _GlassStyleScope(style: controlsStyle, child: content);
  }
}

// ── Top bar ───────────────────────────────────────────────────────────────────
// Two rows — like the "=" sign:
//   Row 1 : [←]  [title …]
//   Row 2 : [🔒] [speed] [🔊] [🎵] [CC] [🔁]



