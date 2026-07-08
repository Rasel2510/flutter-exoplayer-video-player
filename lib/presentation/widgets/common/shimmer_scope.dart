part of 'thumbnail_widget.dart';

class ShimmerScope extends StatefulWidget {
  final Widget child;
  const ShimmerScope({super.key, required this.child});

  /// Returns the shimmer opacity from the nearest [ShimmerScope].
  /// Falls back to a fixed 0.08 if no scope is found (e.g. in tests).
  static Animation<double> of(BuildContext context) {
    final scope =
        context.dependOnInheritedWidgetOfExactType<_ShimmerScopeData>();
    return scope?.animation ?? const AlwaysStoppedAnimation(0.08);
  }

  @override
  State<ShimmerScope> createState() => _ShimmerScopeState();
}

class _ShimmerScopeState extends State<ShimmerScope>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1000),
  )..repeat(reverse: true);

  late final Animation<double> _anim =
      Tween(begin: 0.04, end: 0.12).animate(
    CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
  );

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _ShimmerScopeData(animation: _anim, child: widget.child);
  }
}

class _ShimmerScopeData extends InheritedWidget {
  final Animation<double> animation;
  const _ShimmerScopeData({
    required this.animation,
    required super.child,
  });

  @override
  bool updateShouldNotify(_ShimmerScopeData old) => false; // animation is stable
}

// ── Thumbnail widget ──────────────────────────────────────────────────────────

/// Async thumbnail with shimmer placeholder and graceful fallback.

