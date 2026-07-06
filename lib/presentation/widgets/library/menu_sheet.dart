import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../providers/continue_watching_provider.dart';
import '../common/sheet_surface.dart';

/// A beautiful bottom sheet for app settings and overflow actions.
class MenuSheet extends ConsumerWidget {
  final VoidCallback onOpenFile;

  const MenuSheet({
    super.key,
    required this.onOpenFile,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cwEnabled = ref.watch(continueWatchingEnabledProvider);

    return SheetSurface(
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: Row(
                children: [
                  Icon(Icons.settings_rounded,
                      color: context.colors.accent, size: 18),
                  const SizedBox(width: 10),
                  Text(
                    'Settings',
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
            
            // Open File action
            InkWell(
              onTap: () {
                Navigator.pop(context);
                onOpenFile();
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Row(
                  children: [
                    Icon(
                      Icons.add_rounded,
                      color: context.colors.textSecondary,
                      size: 24,
                    ),
                    const SizedBox(width: 16),
                    Text(
                      'Open file...',
                      style: TextStyle(
                        fontSize: 16,
                        color: context.colors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            // Continue Watching toggle
            InkWell(
              onTap: () {
                ref.read(continueWatchingEnabledProvider.notifier).toggle();
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Row(
                  children: [
                    Icon(
                      cwEnabled ? Icons.history_rounded : Icons.history_toggle_off_rounded,
                      color: cwEnabled ? context.colors.accent : context.colors.textSecondary,
                      size: 24,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Continue Watching',
                            style: TextStyle(
                              fontSize: 16,
                              color: cwEnabled ? context.colors.textPrimary : context.colors.textSecondary,
                              fontWeight: cwEnabled ? FontWeight.w500 : FontWeight.w400,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Show your recently watched videos',
                            style: TextStyle(
                              fontSize: 12,
                              color: context.colors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    IgnorePointer(
                      child: Switch(
                        value: cwEnabled,
                        onChanged: (_) {},
                        activeThumbColor: context.colors.surface,
                        activeTrackColor: context.colors.accent,
                        inactiveThumbColor: context.colors.surface,
                        inactiveTrackColor: context.colors.border,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            SizedBox(height: 16 + MediaQuery.of(context).padding.bottom),
          ],
        ),
      ),
    );
  }
}
