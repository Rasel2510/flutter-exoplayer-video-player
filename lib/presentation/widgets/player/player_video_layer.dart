import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:flutter_video_player/data/engines/media_kit_engine.dart';
import 'package:flutter_video_player/presentation/providers/player_provider.dart';
import 'overlays/error_state.dart';
import 'overlays/loading_poster.dart';

/// Renders the actual video surface: the error state, the loading poster
/// (before the first frame), or the live video — media_kit's own [Video]
/// widget for the software engine, or a rotation/fit-corrected [Texture] for
/// native ExoPlayer.
class PlayerVideoLayer extends ConsumerWidget {
  final String fallbackPath;
  final bool leaving;
  final VoidCallback onBack;

  const PlayerVideoLayer({
    super.key,
    required this.fallbackPath,
    required this.leaving,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final (
      :isInitialized,
      :fitMode,
      :zoomScale,
      :hasError,
      :errorMsg,
      :textureId,
      :videoWidth,
      :videoHeight,
      :videoRotation,
    ) = ref.watch(playerProvider.select((s) => (
          isInitialized: s.isInitialized,
          fitMode: s.fitMode,
          zoomScale: s.zoomScale,
          hasError: s.hasError,
          errorMsg: s.errorMessage,
          textureId: s.textureId,
          videoWidth: s.videoWidth,
          videoHeight: s.videoHeight,
          videoRotation: s.videoRotation,
        )));

    if (hasError) {
      return ErrorState(
        message: errorMsg,
        onRetry: () {
          // FIX #OPT-1: .let() is a Kotlin idiom; Dart has no such built-in
          // extension. Use a plain block instead.
          final n = ref.read(playerProvider.notifier);
          final s = ref.read(playerProvider);
          n.init(
            s.currentVideo?.path ?? fallbackPath,
            folderVideos: s.folderVideos,
            initialIndex: s.currentIndex,
          );
        },
        onBack: onBack,
      );
    }

    if (!isInitialized || textureId == null) {
      // While popping, don't flash the spinner over the outgoing screen —
      // just let the black Scaffold show through.
      if (leaving) return const SizedBox.shrink();
      // Paint the already-cached thumbnail as a poster behind the spinner so
      // tapping a video shows its frame instantly, instead of a black gap,
      // while the decoder warms up.
      final path = ref.read(playerProvider).currentVideo?.path ?? fallbackPath;
      return Hero(
        tag: 'video_thumb_$path',
        child: LoadingPoster(videoPath: path),
      );
    }

    // Render each engine with its proper widget: the software (media_kit)
    // engine MUST use media_kit's own Video widget — its Android texture
    // isn't displayable via a raw Texture. Positioned.fill gives it tight
    // full-screen constraints, so its internal fit logic has a real box to
    // fit into (a Center here would let it self-size and turn every fit
    // mode into a no-op — see the ExoPlayer branch below).
    final engine = ref.read(playerProvider.notifier).engine;
    if (engine is MediaKitEngine) {
      Widget video = Video(
        controller: engine.controller,
        controls: NoVideoControls,
        fit: switch (fitMode) {
          FitMode.contain => BoxFit.contain,
          FitMode.cover => BoxFit.cover,
          FitMode.fill => BoxFit.fill,
          FitMode.natural => BoxFit.scaleDown,
        },
        // The app renders subtitles itself (styled SubtitleOverlay fed by
        // cuesStream). Hide media_kit's own SubtitleView or every cue shows
        // twice.
        subtitleViewConfiguration:
            const SubtitleViewConfiguration(visible: false),
      );
      if (zoomScale != 1.0) {
        video = Transform.scale(scale: zoomScale, child: video);
      }
      return Positioned.fill(child: video);
    }

    // ── Native ExoPlayer: rotation + fit computed explicitly ──────────────
    //
    // Why not Center(FittedBox(fit, Texture))? Under the loose constraints a
    // Center provides, a FittedBox sizes ITSELF to its child's aspect ratio —
    // so the box it fits the video into always has the video's own shape and
    // contain/cover/fill all render identically (the "Fit/Crop/Fill button
    // does nothing" bug). The fit only means something against the SCREEN's
    // box, so compute the target size ourselves from tight constraints.
    //
    // Rotation: videoWidth/videoHeight arrive already rotation-corrected
    // (720x1280 for a portrait phone recording) but the texture CONTENT is
    // still the sideways pre-rotation frame — Flutter ignores the
    // SurfaceTexture transform matrix MediaCodec uses to convey rotation. So
    // the Texture is laid out at the pre-rotation (swapped) size and a
    // RotatedBox turns it upright, restoring the corrected on-screen box.
    final displayW = videoWidth > 0 ? videoWidth.toDouble() : 16.0;
    final displayH = videoHeight > 0 ? videoHeight.toDouble() : 9.0;
    final quarterTurns = (videoRotation ~/ 90) % 4;
    final rotated = quarterTurns.isOdd;

    return Positioned.fill(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final boxW = constraints.maxWidth;
          final boxH = constraints.maxHeight;
          final videoAspect = displayW / displayH;
          final boxAspect = boxW / boxH;

          double targetW;
          double targetH;
          switch (fitMode) {
            case FitMode.fill:
              targetW = boxW;
              targetH = boxH;
            case FitMode.cover:
              if (videoAspect > boxAspect) {
                targetH = boxH;
                targetW = boxH * videoAspect;
              } else {
                targetW = boxW;
                targetH = boxW / videoAspect;
              }
            case FitMode.natural:
              // Like contain, but never upscale past the video's real size.
              if (displayW <= boxW && displayH <= boxH) {
                targetW = displayW;
                targetH = displayH;
              } else if (videoAspect > boxAspect) {
                targetW = boxW;
                targetH = boxW / videoAspect;
              } else {
                targetH = boxH;
                targetW = boxH * videoAspect;
              }
            case FitMode.contain:
              if (videoAspect > boxAspect) {
                targetW = boxW;
                targetH = boxW / videoAspect;
              } else {
                targetH = boxH;
                targetW = boxH * videoAspect;
              }
          }

          // Lay the Texture out at the pre-rotation size; RotatedBox swaps
          // it back so the final on-screen box is exactly targetW x targetH.
          final preRotW = rotated ? targetH : targetW;
          final preRotH = rotated ? targetW : targetH;
          Widget texture = SizedBox(
            width: preRotW,
            height: preRotH,
            child: Texture(textureId: textureId),
          );
          if (quarterTurns != 0) {
            texture = RotatedBox(quarterTurns: quarterTurns, child: texture);
          }

          Widget sized =
              SizedBox(width: targetW, height: targetH, child: texture);
          if (zoomScale != 1.0) {
            sized = Transform.scale(scale: zoomScale, child: sized);
          }
          // Cover (and a zoomed-in video) can exceed the screen box — clip.
          return ClipRect(child: Center(child: sized));
        },
      ),
    );
  }
}
