import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_video_player/presentation/providers/player_provider.dart';
import 'package:flutter_video_player/screens/player_screen.dart';
import 'package:flutter_video_player/presentation/widgets/smooth_page_route.dart';
import 'package:flutter_video_player/app.dart';
import 'package:flutter_video_player/core/theme/app_theme.dart';

class MiniPlayerOverlay extends ConsumerStatefulWidget {
  final Widget child;
  const MiniPlayerOverlay({super.key, required this.child});

  @override
  ConsumerState<MiniPlayerOverlay> createState() => _MiniPlayerOverlayState();
}

class _MiniPlayerOverlayState extends ConsumerState<MiniPlayerOverlay>
    with SingleTickerProviderStateMixin {
  // Corner snap (0=topLeft, 1=topRight, 2=bottomLeft, 3=bottomRight).
  int _corner = 3;

  Offset _dragOffset = Offset.zero;
  bool _isDragging = false;

  double _scale = 1.0;
  double _baseScale = 1.0;

  // Controls visibility (YouTube-style auto-hide).
  bool _controlsVisible = false;
  Timer? _hideTimer;

  // Snap animation.
  late final AnimationController _snapController;
  Animation<Offset>? _snapAnimation;

  static const double _baseWidth = 200;
  static const double _baseHeight = 112;
  static const double _margin = 12;
  static const double _minScale = 0.85;
  static const double _maxScale = 2.0;

  @override
  void initState() {
    super.initState();
    _snapController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    _snapController.dispose();
    super.dispose();
  }

  void _showControls() {
    _hideTimer?.cancel();
    setState(() => _controlsVisible = true);
    _hideTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) setState(() => _controlsVisible = false);
    });
  }

  Offset _cornerPosition(int corner, Size screen, EdgeInsets padding, {double? overrideScale}) {
    final scaleToUse = overrideScale ?? _scale;
    final w = _baseWidth * scaleToUse;
    final h = _baseHeight * scaleToUse;
    switch (corner) {
      case 0:
        return Offset(_margin, padding.top + _margin);
      case 1:
        return Offset(screen.width - w - _margin, padding.top + _margin);
      case 2:
        return Offset(_margin, screen.height - h - max(padding.bottom, _margin) - _margin);
      case 3:
      default:
        return Offset(
          screen.width - w - _margin,
          screen.height - h - max(padding.bottom, _margin) - _margin,
        );
    }
  }

  void _snapToCorner(int corner, Size screen, EdgeInsets padding, Offset current, {double? overrideScale}) {
    final scaleToUse = overrideScale ?? _scale;
    final target = _cornerPosition(corner, screen, padding, overrideScale: scaleToUse);
    _snapAnimation = Tween<Offset>(begin: current, end: target).animate(
      CurvedAnimation(parent: _snapController, curve: Curves.easeOutCubic),
    );
    _snapController.forward(from: 0);
    _snapController.addListener(_onSnapTick);

    setState(() {
      _corner = corner;
      _isDragging = false;
      _dragOffset = Offset.zero;
    });
  }

  void _snapToNearestCorner(Size screen, EdgeInsets padding, Offset current, {double? overrideScale, Offset velocity = Offset.zero}) {
    final scaleToUse = overrideScale ?? _scale;
    final center = current + Offset(_baseWidth * scaleToUse / 2, _baseHeight * scaleToUse / 2);
    const double velocityThreshold = 400.0;

    int bestCorner;

    // If the user flung fast enough, pick corner based on the DOMINANT axis.
    // This prevents a tiny horizontal drift while pushing up from sending
    // the window to the wrong horizontal side.
    if (velocity.distance > velocityThreshold) {
      final absX = velocity.dx.abs();
      final absY = velocity.dy.abs();
      final isLeft  = _corner == 0 || _corner == 2;
      final isTop   = _corner == 0 || _corner == 1;

      if (absY > absX * 1.5) {
        // Mostly vertical — keep the same left/right side, only flip top/bottom.
        final goDown = velocity.dy >= 0;
        bestCorner = isLeft ? (goDown ? 2 : 0) : (goDown ? 3 : 1);
      } else if (absX > absY * 1.5) {
        // Mostly horizontal — keep the same top/bottom, only flip left/right.
        final goRight = velocity.dx >= 0;
        bestCorner = isTop ? (goRight ? 1 : 0) : (goRight ? 3 : 2);
      } else {
        // Truly diagonal — go to the full diagonal corner.
        final goRight = velocity.dx >= 0;
        final goDown  = velocity.dy >= 0;
        bestCorner = goRight ? (goDown ? 3 : 1) : (goDown ? 2 : 0);
      }
    } else {
      // Otherwise snap to the nearest corner by position.
      double bestDist = double.infinity;
      bestCorner = _corner;
      for (int i = 0; i < 4; i++) {
        final cp = _cornerPosition(i, screen, padding, overrideScale: scaleToUse);
        final cc = cp + Offset(_baseWidth * scaleToUse / 2, _baseHeight * scaleToUse / 2);
        final dist = (cc - center).distance;
        if (dist < bestDist) {
          bestDist = dist;
          bestCorner = i;
        }
      }
    }

    _snapToCorner(bestCorner, screen, padding, current, overrideScale: scaleToUse);
  }

  void _onSnapTick() {
    if (_snapAnimation != null) setState(() {});
    if (!_snapController.isAnimating) {
      _snapController.removeListener(_onSnapTick);
    }
  }

  @override
  Widget build(BuildContext context) {
    final playerState = ref.watch(playerProvider);
    final isActive = playerState.isMiniPlayerActive;
    final video = playerState.currentVideo;

    if (!isActive || video == null) {
      _hideTimer?.cancel();
      _controlsVisible = false;
      return widget.child;
    }

    final screenSize = MediaQuery.of(context).size;
    final padding = MediaQuery.of(context).padding;

    final double maxW = screenSize.width - (_margin * 2);
    final double maxH = screenSize.height - padding.top - max(padding.bottom, _margin) - (_margin * 2);
    final double dynamicMaxScale = min(_maxScale, max(_minScale, min(maxW / _baseWidth, maxH / _baseHeight)));
    
    final double effectiveScale = min(_scale, dynamicMaxScale);
    final double iconScale = min(1.3, effectiveScale); // prevent icons from becoming comically large
    final double currentWidth = _baseWidth * effectiveScale;
    final double currentHeight = _baseHeight * effectiveScale;

    const double minX = _margin;
    final double maxX = max(minX, screenSize.width - currentWidth - _margin);
    final double minY = padding.top + _margin;
    final double maxY = max(minY, screenSize.height - currentHeight - max(padding.bottom, _margin) - _margin);

    Offset pos;
    if (_isDragging) {
      pos = _cornerPosition(_corner, screenSize, padding, overrideScale: effectiveScale) + _dragOffset;
      pos = Offset(
        pos.dx.clamp(minX, maxX),
        pos.dy.clamp(minY, maxY),
      );
    } else if (_snapController.isAnimating && _snapAnimation != null) {
      pos = _snapAnimation!.value;
    } else {
      pos = _cornerPosition(_corner, screenSize, padding, overrideScale: effectiveScale);
    }

    final textureId = playerState.textureId;
    final videoWidth = playerState.videoWidth > 0 ? playerState.videoWidth : 16;
    final videoHeight = playerState.videoHeight > 0 ? playerState.videoHeight : 9;
    final seekInterval = playerState.seekInterval;
    
    final IconData replayIcon = seekInterval <= 5
        ? Icons.replay_5_rounded
        : seekInterval <= 10
            ? Icons.replay_10_rounded
            : Icons.replay_30_rounded;

    final IconData forwardIcon = seekInterval <= 5
        ? Icons.forward_5_rounded
        : seekInterval <= 10
            ? Icons.forward_10_rounded
            : Icons.forward_30_rounded;
    
    final bool isEnded = playerState.progress >= 0.99 && !playerState.isPlaying;
    final bool intendsToPlay = playerState.intendsToPlay;

    return Stack(
      children: [
        widget.child,
        Positioned(
          left: pos.dx,
          top: pos.dy,
          width: currentWidth,
          height: currentHeight,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onScaleStart: (details) {
              if (_snapController.isAnimating && _snapAnimation != null) {
                final currentVisualPos = _snapAnimation!.value;
                final basePos = _cornerPosition(_corner, screenSize, padding, overrideScale: effectiveScale);
                _dragOffset = currentVisualPos - basePos;
              }
              _snapController.stop();
              _baseScale = effectiveScale;
              _isDragging = true;
            },
            onScaleUpdate: (details) {
              setState(() {
                if (details.pointerCount >= 2) {
                  _scale = (_baseScale * details.scale).clamp(_minScale, dynamicMaxScale);
                }
                _dragOffset += details.focalPointDelta;

                final double effScaleUpdate = min(_scale, dynamicMaxScale);
                final basePos = _cornerPosition(_corner, screenSize, padding, overrideScale: effScaleUpdate);
                final newWidth = _baseWidth * effScaleUpdate;
                final newHeight = _baseHeight * effScaleUpdate;
                
                const double currentMinX = _margin;
                final double currentMaxX = max(currentMinX, screenSize.width - newWidth - _margin);
                final double currentMinY = padding.top + _margin;
                final double currentMaxY = max(currentMinY, screenSize.height - newHeight - max(padding.bottom, _margin) - _margin);
                
                final rawPos = basePos + _dragOffset;
                final clampedPos = Offset(
                  rawPos.dx.clamp(currentMinX, currentMaxX),
                  rawPos.dy.clamp(currentMinY, currentMaxY),
                );
                _dragOffset = clampedPos - basePos;
              });
            },
            onScaleEnd: (details) {
              final current = _cornerPosition(_corner, screenSize, padding, overrideScale: effectiveScale) + _dragOffset;
              final clamped = Offset(
                current.dx.clamp(minX, maxX),
                current.dy.clamp(minY, maxY),
              );
              _snapToNearestCorner(
                screenSize, padding, clamped,
                overrideScale: effectiveScale,
                velocity: details.velocity.pixelsPerSecond,
              );
            },
            onTap: () {
              if (_controlsVisible) {
                setState(() => _controlsVisible = false);
                _hideTimer?.cancel();
              } else {
                _showControls();
              }
            },
            child: Material(
              color: Colors.black,
              borderRadius: BorderRadius.circular(12),
              elevation: 10,
              shadowColor: Colors.black87,
              clipBehavior: Clip.antiAlias,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // ── Live Video ──
                  if (textureId != null)
                    FittedBox(
                      fit: BoxFit.contain,
                      child: SizedBox(
                        width: videoWidth.toDouble(),
                        height: videoHeight.toDouble(),
                        child: Texture(textureId: textureId),
                      ),
                    )
                  else
                    const Center(
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white54),
                    ),

                  // ── Controls (YouTube-style: show on tap, auto-hide) ──
                  AnimatedOpacity(
                    opacity: _controlsVisible ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 200),
                    child: IgnorePointer(
                      ignoring: !_controlsVisible,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.55),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Stack(
                          children: [
                            // Close (×) — top left
                            Positioned(
                              top: -6,
                              left: -6,
                              child: _YTMiniButton(
                                icon: Icons.close_rounded,
                                size: 18 * iconScale,
                                onTap: () => ref.read(playerProvider.notifier).dispose(),
                              ),
                            ),
                            // Expand — top right
                            Positioned(
                              top: -6,
                              right: -6,
                              child: _YTMiniButton(
                                icon: Icons.fullscreen_rounded,
                                size: 24 * iconScale, // slightly larger since fullscreen icon strokes are thinner
                                onTap: () {
                                  _hideTimer?.cancel();
                                  appNavigatorKey.currentState?.push(
                                    SmoothPageRoute(
                                      child: PlayerScreen(
                                        filePath: video.path,
                                        fileName: video.name,
                                        folderVideos: playerState.folderVideos,
                                        initialIndex: playerState.currentIndex,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                            // Center row: skip back / play-pause / skip forward
                            Center(
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  _YTMiniButton(
                                    icon: isEnded ? Icons.skip_previous_rounded : replayIcon,
                                    size: 20 * iconScale,
                                    onTap: () {
                                      if (isEnded) {
                                        ref.read(playerProvider.notifier).playPrevious();
                                      } else {
                                        ref.read(playerProvider.notifier).seekRelative(-seekInterval);
                                      }
                                      _showControls();
                                    },
                                  ),
                                  const SizedBox(width: 12),
                                  _YTMiniButton(
                                    icon: isEnded 
                                        ? Icons.replay_rounded 
                                        : (intendsToPlay ? Icons.pause_rounded : Icons.play_arrow_rounded),
                                    size: 28 * iconScale,
                                    onTap: () {
                                      final engine = ref.read(playerProvider.notifier).engine;
                                      if (isEnded) {
                                        engine?.seek(Duration.zero);
                                        engine?.play();
                                      } else {
                                        if (playerState.isPlaying) {
                                          engine?.pause();
                                        } else {
                                          engine?.play();
                                        }
                                      }
                                      _showControls();
                                    },
                                  ),
                                  const SizedBox(width: 12),
                                  _YTMiniButton(
                                    icon: isEnded ? Icons.skip_next_rounded : forwardIcon,
                                    size: 20 * iconScale,
                                    onTap: () {
                                      if (isEnded) {
                                        ref.read(playerProvider.notifier).playNext();
                                      } else {
                                        ref.read(playerProvider.notifier).seekRelative(seekInterval);
                                      }
                                      _showControls();
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // ── Thin progress bar at bottom (always visible like YouTube) ──
                  if (!_controlsVisible)
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: _MiniProgressBar(
                        progress: playerState.progress,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// YouTube-style transparent icon button for the mini player.
class _YTMiniButton extends StatelessWidget {
  final IconData icon;
  final double size;
  final VoidCallback onTap;

  const _YTMiniButton({
    required this.icon,
    required this.size,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Icon(icon, size: size, color: Colors.white),
      ),
    );
  }
}

/// A thin red progress bar at the very bottom of the mini player (like YouTube).
class _MiniProgressBar extends StatelessWidget {
  final double progress;
  const _MiniProgressBar({required this.progress});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 3,
      child: LinearProgressIndicator(
        value: progress.clamp(0.0, 1.0),
        backgroundColor: Colors.white24,
        valueColor: AlwaysStoppedAnimation<Color>(context.colors.accent),
        minHeight: 3,
      ),
    );
  }
}
