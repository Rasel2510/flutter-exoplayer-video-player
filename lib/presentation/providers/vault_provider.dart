import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_video_player/data/models/video_file.dart';
import 'package:flutter_video_player/data/services/vault_service.dart';
import 'folders_provider.dart';

final vaultProvider = StateNotifierProvider<VaultNotifier, List<VideoFile>>((ref) {
  return VaultNotifier(ref);
});

class VaultNotifier extends StateNotifier<List<VideoFile>> {
  final Ref _ref;

  // No eager load() in the constructor — VaultScreen already triggers one on
  // mount, so opening the vault previously stat'd every hidden file twice.
  VaultNotifier(this._ref) : super([]);

  bool _loading = false;

  Future<void> load() async {
    // Coalesce concurrent callers (constructor removed, but addVideo/restore/
    // delete all call load() too) so a burst of actions doesn't stack up
    // redundant full-vault rescans.
    if (_loading) return;
    _loading = true;
    try {
      final videos = await VaultService.instance.getVaultVideos();
      if (mounted) state = videos;
    } finally {
      _loading = false;
    }
  }

  Future<bool> authenticate() async {
    return await VaultService.instance.authenticate();
  }

  Future<void> addVideo(VideoFile video) async {
    final vaultVideo = await VaultService.instance.moveToVault(video);
    if (vaultVideo != null) {
      await load();
    }
  }

  Future<void> addVideos(List<VideoFile> videos) async {
    await VaultService.instance.moveManyToVault(videos);
    await load();
  }

  Future<void> restoreVideo(VideoFile video) async {
    final success = await VaultService.instance.restoreFromVault(video);
    if (success) {
      await load();
      await _resyncLibrary();
    }
  }

  Future<void> restoreVideos(List<VideoFile> videos) async {
    final restored = await VaultService.instance.restoreManyFromVault(videos);
    await load();
    if (restored.isNotEmpty) await _resyncLibrary();
  }

  Future<void> deleteVideo(VideoFile video) async {
    await VaultService.instance.deleteFromVault(video);
    await load();
  }

  Future<void> deleteVideos(List<VideoFile> videos) async {
    await VaultService.instance.deleteManyFromVault(videos);
    await load();
  }

  /// A restored file reappears at its original on-disk path, but the library
  /// list (foldersProvider) has no idea — moving a video INTO the vault does
  /// surgically remove it from that state, but there's no equivalent surgical
  /// "insert this back into its folder" op, so a full rescan is the correct
  /// (if heavier) way to bring it back into view. Restoring is a deliberate,
  /// infrequent action, so the rescan cost is acceptable here.
  Future<void> _resyncLibrary() async {
    await _ref.read(foldersProvider.notifier).load(forceScan: true);
  }
}
