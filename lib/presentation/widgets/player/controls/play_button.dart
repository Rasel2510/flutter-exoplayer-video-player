part of '../player_controls_overlay.dart';

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
        width: 54,
        height: 54,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: _kBlack70,
          border: Border.all(color: _kWhite30, width: 1),
        ),
        child: Center(
          child: AnimatedIcon(
            icon: AnimatedIcons.play_pause,
            progress: _ctrl,
            size: 30,
            color: _kWhite100,
          ),
        ),
      ),
    );
  }
}


