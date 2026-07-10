import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_video_player/core/theme/app_theme.dart';
import 'package:flutter_video_player/data/engines/player_engine.dart';
import 'package:flutter_video_player/presentation/providers/subtitle_style_provider.dart';
import 'package:flutter_video_player/presentation/widgets/common/sheet_surface.dart';

part 'delay_control.dart';
part 'appearance_control.dart';
part 'color_swatch_row.dart';
part 'subtitle_step_button.dart';

class SubtitleSheet extends StatelessWidget {
  final List<MediaTrack> tracks;
  final MediaTrack? selectedTrack;
  final bool subtitlesEnabled;
  final void Function(MediaTrack) onSelect;
  final VoidCallback onToggle;
  final VoidCallback onLoadExternal;
  final double delay; // seconds (+ later, − earlier)
  final void Function(double) onAdjustDelay; // delta seconds
  final VoidCallback onResetDelay;

  const SubtitleSheet({
    super.key,
    required this.tracks,
    required this.selectedTrack,
    required this.subtitlesEnabled,
    required this.onSelect,
    required this.onToggle,
    required this.onLoadExternal,
    required this.delay,
    required this.onAdjustDelay,
    required this.onResetDelay,
  });

  @override
  Widget build(BuildContext context) {
    // isScrollControlled=true is set at the call site so the sheet can grow as
    // needed; SheetSurface bounds it and lets the body scroll in landscape.
    return SheetSurface(
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Header row ───────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: Row(
                children: [
                  Icon(Icons.subtitles_outlined,
                      color: context.colors.accent, size: 18),
                  const SizedBox(width: 10),
                  Text(
                    'Subtitles',
                    style: TextStyle(
                      color: context.colors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  // Global on/off toggle
                  GestureDetector(
                    onTap: () {
                      onToggle();
                      Navigator.pop(context);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: subtitlesEnabled
                            ? context.colors.accentSoft
                            : context.colors.elevated,
                        border: Border.all(
                          color: subtitlesEnabled
                              ? context.colors.accent
                              : context.colors.border,
                        ),
                        borderRadius: AppRadius.sm,
                      ),
                      child: Text(
                        subtitlesEnabled ? 'ON' : 'OFF',
                        style: TextStyle(
                          color: subtitlesEnabled
                              ? context.colors.accent
                              : context.colors.textMuted,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'monospace',
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Divider(color: context.colors.divider, height: 1),

            // ── Subtitle sync offset ─────────────────────────────────────
            _DelayControl(
              delay: delay,
              onAdjust: onAdjustDelay,
              onReset: onResetDelay,
            ),

            Divider(color: context.colors.divider, height: 1),

            // ── Subtitle appearance (font size / color / background) ──────
            const _AppearanceControl(),

            Divider(color: context.colors.divider, height: 1),

            if (tracks.isEmpty)
              Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'No subtitle tracks in this file.\nLoad an external .srt file using the button below.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: context.colors.textMuted,
                    fontSize: 12,
                    height: 1.5,
                  ),
                ),
              )
            else
              // Track list — part of the outer scroll view, so it doesn't
              // scroll independently.
              ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: tracks.length,
                  itemBuilder: (_, i) {
                    final track = tracks[i];
                    final isSelected =
                        subtitlesEnabled && selectedTrack?.id == track.id;
                    final label = track.title?.isNotEmpty == true
                        ? track.title!
                        : track.language?.isNotEmpty == true
                            ? track.language!
                            : 'Track ${i + 1}';

                    return InkWell(
                      onTap: () {
                        onSelect(track);
                        Navigator.pop(context);
                      },
                      splashColor: context.colors.accentSoft,
                      highlightColor: Colors.transparent,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 14),
                        child: Row(
                          children: [
                            Icon(
                              isSelected
                                  ? Icons.radio_button_checked
                                  : Icons.radio_button_off,
                              color: isSelected
                                  ? context.colors.accent
                                  : context.colors.textMuted,
                              size: 18,
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Text(
                                label,
                                style: TextStyle(
                                  color: isSelected
                                      ? context.colors.textPrimary
                                      : context.colors.textSecondary,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                            if (isSelected)
                              Icon(Icons.check_rounded,
                                  color: context.colors.accent, size: 16),
                          ],
                        ),
                      ),
                    );
                  },
                ),

            // ── Load external subtitle button ────────────────────────────
            Padding(
              padding: EdgeInsets.fromLTRB(20, 8, 20, 24 + MediaQuery.of(context).padding.bottom),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    onLoadExternal();
                  },
                  icon: Icon(Icons.folder_open_outlined,
                      size: 16, color: context.colors.accent),
                  label: Text(
                    'Load external subtitle',
                    style: TextStyle(
                      color: context.colors.accent,
                      fontSize: 12,
                      letterSpacing: 0.5,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: context.colors.border),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    shape: const RoundedRectangleBorder(
                        borderRadius: AppRadius.sm),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Subtitle delay (+/-) control ────────────────────────────────────────────────

/// Adjusts the subtitle sync offset. Keeps a local copy so the readout updates
/// instantly on tap (the provider is the source of truth for the actual delay).

