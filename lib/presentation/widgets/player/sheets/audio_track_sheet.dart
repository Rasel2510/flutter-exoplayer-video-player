import 'package:flutter/material.dart';
import 'package:flutter_video_player/core/theme/app_theme.dart';
import 'package:flutter_video_player/core/utils/track_labels.dart';
import 'package:flutter_video_player/data/engines/player_engine.dart';
import 'package:flutter_video_player/presentation/widgets/common/sheet_surface.dart';

class AudioTrackSheet extends StatelessWidget {
  final List<MediaTrack> tracks;
  final MediaTrack? selectedTrack;
  final bool audioEnabled;
  final void Function(MediaTrack) onSelect;
  final VoidCallback onDisable;

  const AudioTrackSheet({
    super.key,
    required this.tracks,
    required this.selectedTrack,
    required this.audioEnabled,
    required this.onSelect,
    required this.onDisable,
  });

  /// Index of the active track to highlight; falls back to the first track when
  /// the engine hasn't resolved a concrete selection yet. Returns -1 when audio
  /// is disabled so no track row is highlighted.
  int _selectedIndex() {
    if (!audioEnabled) return -1;
    final id = selectedTrack?.id;
    final i = tracks.indexWhere((t) => t.id == id);
    return i < 0 ? 0 : i;
  }

  @override
  Widget build(BuildContext context) {
    final selectedIndex = _selectedIndex();
    return SheetSurface(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ───────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
            child: Row(
              children: [
                Icon(Icons.audiotrack_outlined,
                    color: context.colors.accent, size: 18),
                const SizedBox(width: 10),
                Text(
                  'Audio Tracks',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: context.colors.textPrimary,
                  ),
                ),
              ],
            ),
          ),

          Divider(color: context.colors.divider, height: 1),

          if (tracks.isEmpty)
            Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'No audio tracks found',
                style: TextStyle(color: context.colors.textMuted, fontSize: 13),
              ),
            )
          else
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                // +1 for the leading "Disable" row.
                itemCount: tracks.length + 1,
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return _row(
                      context,
                      icon: Icons.volume_off_rounded,
                      label: 'Disable',
                      isSelected: !audioEnabled,
                      onTap: onDisable,
                    );
                  }
                  final trackIndex = index - 1;
                  final track = tracks[trackIndex];
                  return _row(
                    context,
                    icon: Icons.audiotrack_outlined,
                    label: TrackLabels.trackLabel(
                      title: track.title,
                      language: track.language,
                      index: trackIndex,
                      total: tracks.length,
                    ),
                    isSelected: trackIndex == selectedIndex,
                    onTap: () => onSelect(track),
                  );
                },
              ),
            ),
          SizedBox(height: 16 + MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }

  Widget _row(
    BuildContext context, {
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: () {
        onTap();
        Navigator.pop(context);
      },
      splashColor: context.colors.accentSoft,
      highlightColor: Colors.transparent,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected
                  ? context.colors.accent
                  : context.colors.textMuted,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: isSelected
                      ? context.colors.textPrimary
                      : context.colors.textSecondary,
                  fontWeight:
                      isSelected ? FontWeight.w600 : FontWeight.normal,
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
  }
}
