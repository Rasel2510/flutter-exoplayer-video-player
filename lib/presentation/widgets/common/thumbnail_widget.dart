import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../services/thumbnail_service.dart';
import '../../../core/utils/duration_formatter.dart';

// ── Shared shimmer ────────────────────────────────────────────────────────────
//
// FIX #OPT-8: Previously every loading thumbnail ran its own AnimationController.
// For a folder with 50 uncached videos that meant 50 simultaneous controllers
// all ticking on the UI thread.
//
// The fix uses an InheritedWidget + a single top-level controller that all
// _Shimmer instances listen to.  The controller lives in a StatefulWidget
// (_ShimmerScope) placed once in the widget tree (inside app.dart or any
// common ancestor); all loading thumbnails share the same animation value.

/// Place this once above any screen that shows [VideoThumbnailWidget].
/// It vends a single [Animation<double>] to all shimmer consumers below it.
part 'widgets/shimmer_scope.dart';

class VideoThumbnailWidget extends StatefulWidget {
  final String videoPath;
  final double width;
  final double height;
  final Duration? duration;

  const VideoThumbnailWidget({
    super.key,
    required this.videoPath,
    this.width = 88,
    this.height = 58,
    this.duration,
  });

  @override
  State<VideoThumbnailWidget> createState() => _VideoThumbnailWidgetState();
}

class _VideoThumbnailWidgetState extends State<VideoThumbnailWidget> {
  File? _thumb;
  bool _failed = false;
  StreamSubscription<String>? _updateSub;
  int? _cacheWidth;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _cacheWidth = (widget.width * MediaQuery.devicePixelRatioOf(context)).round();
  }

  @override
  void initState() {
    super.initState();
    _load();
    // A thumbnail can arrive AFTER this widget gave up — e.g. harvested from
    // the playing fallback engine while this list sits beneath the player
    // route. Reload in place when that happens.
    _updateSub = ThumbnailService.instance.updates.listen((path) {
      if (path == widget.videoPath && _thumb == null) _load();
    });
  }

  @override
  void dispose() {
    _updateSub?.cancel();
    super.dispose();
  }

  @override
  void didUpdateWidget(VideoThumbnailWidget old) {
    super.didUpdateWidget(old);
    if (old.width != widget.width) {
      _cacheWidth = (widget.width * MediaQuery.devicePixelRatioOf(context)).round();
    }
    if (old.videoPath != widget.videoPath) {
      setState(() {
        _thumb = null;
        _failed = false;
      });
      _load();
    }
  }

  Future<void> _load() async {
    final file =
        await ThumbnailService.instance.getThumbnail(widget.videoPath);
    if (!mounted) return;
    setState(() {
      _thumb = file;
      _failed = file == null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.width,
      height: widget.height,
      // The shimmer animates every frame while loading; a RepaintBoundary keeps
      // that per-frame repaint confined to the small thumbnail rect instead of
      // bubbling up and redrawing the whole card (title, badges, progress bar).
      child: RepaintBoundary(child: _buildInner(context)),
    );
  }

  Widget _buildInner(BuildContext context) {
    if (_thumb != null) {
      return Stack(
        fit: StackFit.expand,
        children: [
          Image.file(
            _thumb!,
            fit: BoxFit.cover,
            // Posters harvested from the playing engine are stored at full
            // video resolution — decode at tile size (ResizeImage never
            // upscales) so a 4K frame doesn't cost a ~30 MB bitmap per row.
            cacheWidth: _cacheWidth,
            errorBuilder: (_, __, ___) => _placeholder(context),
          ),
          const Center(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Color(0x80000000),
                shape: BoxShape.circle,
              ),
              child: SizedBox(
                width: 28,
                height: 28,
                child: Icon(Icons.play_arrow_rounded,
                    color: Colors.white, size: 16),
              ),
            ),
          ),
          if (widget.duration != null && widget.duration!.inSeconds > 0)
            Positioned(
              bottom: 4,
              right: 4,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                decoration: const BoxDecoration(
                  color: Color(0xB3000000),
                  borderRadius: BorderRadius.all(Radius.circular(4)),
                ),
                child: Text(
                  DurationFormatter.format(widget.duration!),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
            ),
        ],
      );
    }
    if (_failed) return _placeholder(context);
    // Show shimmer using the shared animation from ShimmerScope.
    return _Shimmer(animation: ShimmerScope.of(context));
  }

  Widget _placeholder(BuildContext context) => Container(
        color: context.colors.elevated,
        child:
            Icon(Icons.movie_outlined, color: context.colors.textMuted, size: 22),
      );
}

// ── Shimmer ───────────────────────────────────────────────────────────────────

/// A simple opacity-shimmer that reads its animation from [ShimmerScope].
/// Stateless because it no longer owns an AnimationController.
class _Shimmer extends AnimatedWidget {
  const _Shimmer({required Animation<double> animation})
      : super(listenable: animation);

  @override
  Widget build(BuildContext context) {
    final value = (listenable as Animation<double>).value.clamp(0.0, 1.0);
    // Paint a translucent white rect directly rather than wrapping a white box
    // in Opacity: Opacity triggers a saveLayer (offscreen buffer) every frame,
    // which is costly on low-end GPUs. The per-frame Color is a trivial CPU
    // allocation by comparison, and there's no layer to composite.
    return ColoredBox(color: Color.fromRGBO(255, 255, 255, value));
  }
}

