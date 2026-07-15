import 'package:flutter/material.dart';
import 'package:flutter_video_player/presentation/providers/subtitle_style_provider.dart';

/// Forces Flutter/Skia to resolve and shape every subtitle font preset once,
/// during the app's very first frame, instead of paying that one-time cost
/// when the user opens the subtitle sheet — where it showed up as a visible
/// stutter/delay right as the sheet's slide-up animation played. Each of the
/// app's non-default subtitle fonts (serif, monospace, cursive, etc.) is an
/// Android system font family that needs its own Typeface lookup + glyph
/// shaping the first time anything is laid out in it; doing that lookup for
/// seven distinct families all at once, in the same frame as a sheet
/// animation, is exactly what read as a hitch.
///
/// [Offstage] still lays out its child (only painting/hit-testing are
/// skipped), so this pays the cost up front without ever being visible.
/// Mounted once at the app root (see app.dart) so it stays alive — and the
/// shaped-font cache stays warm — for the whole app lifetime.
class SubtitleFontWarmup extends StatefulWidget {
  const SubtitleFontWarmup({super.key});

  @override
  State<SubtitleFontWarmup> createState() => _SubtitleFontWarmupState();
}

class _SubtitleFontWarmupState extends State<SubtitleFontWarmup> {
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    // Delay font shaping until after the first frame so we don't block
    // the app launch.
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() => _ready = true);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) return const SizedBox.shrink();
    
    return Offstage(
      child: Column(
        children: [
          for (final preset in subtitleFontPresets)
            if (preset.family != null)
              Text(
                'Ag',
                style: TextStyle(
                  fontFamily: preset.family,
                  fontWeight: FontWeight.w600,
                ),
              ),
        ],
      ),
    );
  }
}
