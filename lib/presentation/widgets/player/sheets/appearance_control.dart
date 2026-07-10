part of 'subtitle_sheet.dart';

class _AppearanceControl extends ConsumerWidget {
  const _AppearanceControl();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final style = ref.watch(subtitleStyleProvider);
    final notifier = ref.read(subtitleStyleProvider.notifier);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Subtitle Style Preview
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF3A3D44), Color(0xFF1A1C20)],
              ),
              border: Border.all(color: context.colors.border),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 8,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Center(
              child: Text(
                'Subtitle Preview',
                textAlign: TextAlign.center,
                style: TextStyle(
                  height: 1.4,
                  fontSize: style.fontSize,
                  color: style.color,
                  fontFamily: style.fontFamily,
                  fontWeight: FontWeight.bold,
                  backgroundColor: style.background
                      ? style.backgroundColor
                      : Colors.transparent,
                  shadows: style.background
                      ? null
                      : const [
                          Shadow(blurRadius: 4, color: Colors.black),
                          Shadow(blurRadius: 8, color: Colors.black),
                        ],
                ),
              ),
            ),
          ),
          
          Row(
            children: [
              Icon(Icons.format_size_rounded,
                  color: context.colors.textMuted, size: 18),
              const SizedBox(width: 14),
              Text('Font size',
                  style:
                      TextStyle(color: context.colors.textSecondary, fontSize: 13)),
              const Spacer(),
              _StepButton(
                icon: Icons.remove_rounded,
                onTap: () => notifier.adjustFontSize(-4),
              ),
              SizedBox(
                width: 40,
                child: Text(
                  style.fontSize.toStringAsFixed(0),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: context.colors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
              _StepButton(
                icon: Icons.add_rounded,
                onTap: () => notifier.adjustFontSize(4),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Icon(Icons.text_fields_rounded,
                  color: context.colors.textMuted, size: 18),
              const SizedBox(width: 14),
              Text('Font',
                  style: TextStyle(
                      color: context.colors.textSecondary, fontSize: 13)),
            ],
          ),
          const SizedBox(height: 10),
          // Each chip renders its label in its own family — a live preview.
          SizedBox(
            height: 38,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              clipBehavior: Clip.none,
              itemCount: subtitleFontPresets.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final preset = subtitleFontPresets[i];
                final selected = style.fontIndex == i;
                return GestureDetector(
                  onTap: () => notifier.setFontIndex(i),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: selected
                          ? context.colors.accentSoft
                          : context.colors.elevated,
                      borderRadius: BorderRadius.circular(19),
                      border: Border.all(
                        color: selected
                            ? context.colors.accent
                            : context.colors.border,
                        width: selected ? 1.5 : 1,
                      ),
                    ),
                    child: Text(
                      preset.label,
                      style: TextStyle(
                        fontFamily: preset.family,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: selected
                            ? context.colors.accent
                            : context.colors.textPrimary,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          _ColorSwatchRow(
            icon: Icons.palette_outlined,
            label: 'Color',
            colors: subtitleColorPresets,
            selectedIndex: style.colorIndex,
            onSelect: notifier.setColorIndex,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.branding_watermark_outlined,
                  color: context.colors.textMuted, size: 18),
              const SizedBox(width: 14),
              Text('Background',
                  style:
                      TextStyle(color: context.colors.textSecondary, fontSize: 13)),
              const Spacer(),
              Switch(
                value: style.background,
                activeThumbColor: context.colors.accent,
                onChanged: notifier.setBackground,
              ),
            ],
          ),
          if (style.background) ...[
            const SizedBox(height: 12),
            _ColorSwatchRow(
              label: 'Background color',
              // The preset colors carry alpha for how they render over the
              // video; shown solid here so the picker swatches read clearly.
              colors: [
                for (final c in subtitleBgColorPresets) c.withValues(alpha: 1.0)
              ],
              selectedIndex: style.backgroundColorIndex,
              onSelect: notifier.setBackgroundColorIndex,
            ),
          ],
        ],
      ),
    );
  }
}


