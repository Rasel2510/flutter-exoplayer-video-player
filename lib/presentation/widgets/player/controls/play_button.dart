part of 'player_controls_overlay.dart';

class _PlayButton extends StatefulWidget {
  final bool isPlaying;
  final VoidCallback onTap;
  const _PlayButton({required this.isPlaying, required this.onTap});

  @override
  State<_PlayButton> createState() => _PlayButtonState();
}

class _PlayButtonState extends State<_PlayButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 300),
    value: 0.0, // starts at "play" icon
  );

  @override
  void initState() {
    super.initState();
    if (widget.isPlaying) _ctrl.value = 1.0;
  }

  @override
  void didUpdateWidget(_PlayButton old) {
    super.didUpdateWidget(old);
    if (widget.isPlaying != old.isPlaying) {
      widget.isPlaying ? _ctrl.forward() : _ctrl.reverse();
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: _GlassSurface(
        width: 62,
        height: 62,
        alignment: Alignment.center,
        strong: true,
        // A soft drop shadow (tint mode) lifts the button off bright frames.
        shadow: const [
          BoxShadow(
            color: Color(0x59000000),
            blurRadius: 18,
            spreadRadius: 2,
          ),
        ],
        child: AnimatedIcon(
          icon: AnimatedIcons.play_pause,
          progress: _ctrl,
          size: 34,
          color: _kWhite100,
        ),
      ),
    );
  }
}


