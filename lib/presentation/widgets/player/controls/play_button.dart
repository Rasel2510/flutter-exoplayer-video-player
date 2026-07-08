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
      child: Container(
        width: 62,
        height: 62,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: _kBlack70,
          // A soft drop shadow lifts the button off bright video frames; the
          // faint ring replaces the old harsh 1px border.
          border: Border.fromBorderSide(BorderSide(color: _kWhite12)),
          boxShadow: [
            BoxShadow(
              color: Color(0x59000000),
              blurRadius: 18,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Center(
          child: AnimatedIcon(
            icon: AnimatedIcons.play_pause,
            progress: _ctrl,
            size: 34,
            color: _kWhite100,
          ),
        ),
      ),
    );
  }
}


