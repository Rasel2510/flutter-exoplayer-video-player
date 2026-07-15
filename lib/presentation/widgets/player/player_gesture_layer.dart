import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_video_player/presentation/providers/player_provider.dart';
import 'overlays/seek_flash.dart';

class PlayerGestureLayer extends ConsumerStatefulWidget {
  final Widget child;

  const PlayerGestureLayer({
    super.key,
    required this.child,
  });

  @override
  ConsumerState<PlayerGestureLayer> createState() => _PlayerGestureLayerState();
}

class _PlayerGestureLayerState extends ConsumerState<PlayerGestureLayer>
    with TickerProviderStateMixin {
  // ── Seek flash ─────────────────────────────────────────────────────────────
  late final AnimationController _seekFlashCtrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 750),
  );
  bool _seekFlashLeft = false;
  bool _seekFlashRight = false;

  // ── Scale / pinch-to-zoom ──────────────────────────────────────────────────
  double _baseZoomScale = 1.0;
  double _dragStartDx = 0;
  bool _swipeActive = false;
  bool _isPinching = false;
  bool _postPinchCooldown = false;
  
  double _dragStartDy = 0;
  bool _swipeCommitted = false;
  bool _isSeekSwipe = false;
  double _seekStartProgress = 0;

  // ── Hold-to-fast-forward (press and hold → 2×) ─────────────────────────────
  bool _holdFFActive = false;

  void _cancelHoldFF() {
    if (_holdFFActive) {
      _holdFFActive = false;
      ref.read(playerProvider.notifier).endHoldFastForward();
    }
  }

  @override
  void dispose() {
    _seekFlashCtrl.dispose();
    super.dispose();
  }

  void _triggerSeekFlash(bool isLeft) {
    setState(() {
      _seekFlashLeft = isLeft;
      _seekFlashRight = !isLeft;
    });
    _seekFlashCtrl.forward(from: 0).then((_) {
      if (mounted) {
        setState(() {
          _seekFlashLeft = false;
          _seekFlashRight = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final (:isLocked, :controlsVisible, :holdFastForward, :seekInterval) =
        ref.watch(playerProvider.select((s) => (
              isLocked: s.isLocked,
              controlsVisible: s.controlsVisible,
              holdFastForward: s.holdFastForward,
              seekInterval: s.seekInterval,
            )));

    return Stack(
      children: [
        // Gesture layer. `opaque` so taps register everywhere in this layer's
        // bounds — including the black letterbox/pillarbox bars around a
        // video that doesn't fill the screen (e.g. a portrait video in
        // landscape) — instead of the default `deferToChild`, which only
        // counts a tap as "hit" where an actual painted descendant sits under
        // it. Without this, tapping the black bars silently did nothing.
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            if (!_swipeActive && !_isPinching) {
              controlsVisible
                  ? ref.read(playerProvider.notifier).hideControls()
                  : ref.read(playerProvider.notifier).showControls();
            }
          },
          onDoubleTapDown: (details) {
            if (isLocked) return;
            final isLeft = details.globalPosition.dx < size.width / 2;
            if (isLeft) {
              ref
                  .read(playerProvider.notifier)
                  .seekRelative(-seekInterval, revealControls: false);
            } else {
              ref
                  .read(playerProvider.notifier)
                  .seekRelative(seekInterval, revealControls: false);
            }
            _triggerSeekFlash(isLeft);
          },
          onScaleStart: (details) {
            if (isLocked) return;
            if (details.pointerCount >= 2) {
              _isPinching = true;
              _swipeActive = false;
              _postPinchCooldown = false;
              _baseZoomScale = ref.read(playerProvider).zoomScale;
              _cancelHoldFF(); // a second finger → it's a pinch, not a hold
            } else {
              if (_postPinchCooldown) return;
              _isPinching = false;
              _dragStartDx = details.localFocalPoint.dx;
              _dragStartDy = details.localFocalPoint.dy;
              _swipeActive = true;
              _swipeCommitted = false;
              _isSeekSwipe = false;
            }
          },
          onScaleUpdate: (details) {
            if (isLocked) return;
            if (_isPinching || details.pointerCount >= 2) {
              _isPinching = true;
              _swipeActive = false;
              if (details.pointerCount >= 2) {
                ref.read(playerProvider.notifier).setZoomScale(_baseZoomScale * details.scale);
              }
            } else if (_swipeActive && !_postPinchCooldown) {
              // While fast-forwarding, ignore movement until the finger lifts.
              if (_holdFFActive) return;
              if (!_swipeCommitted) {
                final dx = details.localFocalPoint.dx - _dragStartDx;
                final dy = details.localFocalPoint.dy - _dragStartDy;
                if (dx.abs() > 15 || dy.abs() > 15) {
                  _swipeCommitted = true;
                  if (dx.abs() > dy.abs()) {
                    _isSeekSwipe = true;
                    _seekStartProgress = ref.read(playerProvider).progress;
                    ref.read(playerProvider.notifier).beginSeek(_seekStartProgress);
                    ref.read(playerProvider.notifier).showControls();
                  } else {
                    _isSeekSwipe = false;
                    ref.read(playerProvider.notifier).startSwipe(_dragStartDx, size.width);
                  }
                } else {
                  return;
                }
              }
              if (_isSeekSwipe) {
                final durationMs = ref.read(playerProvider).duration.inMilliseconds;
                if (durationMs > 0) {
                  final deltaMs = (details.localFocalPoint.dx - _dragStartDx) * 300;
                  final seekStartMs = _seekStartProgress * durationMs;
                  final newMs = (seekStartMs + deltaMs).clamp(0.0, durationMs.toDouble());
                  ref.read(playerProvider.notifier).updateSeek(newMs / durationMs);
                }
              } else {
                ref.read(playerProvider.notifier).updateSwipe(details.focalPointDelta.dy, size.height);
              }
            }
          },
          onScaleEnd: (_) {
            if (isLocked) return;
            // Release the hold-to-fast-forward (restores prior speed).
            _cancelHoldFF();
            if (_isPinching) {
              _isPinching = false;
              _postPinchCooldown = true;
              Future.delayed(
                const Duration(milliseconds: 150),
                () {
                  if (mounted) _postPinchCooldown = false;
                },
              );
            } else if (_swipeActive) {
              _swipeActive = false;
              if (_swipeCommitted) {
                if (_isSeekSwipe) {
                  ref.read(playerProvider.notifier).endSeek(ref.read(playerProvider).seekValue);
                } else {
                  ref.read(playerProvider.notifier).endSwipe();
                }
              }
            }
          },
          onLongPressStart: (details) {
            if (isLocked) return;
            HapticFeedback.mediumImpact();
            _holdFFActive = true;
            ref.read(playerProvider.notifier).startHoldFastForward();
          },
          onLongPressEnd: (details) {
            _cancelHoldFF();
          },
          onLongPressUp: () {
            _cancelHoldFF();
          },
          child: widget.child,
        ),

        // Seek flash overlays
        if (_seekFlashLeft)
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            width: size.width / 2,
            child: SeekFlash(
              animation: _seekFlashCtrl,
              isForward: false,
              seekInterval: seekInterval,
            ),
          ),
        if (_seekFlashRight)
          Positioned(
            right: 0,
            top: 0,
            bottom: 0,
            width: size.width / 2,
            child: SeekFlash(
              animation: _seekFlashCtrl,
              isForward: true,
              seekInterval: seekInterval,
            ),
          ),

        // Hold-to-fast-forward badge.
        if (holdFastForward)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 7),
                    decoration: BoxDecoration(
                      color: const Color(0xB8000000),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0x1AFFFFFF)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.fast_forward_rounded,
                            color: Colors.white, size: 16),
                        SizedBox(width: 6),
                        Text(
                          '2×',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
