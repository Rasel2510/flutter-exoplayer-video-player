import 'package:flutter/material.dart';

/// YouTube/Netflix-style double-tap seek overlay.
///
/// Animation layers (all driven by one 750 ms controller, 0 → 1):
///   1. Half-screen gradient tint  — flashes in, holds, fades out.
///   2. Three expanding ripple rings — pulse outward from the tapped edge.
///   3. Three staggered chevrons    — sweep outward (‹‹‹ / ›››).
///   4. Seek icon                   — scales in with spring, then fades.
///   5. "+Ns / −Ns" label           — slides up and fades out.
class SeekFlash extends StatefulWidget {
  final Animation<double> animation;
  final bool isForward;
  final int seekInterval;

  const SeekFlash({
    super.key,
    required this.animation,
    required this.isForward,
    required this.seekInterval,
  });

  @override
  State<SeekFlash> createState() => _SeekFlashState();
}

class _SeekFlashState extends State<SeekFlash> {
  // ── Sub-animations (created once in initState, disposed here) ─────────────
  //
  // All are driven by widget.animation (the shared AnimationController).
  // Creating them here — not inside build() — means Flutter only allocates
  // the CurvedAnimation / TweenSequence objects once per widget lifetime
  // instead of on every animation frame, which was the main perf issue with
  // the previous StatelessWidget approach that called _buildAnims() inside
  // AnimatedBuilder.builder.

  late final Animation<double> _bgOpacity;
  late final Animation<double> _ripple1;
  late final Animation<double> _ripple2;
  late final Animation<double> _ripple3;
  late final Animation<double> _rippleOpacity;
  late final Animation<double> _iconScale;
  late final Animation<double> _iconOpacity;
  late final Animation<double> _chevron1;
  late final Animation<double> _chevron2;
  late final Animation<double> _chevron3;
  late final Animation<double> _labelSlide;
  late final Animation<double> _labelOpacity;

  // CurvedAnimations must be disposed to avoid listener leaks.
  final List<CurvedAnimation> _curvedAnims = [];

  CurvedAnimation _curved(double begin, double end, Curve curve) {
    final ca = CurvedAnimation(
      parent: widget.animation,
      curve: Interval(begin, end, curve: curve),
    );
    _curvedAnims.add(ca);
    return ca;
  }

  @override
  void initState() {
    super.initState();
    final anim = widget.animation;

    // Background tint: sharp in (0–15 %) then hold, then slow fade.
    _bgOpacity = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 15),
      TweenSequenceItem(tween: ConstantTween(1.0),           weight: 35),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 50),
    ]).animate(anim);

    // Three ripple rings staggered 12 % apart.
    _ripple1 = _curved(0.00, 0.75, Curves.easeOut);
    _ripple2 = _curved(0.12, 0.87, Curves.easeOut);
    _ripple3 = _curved(0.24, 0.99, Curves.easeOut);
    _rippleOpacity = TweenSequence<double>([
      TweenSequenceItem(tween: ConstantTween(0.5),           weight: 20),
      TweenSequenceItem(tween: Tween(begin: 0.5, end: 0.0), weight: 80),
    ]).animate(anim);

    // Icon: spring-scale in, hold, shrink-fade out.
    _iconScale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 0.4, end: 1.15)
            .chain(CurveTween(curve: Curves.easeOutBack)),
        weight: 25,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.15, end: 1.0)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 10,
      ),
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 30),
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 0.6)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 35,
      ),
    ]).animate(anim);
    _iconOpacity = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 20),
      TweenSequenceItem(tween: ConstantTween(1.0),           weight: 45),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 35),
    ]).animate(anim);

    // Three chevrons sweep outward, staggered 10 % apart.
    _chevron1 = _curved(0.05, 0.45, Curves.easeOut);
    _chevron2 = _curved(0.15, 0.55, Curves.easeOut);
    _chevron3 = _curved(0.25, 0.65, Curves.easeOut);

    // Label slides up slightly and fades.
    _labelSlide = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 8.0, end: 0.0)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 25,
      ),
      TweenSequenceItem(tween: ConstantTween(0.0), weight: 40),
      TweenSequenceItem(
        tween: Tween(begin: 0.0, end: -6.0)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 35,
      ),
    ]).animate(anim);
    _labelOpacity = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 20),
      TweenSequenceItem(tween: ConstantTween(1.0),           weight: 45),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 35),
    ]).animate(anim);
  }

  @override
  void dispose() {
    for (final ca in _curvedAnims) {
      ca.dispose();
    }
    super.dispose();
  }

  // ── Icon widget ────────────────────────────────────────────────────────────

  /// Returns the appropriate seek icon for [seekInterval].
  ///
  /// For 15 s we use the same custom Flutter widget as [_SeekPill] because
  /// [Icons.forward_15_rounded] / [Icons.replay_15_rounded] don't exist in
  /// the Flutter Material icon set.
  Widget _buildIcon() {
    if (widget.seekInterval == 15) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            widget.isForward
                ? Icons.fast_forward_rounded
                : Icons.fast_rewind_rounded,
            color: Colors.white,
            size: 32,
          ),
          const Text(
            '15',
            style: TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              height: 1.1,
            ),
          ),
        ],
      );
    }

    final IconData iconData;
    if (widget.isForward) {
      iconData = widget.seekInterval <= 5
          ? Icons.forward_5_rounded
          : widget.seekInterval <= 10
              ? Icons.forward_10_rounded
              : Icons.forward_30_rounded;
    } else {
      iconData = widget.seekInterval <= 5
          ? Icons.replay_5_rounded
          : widget.seekInterval <= 10
              ? Icons.replay_10_rounded
              : Icons.replay_30_rounded;
    }
    return Icon(iconData, color: Colors.white, size: 44);
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    // Precompute values that depend only on isForward (never change).
    final radius = BorderRadius.horizontal(
      left:  widget.isForward ? Radius.zero : const Radius.circular(999),
      right: widget.isForward ? const Radius.circular(999) : Radius.zero,
    );
    // Positive = rightward, negative = leftward.
    final chevronDir = widget.isForward ? 1.0 : -1.0;
    // Build the icon widget once (doesn't change while mounted).
    final iconWidget = _buildIcon();
    final label = widget.isForward
        ? '+${widget.seekInterval}s'
        : '−${widget.seekInterval}s';

    return AnimatedBuilder(
      animation: widget.animation,
      builder: (context, _) {
        return IgnorePointer(
          child: ClipRRect(
            borderRadius: radius,
            child: Stack(
              children: [
                // ── 1. Background gradient tint ──────────────────────────────
                Positioned.fill(
                  child: Opacity(
                    opacity: (_bgOpacity.value * 0.22).clamp(0.0, 1.0),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: widget.isForward
                              ? Alignment.centerLeft
                              : Alignment.centerRight,
                          end: widget.isForward
                              ? Alignment.centerRight
                              : Alignment.centerLeft,
                          colors: const [
                            Color(0x00FFFFFF),
                            Color(0x33FFFFFF),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                // ── 2. Ripple rings (Canvas) ──────────────────────────────────
                Positioned.fill(
                  child: CustomPaint(
                    painter: _RipplePainter(
                      progress1: _ripple1.value,
                      progress2: _ripple2.value,
                      progress3: _ripple3.value,
                      opacity:   _rippleOpacity.value,
                      isForward: widget.isForward,
                    ),
                  ),
                ),

                // ── 3. Chevron arrows ─────────────────────────────────────────
                Positioned.fill(
                  child: _ChevronLayer(
                    p1:        _chevron1.value,
                    p2:        _chevron2.value,
                    p3:        _chevron3.value,
                    direction: chevronDir,
                    isForward: widget.isForward,
                  ),
                ),

                // ── 4 & 5. Icon + label ───────────────────────────────────────
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Opacity(
                        opacity: _iconOpacity.value,
                        child: Transform.scale(
                          scale: _iconScale.value,
                          child: iconWidget,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Transform.translate(
                        offset: Offset(0, _labelSlide.value),
                        child: Opacity(
                          opacity: _labelOpacity.value,
                          child: Text(
                            label,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ── Ripple ring painter ────────────────────────────────────────────────────────

class _RipplePainter extends CustomPainter {
  final double progress1;
  final double progress2;
  final double progress3;
  final double opacity;
  final bool isForward;

  const _RipplePainter({
    required this.progress1,
    required this.progress2,
    required this.progress3,
    required this.opacity,
    required this.isForward,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (opacity <= 0) return;

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    // Origin: the inner edge (where the tap happened — centre of the screen).
    final originX = isForward ? 0.0 : size.width;
    final origin  = Offset(originX, size.height * 0.5);

    // Max radius: diagonal to far corner of the half panel.
    final maxR = Offset(size.width, size.height * 0.5).distance;

    void drawRing(double progress) {
      if (progress <= 0) return;
      final r = progress * maxR;
      final ringOpacity = opacity * (1.0 - progress * 0.8);
      paint.color = Colors.white.withValues(alpha: ringOpacity.clamp(0.0, 1.0));
      canvas.drawCircle(origin, r, paint);
    }

    drawRing(progress1);
    drawRing(progress2);
    drawRing(progress3);
  }

  @override
  bool shouldRepaint(_RipplePainter old) =>
      old.progress1 != progress1 ||
      old.progress2 != progress2 ||
      old.progress3 != progress3 ||
      old.opacity   != opacity;
}

// ── Chevron layer ──────────────────────────────────────────────────────────────

/// Three chevron arrows (‹‹‹ / ›››) that sweep outward in a staggered wave.
class _ChevronLayer extends StatelessWidget {
  final double p1;        // leading chevron progress
  final double p2;
  final double p3;        // trailing chevron progress
  final double direction; // +1 = rightward, −1 = leftward
  final bool isForward;

  const _ChevronLayer({
    required this.p1,
    required this.p2,
    required this.p3,
    required this.direction,
    required this.isForward,
  });

  @override
  Widget build(BuildContext context) {
    // Each chevron travels 28 px and fades in during the first half of its
    // progress range, then fades out in the second half (bell-curve opacity).
    Widget chevron(double progress) {
      final tx  = direction * progress * 28.0;
      final opa = progress < 0.5
          ? progress * 2.0
          : (1.0 - progress) * 2.0;
      return Transform.translate(
        offset: Offset(tx, 0),
        child: Opacity(
          opacity: opa.clamp(0.0, 1.0),
          child: Icon(
            isForward
                ? Icons.chevron_right_rounded
                : Icons.chevron_left_rounded,
            color: Colors.white,
            size: 26,
          ),
        ),
      );
    }

    // Leading chevron (p1) appears first; trailing (p3) appears last.
    // Order in the Row is mirrored so they always point in the correct
    // direction regardless of which side of the screen was tapped.
    final children = isForward
        ? [chevron(p1), chevron(p2), chevron(p3)]
        : [chevron(p3), chevron(p2), chevron(p1)];

    return Center(
      child: Padding(
        // Push chevrons above the label so they don't overlap.
        padding: const EdgeInsets.only(bottom: 48),
        child: Row(mainAxisSize: MainAxisSize.min, children: children),
      ),
    );
  }
}
