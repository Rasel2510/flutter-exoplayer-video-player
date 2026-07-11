import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_video_player/core/theme/app_theme.dart';
import 'package:flutter_video_player/data/models/video_folder.dart';
import 'package:flutter_video_player/presentation/providers/folders_provider.dart';
import 'package:flutter_video_player/presentation/widgets/library/folder_card.dart';

/// Destination-folder picker for Move/Copy-to-album. Pops with the chosen
/// [VideoFolder], or null if the user backs out.
class FolderPickerScreen extends ConsumerStatefulWidget {
  final String excludePath;
  final String title;
  final String confirmLabel;

  const FolderPickerScreen({
    super.key,
    required this.excludePath,
    required this.title,
    required this.confirmLabel,
  });

  @override
  ConsumerState<FolderPickerScreen> createState() => _FolderPickerScreenState();
}

class _FolderPickerScreenState extends ConsumerState<FolderPickerScreen> {
  VideoFolder? _selected;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(foldersProvider.notifier).load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final folders = ref
        .watch(foldersProvider.select((s) => s.folders))
        .where((f) => f.path != widget.excludePath)
        .toList();
    final newPaths = ref.watch(foldersProvider.select((s) => s.newPaths));

    return Scaffold(
      backgroundColor: context.colors.bg,
      appBar: AppBar(title: Text(widget.title)),
      body: folders.isEmpty
          ? Center(
              child: Text(
                'No other folders available',
                style: TextStyle(color: context.colors.textMuted),
              ),
            )
          : ListView.builder(
              padding: EdgeInsets.fromLTRB(
                16,
                8,
                16,
                8 + MediaQuery.of(context).padding.bottom,
              ),
              itemCount: folders.length,
              itemBuilder: (_, i) {
                final folder = folders[i];
                return FolderCard(
                  folder: folder,
                  isExternal: false,
                  isNew: newPaths.contains(folder.path),
                  onTap: () => setState(() => _selected = folder),
                );
              },
            ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: FilledButton(
            onPressed: _selected == null
                ? null
                : () => Navigator.pop(context, _selected),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
              shape: const StadiumBorder(),
            ),
            child: Text(widget.confirmLabel),
          ),
        ),
      ),
    );
  }
}
