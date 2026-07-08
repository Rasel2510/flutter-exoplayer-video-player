import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../providers/scan_mode_provider.dart';
import '../../common/sheet_surface.dart';

part 'widgets/mode_row.dart';

/// Bottom sheet to choose how the library discovers videos (Android only).
class ScanModeSheet extends StatelessWidget {
  final LibraryScanMode selected;
  final void Function(LibraryScanMode) onSelect;

  const ScanModeSheet({
    super.key,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return SheetSurface(
      child: SingleChildScrollView(
        child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ───────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
            child: Row(
              children: [
                Icon(Icons.travel_explore_rounded,
                    color: context.colors.accent, size: 18),
                const SizedBox(width: 10),
                Text(
                  'Library scan mode',
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

          for (final mode in LibraryScanMode.values)
            _ModeRow(
              mode: mode,
              isSelected: mode == selected,
              onTap: () {
                onSelect(mode);
                Navigator.pop(context);
              },
            ),

          SizedBox(height: 16 + MediaQuery.of(context).padding.bottom),
        ],
        ),
      ),
    );
  }
}


