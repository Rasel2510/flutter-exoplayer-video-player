part of '../player_controls_overlay.dart';

class _TopBar extends ConsumerWidget {
  final String fileName;
  final VoidCallback onBack;
  final VoidCallback onShowSpeed;
  final VoidCallback onShowVolume;
  final VoidCallback onShowAudio;
  final VoidCallback onShowSubtitle;
  final VoidCallback onToggleRepeat;
  final VoidCallback onAudioMode;
  final VoidCallback onSleepTimer;
  final VoidCallback onCycleAbRepeat;

  const _TopBar({
    required this.fileName,
    required this.onBack,
    required this.onShowSpeed,
    required this.onShowVolume,
    required this.onShowAudio,
    required this.onShowSubtitle,
    required this.onToggleRepeat,
    required this.onAudioMode,
    required this.onSleepTimer,
    required this.onCycleAbRepeat,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // One combined select = one listener, one rebuild per change instead of six.
    final (
      :speed,
      :volume,
      :loopMode,
      :hasMultipleAudio,
      :hasSubtitles,
      :subtitlesEnabled,
      :sleepActive,
      :abState,
    ) = ref.watch(playerProvider.select((s) => (
          speed: s.playbackSpeed,
          volume: s.volume,
          loopMode: s.loopMode,
          hasMultipleAudio: s.audioTracks.length > 1,
          hasSubtitles: s.subtitleTracks.isNotEmpty,
          subtitlesEnabled: s.subtitlesEnabled,
          sleepActive: s.sleepTimerEndsAt != null || s.sleepTimerEndOfVideo,
          // 0 = off, 1 = A set (waiting for B), 2 = looping A↔B.
          abState: s.abRepeatStart == null
              ? 0
              : (s.abRepeatEnd == null ? 1 : 2),
        )));

    // Avoid allocating a new string on every build when speed hasn't changed.
    // The select above already prevents rebuild unless speed changes, so this
    // is just defensive clarity.
    final speedLabel =
        speed == speed.roundToDouble() ? '${speed.toInt()}×' : '$speed×';

    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 8, 18, 0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Row 1: back + title ──────────────────────────────────────────
          Row(
            children: [
              _GlassIconButton(
                icon: Icons.arrow_back_ios_new_rounded,
                size: 20,
                onTap: onBack,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  fileName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _kWhite100,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.1,
                  ),
                ),
              ),
            ],
          ),

          // ── Row 2: action buttons ────────────────────────────────────────
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            reverse: true,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
              // Playback speed
              _MiniChip(label: speedLabel, onTap: onShowSpeed),
              const SizedBox(width: 6),
              // Volume
              _GlassIconButton(
                icon: volume == 0
                    ? Icons.volume_off_rounded
                    : volume < 50
                        ? Icons.volume_down_rounded
                        : Icons.volume_up_rounded,
                size: 20,
                onTap: onShowVolume,
                // Orange tint when volume is boosted
                boosted: volume > 100,
              ),
              // Audio track — always visible. Highlighted (accent) when the
              // video actually has more than one audio track to choose from.
              const SizedBox(width: 2),
              _GlassIconButton(
                icon: Icons.audiotrack_rounded,
                size: 19,
                onTap: onShowAudio,
                active: hasMultipleAudio,
              ),
              const SizedBox(width: 2),
              // Audio (background) mode — play as audio and leave the screen.
              _GlassIconButton(
                icon: Icons.headphones_rounded,
                size: 19,
                onTap: onAudioMode,
              ),
              const SizedBox(width: 2),
              // Sleep timer — auto-pause after a delay / end of video.
              _GlassIconButton(
                icon: Icons.bedtime_rounded,
                size: 18,
                onTap: onSleepTimer,
                active: sleepActive,
              ),
              const SizedBox(width: 2),
              // Subtitle — white when off, orange when on.
              _GlassIconButton(
                icon: subtitlesEnabled && hasSubtitles
                    ? Icons.subtitles_rounded
                    : Icons.subtitles_off_outlined,
                size: 19,
                onTap: onShowSubtitle,
                active: subtitlesEnabled && hasSubtitles,
              ),
              const SizedBox(width: 6),
              // A-B repeat — tap to set A, again for B (loops), again to clear.
              _MiniChip(
                label: abState == 1 ? 'A•' : 'A-B',
                onTap: onCycleAbRepeat,
                color: abState == 0 ? null : context.colors.accent,
              ),
              const SizedBox(width: 6),
              // Repeat / loop
              _GlassIconButton(
                icon: loopMode == LoopMode.loopOne
                    ? Icons.repeat_one_rounded
                    : Icons.repeat_rounded,
                size: 19,
                onTap: onToggleRepeat,
                active: loopMode.isActive,
                // Orange when loop-one, accent when loop-all
                loopMode: loopMode,
              ),
            ],
          ),
          ),
        ],
      ),
    );
  }
}

// ── Center controls ───────────────────────────────────────────────────────────


