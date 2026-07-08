import 'package:flutter/material.dart';
import 'package:flutter_video_player/core/theme/app_theme.dart';
import 'package:flutter_video_player/presentation/widgets/common/sheet_surface.dart';
import 'sort_option.dart';

class SortSheet extends StatelessWidget {
  final SortOption current;
  final void Function(SortOption) onSelect;

  const SortSheet({super.key, required this.current, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).padding.bottom;
    return SheetSurface(
      child: SingleChildScrollView(
        child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ───────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
            child: Text('SORT BY', style: context.textStyles.label),
          ),

          // ── Options ──────────────────────────────────────────────────────
          ...SortOption.values.map((opt) {
            final selected = opt == current;
            return Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => onSelect(opt),
                splashColor: context.colors.accentSoft,
                highlightColor: Colors.transparent,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 14),
                  child: Row(
                    children: [
                      Icon(
                        opt.icon,
                        size: 20,
                        color: selected
                            ? context.colors.accent
                            : context.colors.textSecondary,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          opt.label,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: selected
                                ? FontWeight.w600
                                : FontWeight.w400,
                            color: selected
                                ? context.colors.accent
                                : context.colors.textPrimary,
                          ),
                        ),
                      ),
                      if (selected)
                        Icon(Icons.check_rounded,
                            size: 18, color: context.colors.accent),
                    ],
                  ),
                ),
              ),
            );
          }),

          SizedBox(height: 16 + bottomPad),
        ],
        ),
      ),
    );
  }
}
