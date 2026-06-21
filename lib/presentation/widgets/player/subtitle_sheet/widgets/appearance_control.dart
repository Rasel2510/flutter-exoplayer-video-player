part of '../subtitle_sheet.dart';

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
              Icon(Icons.palette_outlined,
                  color: context.colors.textMuted, size: 18),
              const SizedBox(width: 14),
              Text('Color',
                  style:
                      TextStyle(color: context.colors.textSecondary, fontSize: 13)),
              const Spacer(),
              for (var i = 0; i < subtitleColorPresets.length; i++)
                Padding(
                  padding: const EdgeInsets.only(left: 10),
                  child: GestureDetector(
                    onTap: () => notifier.setColorIndex(i),
                    child: Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        color: subtitleColorPresets[i],
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: style.colorIndex == i
                              ? context.colors.accent
                              : context.colors.border,
                          width: style.colorIndex == i ? 2 : 1,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
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
            Row(
              children: [
                const SizedBox(width: 32), // Align with text
                Text('Background color',
                    style: TextStyle(color: context.colors.textSecondary, fontSize: 13)),
                const Spacer(),
                for (var i = 0; i < subtitleBgColorPresets.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(left: 10),
                    child: GestureDetector(
                      onTap: () => notifier.setBackgroundColorIndex(i),
                      child: Container(
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          // the preset colors have alpha, so we render them on white or just use the raw color
                          // Since panel is dark, the alpha color will blend and show correctly.
                          color: subtitleBgColorPresets[i].withValues(alpha: 1.0), // Show solid color in picker
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: style.backgroundColorIndex == i
                                ? context.colors.accent
                                : context.colors.border,
                            width: style.backgroundColorIndex == i ? 2 : 1,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}


