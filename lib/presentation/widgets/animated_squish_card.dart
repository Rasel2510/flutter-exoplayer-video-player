import 'package:flutter/material.dart';

class AnimatedSquishCard extends StatefulWidget {
  final Widget child;
  final double scaleDown;

  const AnimatedSquishCard({
    super.key,
    required this.child,
    this.scaleDown = 0.97,
  });

  @override
  State<AnimatedSquishCard> createState() => _AnimatedSquishCardState();
}

class _AnimatedSquishCardState extends State<AnimatedSquishCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
      reverseDuration: const Duration(milliseconds: 200),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: widget.scaleDown).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutQuad),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onPointerDown(PointerDownEvent event) {
    _controller.forward();
  }

  void _onPointerUp(PointerUpEvent event) {
    _controller.reverse();
  }

  void _onPointerCancel(PointerCancelEvent event) {
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: _onPointerDown,
      onPointerUp: _onPointerUp,
      onPointerCancel: _onPointerCancel,
      behavior: HitTestBehavior.translucent,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            // Isolates the card's contents (thumbnail bitmap, ink well, text)
            // onto their own compositor layer so each squish frame just
            // re-transforms that cached layer instead of repainting the
            // whole card — this widget now wraps every card in the library
            // and folder lists.
            child: RepaintBoundary(child: child),
          );
        },
        child: widget.child,
      ),
    );
  }
}
