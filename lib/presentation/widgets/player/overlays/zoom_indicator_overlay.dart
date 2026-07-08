import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_video_player/presentation/providers/player_provider.dart';

class ZoomIndicatorOverlay extends ConsumerStatefulWidget {
  const ZoomIndicatorOverlay({super.key});

  @override
  ConsumerState<ZoomIndicatorOverlay> createState() => _ZoomIndicatorOverlayState();
}

class _ZoomIndicatorOverlayState extends ConsumerState<ZoomIndicatorOverlay> {
  Timer? _timer;
  bool _visible = false;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _showIndicator() {
    _timer?.cancel();
    if (!mounted) return;
    setState(() {
      _visible = true;
    });
    _timer = Timer(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _visible = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final zoom = ref.watch(playerProvider.select((s) => s.zoomScale));

    ref.listen<double>(
      playerProvider.select((s) => s.zoomScale),
      (previous, next) {
        if ((next - 1.0).abs() < 0.05) {
          _timer?.cancel();
          if (_visible) {
            setState(() {
              _visible = false;
            });
          }
        } else if (previous != next) {
          _showIndicator();
        }
      },
    );

    final show = _visible && (zoom - 1.0).abs() >= 0.05;

    return Positioned(
      top: 60,
      left: 0,
      right: 0,
      child: Center(
        child: AnimatedOpacity(
          opacity: show ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 200),
          child: IgnorePointer(
            ignoring: !show,
            child: GestureDetector(
              onTap: () {
                ref.read(playerProvider.notifier).resetZoom();
                _timer?.cancel();
                setState(() {
                  _visible = false;
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                  color: const Color(0xA6000000),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: const Color(0x33FFFFFF),
                      width: 1),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.zoom_in_rounded,
                        color: Colors.white70, size: 16),
                    const SizedBox(width: 6),
                    Text(
                      '${zoom.toStringAsFixed(1)}×',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.close_rounded,
                        color: Colors.white54, size: 14),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
