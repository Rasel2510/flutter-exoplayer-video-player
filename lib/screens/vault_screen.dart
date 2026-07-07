import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme/app_theme.dart';
import '../models/video_file.dart';
import '../presentation/providers/vault_provider.dart';
import '../presentation/widgets/folder_videos/video_card.dart';
import '../presentation/widgets/smooth_page_route.dart';
import 'player_screen.dart';
import 'vault_pin_screen.dart';

class VaultScreen extends ConsumerStatefulWidget {
  const VaultScreen({super.key});

  @override
  ConsumerState<VaultScreen> createState() => _VaultScreenState();
}

class _VaultScreenState extends ConsumerState<VaultScreen> {
  bool _selectionMode = false;
  final Set<String> _selectedPaths = {};

  @override
  void initState() {
    super.initState();
    // Refresh vault contents when entering
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(vaultProvider.notifier).load();
    });
  }

  void _enterSelectionMode(VideoFile? initial) {
    setState(() {
      _selectionMode = true;
      if (initial != null) _selectedPaths.add(initial.path);
    });
  }

  void _exitSelectionMode() {
    setState(() {
      _selectionMode = false;
      _selectedPaths.clear();
    });
  }

  void _toggleSelection(String path) {
    setState(() {
      if (_selectedPaths.contains(path)) {
        _selectedPaths.remove(path);
      } else {
        _selectedPaths.add(path);
      }
    });
  }

  void _selectAll(List<VideoFile> videos) {
    setState(() {
      if (_selectedPaths.length == videos.length) {
        _selectedPaths.clear();
      } else {
        _selectedPaths
          ..clear()
          ..addAll(videos.map((v) => v.path));
      }
    });
  }

  Future<void> _restoreSelected(List<VideoFile> videos) async {
    final selected =
        videos.where((v) => _selectedPaths.contains(v.path)).toList();
    final count = selected.length;
    // Exit selection mode right away instead of waiting on the restore (which
    // includes a full library rescan) — otherwise the Restore/Delete bar
    // visibly lingers on screen until that finishes, looking stuck unless the
    // user manually taps the close (X) button.
    _exitSelectionMode();
    await ref.read(vaultProvider.notifier).restoreVideos(selected);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$count video(s) restored')),
    );
  }

  Future<void> _deleteSelected(List<VideoFile> videos) async {
    final selected =
        videos.where((v) => _selectedPaths.contains(v.path)).toList();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Delete ${selected.length} video(s)?'),
        content: const Text(
          'These videos will be permanently deleted. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    // Same reasoning as _restoreSelected — exit selection mode immediately
    // rather than after the delete completes.
    _exitSelectionMode();
    await ref.read(vaultProvider.notifier).deleteVideos(selected);
  }

  // Re-verifies the existing vault PIN before letting the user set a new
  // one — same "prove you already have access" gate a device PIN-change
  // flow uses, just against VaultPinService instead of the OS.
  Future<void> _changePin() async {
    final verified = await Navigator.push<bool>(
      context,
      SmoothPageRoute(
        child: const VaultPinScreen(mode: VaultPinMode.unlock),
      ),
    );
    if (verified != true || !mounted) return;
    final created = await Navigator.push<bool>(
      context,
      SmoothPageRoute(
        child: const VaultPinScreen(mode: VaultPinMode.create),
      ),
    );
    if (created == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vault PIN updated')),
      );
    }
  }

  void _openVideo(VideoFile vf, List<VideoFile> playlist) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PlayerScreen(
          filePath: vf.path,
          fileName: vf.name,
          folderVideos: playlist,
          initialIndex: playlist.indexOf(vf),
        ),
      ),
    );
  }

  void _showVaultOptions(VideoFile vf) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      showDragHandle: false,
      useSafeArea: true,
      isScrollControlled: true,
      builder: (_) => Container(
        margin: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: context.colors.surface,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
              child: Text(
                vf.name,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Divider(color: context.colors.border, height: 1),
            ListTile(
              leading: Icon(Icons.play_arrow_rounded, color: context.colors.textPrimary),
              title: const Text('Play'),
              onTap: () {
                Navigator.pop(context);
                final list = ref.read(vaultProvider);
                _openVideo(vf, list);
              },
            ),
            ListTile(
              leading: Icon(Icons.restore_rounded, color: context.colors.accent),
              title: const Text('Restore from Vault'),
              onTap: () async {
                Navigator.pop(context);
                await ref.read(vaultProvider.notifier).restoreVideo(vf);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Video restored successfully')),
                  );
                }
              },
            ),
            ListTile(
              leading: Icon(Icons.check_circle_outline_rounded,
                  color: context.colors.textPrimary),
              title: const Text('Select'),
              onTap: () {
                Navigator.pop(context);
                _enterSelectionMode(vf);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_rounded, color: Colors.redAccent),
              title: const Text('Delete permanently', style: TextStyle(color: Colors.redAccent)),
              onTap: () async {
                Navigator.pop(context);
                await ref.read(vaultProvider.notifier).deleteVideo(vf);
              },
            ),
            SizedBox(height: MediaQuery.of(context).padding.bottom + 12),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final videos = ref.watch(vaultProvider);

    return Scaffold(
      backgroundColor: context.colors.bg,
      appBar: AppBar(
        backgroundColor: context.colors.bg,
        scrolledUnderElevation: 0,
        title: Text(
          _selectionMode ? '${_selectedPaths.length} selected' : 'Secure Vault',
          style: TextStyle(
            color: context.colors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        leading: IconButton(
          icon: Icon(
            _selectionMode ? Icons.close_rounded : Icons.arrow_back_rounded,
            color: context.colors.textPrimary,
          ),
          onPressed: _selectionMode ? _exitSelectionMode : () => Navigator.pop(context),
        ),
        actions: [
          if (_selectionMode)
            IconButton(
              icon: Icon(Icons.select_all_rounded, color: context.colors.textPrimary),
              tooltip: 'Select all',
              onPressed: () => _selectAll(videos),
            )
          else ...[
            if (videos.isNotEmpty)
              IconButton(
                icon: Icon(Icons.checklist_rounded, color: context.colors.textPrimary),
                tooltip: 'Select',
                onPressed: () => _enterSelectionMode(null),
              ),
            IconButton(
              icon: Icon(Icons.lock_reset_rounded, color: context.colors.textPrimary),
              tooltip: 'Change vault PIN',
              onPressed: _changePin,
            ),
          ],
        ],
      ),
      body: videos.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.lock_rounded, size: 64, color: context.colors.textMuted),
                  const SizedBox(height: 16),
                  Text(
                    'Vault is empty',
                    style: TextStyle(color: context.colors.textSecondary, fontSize: 16),
                  ),
                ],
              ),
            )
          : ListView.builder(
              itemCount: videos.length,
              padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom + 20),
              itemBuilder: (context, index) {
                final vf = videos[index];
                return RepaintBoundary(
                  child: VideoCard(
                    vf: vf,
                    savedPos: null,
                    totalDur: null, // Durations could be fetched if needed
                    isNew: false,
                    selectionMode: _selectionMode,
                    isSelected: _selectedPaths.contains(vf.path),
                    onSelectToggle: () => _toggleSelection(vf.path),
                    onTap: () =>
                        _selectionMode ? _toggleSelection(vf.path) : _openVideo(vf, videos),
                    onLongPress: () =>
                        _selectionMode ? _toggleSelection(vf.path) : _showVaultOptions(vf),
                  ),
                );
              },
            ),
      bottomNavigationBar: _selectionMode
          ? _VaultSelectionBar(
              selectedCount: _selectedPaths.length,
              onRestore: _selectedPaths.isEmpty ? null : () => _restoreSelected(videos),
              onDelete: _selectedPaths.isEmpty ? null : () => _deleteSelected(videos),
            )
          : null,
    );
  }
}

/// Bottom bar shown in the vault's multi-select mode: Restore and Delete
/// permanently. Mirrors SelectionActionBar's layout (used for the regular
/// folder video list) but with vault-specific actions/labels.
class _VaultSelectionBar extends StatelessWidget {
  final int selectedCount;
  final VoidCallback? onRestore;
  final VoidCallback? onDelete;

  const _VaultSelectionBar({
    required this.selectedCount,
    required this.onRestore,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.colors.surface,
        border: Border(top: BorderSide(color: context.colors.divider)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: onRestore,
                  style: FilledButton.styleFrom(
                    backgroundColor: context.colors.accent,
                    foregroundColor: context.colors.bg,
                    disabledBackgroundColor: context.colors.divider,
                    disabledForegroundColor: context.colors.textMuted,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: const StadiumBorder(),
                  ),
                  icon: const Icon(Icons.restore_rounded, size: 20),
                  label: Text(
                    'Restore ($selectedCount)',
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  onPressed: onDelete,
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: context.colors.divider,
                    disabledForegroundColor: context.colors.textMuted,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: const StadiumBorder(),
                  ),
                  icon: const Icon(Icons.delete_outline_rounded, size: 20),
                  label: const Text(
                    'Delete',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
