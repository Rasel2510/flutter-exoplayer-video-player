import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_video_player/core/theme/app_theme.dart';
import 'package:flutter_video_player/models/video_folder.dart';
import '../../providers/library_appearance_provider.dart';
import '../animated_squish_card.dart';
import 'new_badge.dart';
import 'resume_pill.dart';

class FolderCard extends ConsumerWidget {
  final VideoFolder folder;
  final bool isExternal;
  final bool isNew;
  final Duration? resumePosition;
  final VoidCallback onTap;
  final VoidCallback? onResume;

  const FolderCard({
    super.key,
    required this.folder,
    required this.isExternal,
    required this.onTap,
    this.isNew = false,
    this.resumePosition,
    this.onResume,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final iconColorIndex = ref.watch(
        libraryAppearanceProvider.select((a) => a.folderIconColorIndex));
    final folderIconColor =
        resolveLibraryAccent(iconColorIndex, context.colors.folderIcon);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: AnimatedSquishCard(
        child: Material(
          color: context.colors.surface,
          borderRadius: AppRadius.md,
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            splashColor: context.colors.accentSoft,
            highlightColor: Colors.transparent,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
              child: Row(
                children: [
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      Icon(
                        Icons.folder_rounded,
                        size: 32,
                        color: isExternal
                            ? const Color(0xFF40AAAA)
                            : folderIconColor,
                      ),
                      if (isExternal)
                        const Positioned(
                          right: 0,
                          bottom: 0,
                          child: Icon(Icons.sd_card_rounded,
                              size: 10, color: Color(0xFF40AAAA)),
                        ),
                    ],
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          folder.name,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: context.colors.textPrimary,
                            letterSpacing: -0.2,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (isNew) ...[
                          const SizedBox(height: 2),
                          const NewBadge(),
                        ],
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            Text(
                              '${folder.videoCount} '
                              'video${folder.videoCount == 1 ? '' : 's'}',
                              style: context.textStyles.bodySmall,
                            ),
                            if (isExternal) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: const BoxDecoration(
                                  color: Color(0xFF0A2020),
                                  borderRadius: AppRadius.xs,
                                ),
                                child: const Text('SD',
                                    style: TextStyle(
                                        fontSize: 9,
                                        color: Color(0xFF40AAAA),
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 0.5)),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (onResume != null && resumePosition != null) ...[
                    ResumePill(position: resumePosition!, onTap: onResume!),
                    const SizedBox(width: 10),
                  ],
                  Icon(Icons.chevron_right_rounded,
                      size: 18, color: context.colors.textMuted),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
