import 'package:flutter/material.dart';
import 'package:flutter_video_player/presentation/widgets/common/glass_surface.dart';
import 'mini_controls_row.dart';
import 'mini_progress_bar.dart';
import 'yt_mini_button.dart';

/// The mini-player's visual content: video texture, auto-hide controls
/// overlay (close / expand / playback row), and progress bar. Dragging,
/// resizing, and corner-snapping are owned by MiniPlayerOverlay itself — this
/// widget only renders what goes inside the floating window.
class MiniPlayerSurface extends StatelessWidget {
  final int? textureId;
  final int videoWidth;
  final int videoHeight;
  final int videoRotation;
  final bool controlsVisible;
  final bool frosted;
  final double iconScale;
  final int seekInterval;
  final IconData replayIcon;
  final IconData forwardIcon;
  final VoidCallback onClose;
  final VoidCallback onExpand;
  final VoidCallback onShowControls;

  const MiniPlayerSurface({
    super.key,
    required this.textureId,
    required this.videoWidth,
    required this.videoHeight,
    required this.videoRotation,
    required this.controlsVisible,
    required this.frosted,
    required this.iconScale,
    required this.seekInterval,
    required this.replayIcon,
    required this.forwardIcon,
    required this.onClose,
    required this.onExpand,
    required this.onShowControls,
  });

  @override
  Widget build(BuildContext context) {
    final texId = textureId;
    return Material(
      color: Colors.black,
      borderRadius: BorderRadius.circular(12),
      elevation: 10,
      shadowColor: Colors.black87,
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // ── Live Video ──
          // The Texture is laid out at the pre-rotation (swapped) size and
          // uprighted with a RotatedBox — same correction as PlayerVideoLayer:
          // videoWidth/videoHeight are already rotation-corrected, but the
          // raw frame content Flutter samples is not. The FittedBox works
          // here (unlike the main player's old Center-wrapped one) because
          // StackFit.expand gives it tight window-sized constraints.
          if (texId != null)
            FittedBox(
              fit: BoxFit.contain,
              child: RotatedBox(
                quarterTurns: (videoRotation ~/ 90) % 4,
                child: SizedBox(
                  width: ((videoRotation ~/ 90).isOdd
                          ? videoHeight
                          : videoWidth)
                      .toDouble(),
                  height: ((videoRotation ~/ 90).isOdd
                          ? videoWidth
                          : videoHeight)
                      .toDouble(),
                  child: Texture(textureId: texId),
                ),
              ),
            )
          else
            const Center(
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: Colors.white54),
            ),

          // ── Controls overlay ──
          // Matches the main player's frosted/tint setting so the
          // mini-player's scrim doesn't look stuck in the old flat look when
          // the user turns Frosted controls on. Wrapped in its own
          // BackdropGroup — this is the only glass surface in this small
          // window, so there's nothing else to batch with.
          AnimatedOpacity(
            opacity: controlsVisible ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 200),
            child: IgnorePointer(
              ignoring: !controlsVisible,
              child: BackdropGroup(
                child: GlassSurface(
                  style: frosted ? GlassStyle.frosted : GlassStyle.tint,
                  borderRadius: BorderRadius.circular(12),
                  child: Stack(
                    children: [
                      // Close (×) — top left
                      Positioned(
                        top: -6,
                        left: -6,
                        child: YtMiniButton(
                          icon: Icons.close_rounded,
                          size: 18 * iconScale,
                          onTap: onClose,
                        ),
                      ),
                      // Expand — top right
                      Positioned(
                        top: -6,
                        right: -6,
                        child: YtMiniButton(
                          icon: Icons.fullscreen_rounded,
                          size: 24 * iconScale,
                          onTap: onExpand,
                        ),
                      ),
                      // Center: skip back / play-pause / skip forward
                      Center(
                        child: MiniControlsRow(
                          seekInterval: seekInterval,
                          replayIcon: replayIcon,
                          forwardIcon: forwardIcon,
                          iconScale: iconScale,
                          onShowControls: onShowControls,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // ── Progress bar — isolated Consumer, rebuilds every second ──
          if (!controlsVisible)
            const Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: MiniProgressBarConsumer(),
            ),
        ],
      ),
    );
  }
}
