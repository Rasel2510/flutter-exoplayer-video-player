import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme/app_theme.dart';
import '../models/video_file.dart';
import '../presentation/providers/vault_provider.dart';
import '../presentation/widgets/folder_videos/video_card.dart';
import '../presentation/widgets/smooth_page_route.dart';
import '../presentation/widgets/vault/vault_app_bar.dart';
import '../presentation/widgets/vault/vault_auto_lock_sheet.dart';
import '../presentation/widgets/vault/vault_menu_sheet.dart';
import '../presentation/widgets/vault/vault_options_sheet.dart';
import '../presentation/widgets/vault/vault_selection_bar.dart';
import '../services/secure_screen_guard.dart';
import '../services/vault_settings_service.dart';
import 'player_screen.dart';
import 'vault_pin_screen.dart';

class VaultScreen extends ConsumerStatefulWidget {
  const VaultScreen({super.key});

  @override
  ConsumerState<VaultScreen> createState() => _VaultScreenState();
}

class _VaultScreenState extends ConsumerState<VaultScreen>
    with WidgetsBindingObserver {
  bool _selectionMode = false;
  final Set<String> _selectedPaths = {};

  // Set when the app is backgrounded while this screen is showing; compared
  // against the configured auto-lock duration on resume. Null means we
  // haven't been backgrounded since the last check.
  DateTime? _backgroundedAt;
  int _autoLockRetries = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    SecureScreenGuard.activate();
    // Refresh vault contents when entering
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(vaultProvider.notifier).load();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    SecureScreenGuard.deactivate();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      if (_backgroundedAt == null) {
        _backgroundedAt = DateTime.now();
        _autoLockRetries = 0;
      }
    } else if (state == AppLifecycleState.resumed) {
      _checkAutoLock();
    }
  }

  // Re-locks the vault (by popping back to wherever it was opened from) if
  // the app was backgrounded at least as long as the configured auto-lock
  // duration. Only pops while this screen is the visible/top route — if a
  // dialog or bottom sheet (e.g. the delete confirmation) is on top, popping
  // would dismiss that instead of locking the vault, so we retry briefly
  // rather than silently dropping the lock for this cycle. Also leaves the
  // screen alone entirely if the user drilled into a video from the vault
  // and backgrounded there instead — we don't chase across routes to avoid
  // popping the wrong screen.
  Future<void> _checkAutoLock() async {
    final backgroundedAt = _backgroundedAt;
    if (backgroundedAt == null || !mounted) return;
    final autoLockSeconds =
        await VaultSettingsService.instance.getAutoLockSeconds();
    if (!mounted) return;
    if (autoLockSeconds < 0) {
      _backgroundedAt = null;
      return; // "Never"
    }
    final elapsed = DateTime.now().difference(backgroundedAt);
    if (elapsed.inSeconds < autoLockSeconds) {
      _backgroundedAt = null;
      return;
    }
    if (ModalRoute.of(context)?.isCurrent == true) {
      _backgroundedAt = null;
      Navigator.of(context).pop();
      return;
    }
    if (_autoLockRetries++ < 10) {
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) _checkAutoLock();
      });
    } else {
      _backgroundedAt = null;
    }
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

  void _showVaultMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      showDragHandle: false,
      useSafeArea: true,
      isScrollControlled: true,
      builder: (_) => VaultMenuSheet(
        onChangePin: () {
          Navigator.pop(context);
          _changePin();
        },
        onAutoLockTimer: () {
          Navigator.pop(context);
          _showAutoLockSheet();
        },
      ),
    );
  }

  Future<void> _showAutoLockSheet() async {
    final currentSeconds = await VaultSettingsService.instance.getAutoLockSeconds();
    if (!mounted) return;
    final chosen = await showModalBottomSheet<int>(
      context: context,
      backgroundColor: Colors.transparent,
      showDragHandle: false,
      useSafeArea: true,
      isScrollControlled: true,
      builder: (_) => VaultAutoLockSheet(currentSeconds: currentSeconds),
    );
    if (chosen == null || chosen == currentSeconds) return;
    await VaultSettingsService.instance.setAutoLockSeconds(chosen);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Auto-lock set to ${formatAutoLockSeconds(chosen).toLowerCase()}'),
      ),
    );
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
      builder: (_) => VaultOptionsSheet(
        vf: vf,
        onPlay: () {
          Navigator.pop(context);
          final list = ref.read(vaultProvider);
          _openVideo(vf, list);
        },
        onRestore: () async {
          Navigator.pop(context);
          await ref.read(vaultProvider.notifier).restoreVideo(vf);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Video restored successfully')),
            );
          }
        },
        onSelect: () {
          Navigator.pop(context);
          _enterSelectionMode(vf);
        },
        onDelete: () async {
          Navigator.pop(context);
          await ref.read(vaultProvider.notifier).deleteVideo(vf);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final videos = ref.watch(vaultProvider);

    return Scaffold(
      backgroundColor: context.colors.bg,
      appBar: VaultAppBar(
        selectionMode: _selectionMode,
        selectedCount: _selectedPaths.length,
        hasVideos: videos.isNotEmpty,
        onBack: () => Navigator.pop(context),
        onExitSelection: _exitSelectionMode,
        onSelectAll: () => _selectAll(videos),
        onEnterSelection: () => _enterSelectionMode(null),
        onMenu: _showVaultMenu,
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
          ? VaultSelectionBar(
              selectedCount: _selectedPaths.length,
              onRestore: _selectedPaths.isEmpty ? null : () => _restoreSelected(videos),
              onDelete: _selectedPaths.isEmpty ? null : () => _deleteSelected(videos),
            )
          : null,
    );
  }
}
