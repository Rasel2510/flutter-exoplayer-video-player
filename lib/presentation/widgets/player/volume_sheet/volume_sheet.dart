import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/volume_color.dart';
import '../../common/sheet_surface.dart';

part 'widgets/preset_button.dart';

class VolumeSheet extends StatefulWidget {
  final double volume; // 0.0 – 200.0
  final void Function(double) onChanged;

  const VolumeSheet({
    super.key,
    required this.volume,
    required this.onChanged,
  });

  @override
  State<VolumeSheet> createState() => _VolumeSheetState();
}

class _VolumeSheetState extends State<VolumeSheet> {
  late double _volume;

  static const Color _boostColor     = VolumeColor.boost;
  static const Color _boostColorSoft = VolumeColor.boostSoft;

  @override
  void initState() {
    super.initState();
    _volume = widget.volume.clamp(0.0, 200.0);
  }

  bool get _isBoosted => _volume > 100.0;

  // Blue at ≤100 %, shifting toward orange the further past 100 % the volume
  // is pushed (fully orange at 200 %) — matches the swipe HUD gauge.
  Color _accent(BuildContext context) =>
      VolumeColor.forVolume(_volume, context.colors.accent);

  Color _accentSoft(BuildContext context) =>
      _isBoosted ? _boostColorSoft : context.colors.accentSoft;

  void _set(double v) {
    setState(() => _volume = v.clamp(0.0, 200.0));
    widget.onChanged(_volume);
  }

  void _setAndClose(double v) {
    _set(v);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final accent     = _accent(context);
    final accentSoft = _accentSoft(context);

    return SheetSurface(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header row ───────────────────────────────────────────────────
          Row(
            children: [
              Text(
                _isBoosted ? 'VOLUME BOOST' : 'VOLUME',
                style: context.textStyles.label.copyWith(
                  color: _isBoosted ? _boostColor : null,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: context.colors.elevated,
                    borderRadius: AppRadius.xl,
                    border: Border.all(color: context.colors.border),
                  ),
                  child: Text(
                    'Done',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: context.colors.textSecondary,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // ── Slider ────────────────────────────────────────────────────────
          Row(
            children: [
              Icon(Icons.volume_off_rounded,
                  color: context.colors.textMuted, size: 20),
              Expanded(
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    // Same rule as the swipe HUD bar: one solid fill that is
                    // accent through 100 %, then the whole track heats toward
                    // red across the boost range (design spec).
                    activeTrackColor:
                        VolumeColor.barColor(_volume, context.colors.accent),
                    inactiveTrackColor: context.colors.textDim,
                    thumbColor: accent,
                    overlayColor: accentSoft,
                    trackHeight: 4,
                    thumbShape:
                        const RoundSliderThumbShape(enabledThumbRadius: 7),
                  ),
                  child: Slider(
                    min: 0.0,
                    max: 200.0,
                    value: _volume,
                    onChanged: _set,
                  ),
                ),
              ),
              Icon(Icons.volume_up_rounded,
                  color: context.colors.textMuted, size: 20),
              const SizedBox(width: 12),
              SizedBox(
                width: 48,
                child: Text(
                  '${_volume.round()}%',
                  style: TextStyle(
                    color: accent,
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // ── Normal presets ────────────────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [0.0, 25.0, 50.0, 75.0, 100.0].map((v) {
              final active = (_volume - v).abs() < 1.0;
              return _PresetButton(
                label: '${v.round()}%',
                active: active,
                isBoost: false,
                accent: active ? context.colors.accent : null,
                accentSoft: context.colors.accentSoft,
                border: context.colors.border,
                muted: context.colors.textMuted,
                onTap: () => _setAndClose(v),
              );
            }).toList(),
          ),
          const SizedBox(height: 8),

          // ── Boost presets ─────────────────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [125.0, 150.0, 175.0, 200.0].map((v) {
              final active = (_volume - v).abs() < 1.0;
              return _PresetButton(
                label: '${v.round()}%',
                active: active,
                isBoost: true,
                accent: active ? _boostColor : null,
                accentSoft: _boostColorSoft,
                border: context.colors.border,
                muted: context.colors.textMuted,
                onTap: () => _setAndClose(v),
              );
            }).toList(),
          ),
          const SizedBox(height: 8),
          SizedBox(height: MediaQuery.of(context).padding.bottom),
        ],
        ),
      ),
    );
  }
}


