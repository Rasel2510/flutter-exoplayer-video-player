import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_video_player/data/services/thumbnail_service.dart';

/// Shown while the native player warms up (before the first frame). Paints the
/// video's already-cached thumbnail as a full-screen poster behind a spinner so
/// the transition into playback feels instant instead of black.
///
/// [ThumbnailService.getThumbnail] returns from its in-memory `_resolved` map
/// when the library already generated the thumbnail (the common case), so the
/// poster appears on the next microtask with no disk hit.
class LoadingPoster extends StatelessWidget {
  final String videoPath;
  const LoadingPoster({super.key, required this.videoPath});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        FutureBuilder<File?>(
          future: ThumbnailService.instance.getThumbnail(videoPath),
          builder: (context, snap) {
            final file = snap.data;
            if (file == null) return const SizedBox.shrink();
            // contain → same letterboxing the video will use, so there's no
            // jump when the real frame replaces the poster.
            return Image.file(
              file,
              fit: BoxFit.contain,
              gaplessPlayback: true,
              filterQuality: FilterQuality.low,
              // Harvested posters can be full video resolution — cap the
              // decode at screen width so opening a 4K HEVC doesn't spike a
              // huge bitmap decode right as the decoder is warming up.
              cacheWidth: (MediaQuery.sizeOf(context).width *
                      MediaQuery.devicePixelRatioOf(context))
                  .round(),
            );
          },
        ),
        const Center(child: CircularProgressIndicator()),
      ],
    );
  }
}
