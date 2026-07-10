part of 'subtitle_sheet.dart';

/// Icon (optional) + label, then a horizontally-scrollable strip of color
/// swatches below. The right edge fades out only while there's more to
/// scroll to. Shared by the subtitle sheet's text-color and
/// background-color rows — mirrors the same pattern used by the Settings
/// sheet's folder-icon/badge-color pickers.
class _ColorSwatchRow extends StatefulWidget {
  final IconData? icon;
  final String label;
  final List<Color> colors;
  final int selectedIndex;
  final void Function(int) onSelect;

  const _ColorSwatchRow({
    this.icon,
    required this.label,
    required this.colors,
    required this.selectedIndex,
    required this.onSelect,
  });

  @override
  State<_ColorSwatchRow> createState() => _ColorSwatchRowState();
}

class _ColorSwatchRowState extends State<_ColorSwatchRow> {
  final _scrollController = ScrollController();
  // Only fade the trailing edge when the strip actually has more to scroll
  // to — otherwise a layout wide enough to show every preset would dim the
  // last swatch even though nothing is hidden.
  bool _canScroll = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_updateCanScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) => _updateCanScroll());
  }

  @override
  void dispose() {
    _scrollController.removeListener(_updateCanScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _updateCanScroll() {
    if (!_scrollController.hasClients) return;
    final canScroll = _scrollController.position.maxScrollExtent > 0;
    if (canScroll != _canScroll) setState(() => _canScroll = canScroll);
  }

  @override
  Widget build(BuildContext context) {
    final strip = SizedBox(
      height: 24,
      child: ListView.separated(
        controller: _scrollController,
        scrollDirection: Axis.horizontal,
        clipBehavior: Clip.none,
        // Trailing pad so the last swatch can scroll clear of the fade.
        padding: EdgeInsets.only(right: _canScroll ? 24 : 0),
        itemCount: widget.colors.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (_, i) => GestureDetector(
          onTap: () => widget.onSelect(i),
          child: Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              color: widget.colors[i],
              shape: BoxShape.circle,
              border: Border.all(
                color: widget.selectedIndex == i
                    ? context.colors.accent
                    : context.colors.border,
                width: widget.selectedIndex == i ? 2 : 1,
              ),
            ),
          ),
        ),
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (widget.icon != null) ...[
              Icon(widget.icon, color: context.colors.textMuted, size: 18),
              const SizedBox(width: 14),
            ] else
              const SizedBox(width: 32), // Align with an icon row above it.
            Text(widget.label,
                style: TextStyle(color: context.colors.textSecondary, fontSize: 13)),
          ],
        ),
        const SizedBox(height: 10),
        _canScroll
            ? ShaderMask(
                shaderCallback: (bounds) => const LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [Colors.white, Colors.white, Colors.transparent],
                  stops: [0.0, 0.9, 1.0],
                ).createShader(bounds),
                blendMode: BlendMode.dstIn,
                child: strip,
              )
            : strip,
      ],
    );
  }
}
