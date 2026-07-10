import 'dart:async';
import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:flutter_video_player/core/theme/app_theme.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_video_player/data/models/video_file.dart';
import 'package:flutter_video_player/data/models/video_folder.dart';
import 'package:flutter_video_player/presentation/providers/folders_provider.dart';
import 'package:flutter_video_player/presentation/providers/continue_watching_provider.dart';
import 'package:flutter_video_player/data/services/duration_cache_service.dart';
import 'package:flutter_video_player/data/services/position_service.dart';
import 'package:flutter_video_player/data/services/recent_files_service.dart';
import 'folder_videos_screen.dart';
import 'package:flutter_video_player/presentation/widgets/library/continue_watching_row.dart';
import 'package:flutter_video_player/presentation/widgets/library/empty_library.dart';
import 'package:flutter_video_player/presentation/widgets/library/folder_card.dart';
import 'package:flutter_video_player/presentation/widgets/library/library_header.dart';
import 'package:flutter_video_player/presentation/widgets/library/no_results.dart';
import 'package:flutter_video_player/presentation/widgets/library/permission_prompt.dart';
import 'package:flutter_video_player/presentation/widgets/library/scanning_screen.dart';
import 'package:flutter_video_player/presentation/widgets/library/search_video_row.dart';
import 'package:flutter_video_player/presentation/widgets/library/folder_resume.dart';
import 'package:flutter_video_player/presentation/widgets/common/smooth_page_route.dart';
import 'player_screen.dart';

class LibraryScreen extends ConsumerStatefulWidget {
  final void Function(VideoFile vf,
      {List<VideoFile> playlist, int index}) onOpenVideo;
  const LibraryScreen({super.key, required this.onOpenVideo});

  @override
  ConsumerState<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends ConsumerState<LibraryScreen>
    with AutomaticKeepAliveClientMixin, WidgetsBindingObserver {
  bool _permissionGranted = false;
  bool _checkingPermission = true;
  bool _awaitingStorageSettings = false;

  // Search
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';
  bool _searchOpen = false;
  // Debounce so a full library filter + rebuild doesn't run on every keystroke.
  Timer? _searchDebounce;

  // Memoized video-name search result — recomputed only when the query or the
  // folder list actually changes, not on every unrelated rebuild.
  List<({VideoFile video, VideoFolder folder})> _matchedCache = const [];
  String? _matchedForQuery;
  List<VideoFolder>? _matchedForFolders;

  final Map<String, FolderResume?> _folderResumes = {};

  // "Continue Watching" strip data: recents joined with saved resume points.
  List<ContinueWatchingItem> _continueWatching = const [];

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _searchCtrl.addListener(() {
      // Always restart the timer and read the live text when it fires — never
      // capture the text here, or a quick type-then-delete could leave a stale
      // pending change that applies a query the field no longer shows.
      _searchDebounce?.cancel();
      _searchDebounce = Timer(const Duration(milliseconds: 180), () {
        if (!mounted) return;
        final q = _searchCtrl.text.trim().toLowerCase();
        if (q != _searchQuery) setState(() => _searchQuery = q);
      });
    });
    _checkPermissionsAndLoad();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _searchDebounce?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState lifecycle) {
    if (lifecycle != AppLifecycleState.resumed) return;
    if (_permissionGranted) {
      ref.read(foldersProvider.notifier).load(forceScan: false);
      _loadContinueWatching();
    } else if (_awaitingStorageSettings) {
      _awaitingStorageSettings = false;
      _recheckPermissionsAfterSettings();
    }
  }

  // ── Permission helpers ────────────────────────────────────────────────────

  Future<void> _checkPermissionsAndLoad() async {
    // iOS sandboxes apps to their own container — there's no shared device
    // storage to scan and no Android-style storage permission. Videos are
    // opened via the file picker, so skip the permission flow and show the
    // (empty) library directly.
    if (!Platform.isAndroid) {
      if (!mounted) return;
      setState(() {
        _permissionGranted = true;
        _checkingPermission = false;
      });
      ref.read(foldersProvider.notifier).load(forceScan: false);
      _loadContinueWatching();
      return;
    }
    setState(() => _checkingPermission = true);
    await Permission.videos.request();
    if (!mounted) return;
    await Permission.storage.request();
    if (!mounted) return;
    await Permission.notification.request();
    if (!mounted) return;
    final manageStatus = await Permission.manageExternalStorage.status;
    if (!manageStatus.isGranted) {
      _awaitingStorageSettings = true;
      await Permission.manageExternalStorage.request();
      if (!mounted) return;
      _awaitingStorageSettings = false;
    }
    await _applyPermissionResult();
  }

  Future<void> _recheckPermissionsAfterSettings() async {
    if (_checkingPermission) return;
    final results = await Future.wait([
      Permission.manageExternalStorage.isGranted,
      Permission.storage.isGranted,
      Permission.videos.isGranted,
    ]);
    if (!mounted) return;
    if (results.any((g) => g) && !_permissionGranted) {
      setState(() => _permissionGranted = true);
      // FIX #PERM-SCAN: forceScan=true — user just granted storage permission
      // so there is no valid cache yet. Scan immediately instead of waiting
      // for the background snapshot check to figure that out.
      ref.read(foldersProvider.notifier).load(forceScan: true);
      _loadContinueWatching();
    }
  }

  Future<void> _applyPermissionResult() async {
    final results = await Future.wait([
      Permission.manageExternalStorage.isGranted,
      Permission.storage.isGranted,
      Permission.videos.isGranted,
    ]);
    if (!mounted) return;
    final granted = results.any((g) => g);
    setState(() {
      _permissionGranted = granted;
      _checkingPermission = false;
    });
    if (granted) {
      ref.read(foldersProvider.notifier).load(forceScan: false);
      _loadContinueWatching();
    }
  }

  // ── Continue Watching ──────────────────────────────────────────────────────

  /// Joins the recents list with saved resume points. Finished videos drop off
  /// automatically: PositionService clears the position near the end, so their
  /// load() returns null and they're skipped here.
  Future<void> _loadContinueWatching() async {
    final recents = await RecentFilesService.instance.getRecents();
    final toCheck = recents.take(20).toList();
    final positions = await Future.wait(
      toCheck.map((vf) => PositionService.instance.load(vf.path))
    );
    
    final items = <ContinueWatchingItem>[];
    for (var i = 0; i < toCheck.length; i++) {
      final vf = toCheck[i];
      final pos = positions[i];
      if (pos == null || pos <= Duration.zero) continue;
      final dur = vf.duration ??
          DurationCacheService.instance.getFromCacheSync(vf.path);
      items.add(
          ContinueWatchingItem(video: vf, position: pos, duration: dur));
      if (items.length >= 10) break;
    }
    if (!mounted) return;
    setState(() => _continueWatching = items);
  }

  /// Resumes a Continue Watching entry directly (no resume dialog). The
  /// video's folder — when it's in the library — becomes the playlist so
  /// next/previous and auto-play-next work as usual.
  Future<void> _openContinueWatching(ContinueWatchingItem item) async {
    final folders = ref.read(foldersProvider).folders;
    final dir = p.dirname(item.video.path);
    VideoFolder? folder;
    for (final f in folders) {
      if (f.path == dir) {
        folder = f;
        break;
      }
    }
    final playlist = folder?.videos ?? const <VideoFile>[];
    var index = -1;
    for (var i = 0; i < playlist.length; i++) {
      if (playlist[i].path == item.video.path) {
        index = i;
        break;
      }
    }

    await RecentFilesService.instance.addRecent(item.video); // bump to front
    if (!mounted) return;
    await Navigator.push(
      context,
      SmoothPageRoute(
        child: PlayerScreen(
          filePath: item.video.path,
          fileName: item.video.name,
          resumeFrom: item.position,
          folderVideos: playlist,
          initialIndex: index,
        ),
      ),
    );
    if (!mounted) return;
    _loadContinueWatching();
    // The folder's resume pill may be stale now — drop it so the lazy loader
    // refetches it on the next build.
    if (folder != null) {
      setState(() => _folderResumes.remove(folder!.path));
    }
  }

  Future<void> _confirmRemoveContinueWatching(
      ContinueWatchingItem item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Remove from Continue Watching?'),
        content: Text(
          '"${item.video.name}" will be removed from the row. The video and '
          'its resume point are kept.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await RecentFilesService.instance.removeRecent(item.video.path);
    _loadContinueWatching();
  }

  // ── Folder resume helpers ──────────────────────────────────────────────────

  /// FIX #OPT-6: Resume data is now loaded lazily per-folder when each item
  /// becomes visible in the list, rather than eagerly for the entire library
  /// up front.  For a library with 50 folders × 20 videos each, the old
  /// approach fired 1000 SharedPreferences reads before the user saw anything.
  /// Now each folder triggers its own load only once, on first render.
  void _ensureResumeLoaded(VideoFolder folder) {
    if (_folderResumes.containsKey(folder.path)) return;
    // Mark as "in progress" with a sentinel so we don't re-fire on every
    // build frame while the Future is still pending.
    _folderResumes[folder.path] = null;
    _findLastWatched(folder).then((resume) {
      if (mounted) setState(() => _folderResumes[folder.path] = resume);
    });
  }

  Future<FolderResume?> _findLastWatched(VideoFolder folder) async {
    final futures = folder.videos.map((vf) async {
      final pos = await PositionService.instance.load(vf.path);
      return (vf, pos);
    });
    final results = await Future.wait(futures);
    VideoFile? best;
    Duration? bestPos;
    for (final (vf, pos) in results) {
      if (pos != null && pos > Duration.zero) {
        if (best == null || vf.modified.isAfter(best.modified)) {
          best = vf;
          bestPos = pos;
        }
      }
    }
    return best != null ? FolderResume(best, bestPos!) : null;
  }

  void _openFolder(VideoFolder folder) {
    Navigator.push(
      context,
      SmoothPageRoute(child: FolderVideosScreen(folder: folder)),
    ).then((_) {
      if (mounted) {
        setState(() => _folderResumes.remove(folder.path));
        _findLastWatched(folder).then((r) {
          if (mounted) setState(() => _folderResumes[folder.path] = r);
        });
        _loadContinueWatching();
      }
    });
  }

  Future<void> _resumeFolder(VideoFolder folder, FolderResume resume) async {
    await RecentFilesService.instance.addRecent(resume.video);
    if (!mounted) return;
    await Navigator.push(
      context,
      SmoothPageRoute(
        child: PlayerScreen(
          filePath: resume.video.path,
          fileName: resume.video.name,
          resumeFrom: resume.position,
          folderVideos: folder.videos,
          initialIndex: folder.videos.indexOf(resume.video),
        ),
      ),
    );
    if (mounted) {
      setState(() => _folderResumes.remove(folder.path));
      _findLastWatched(folder).then((r) {
        if (mounted) setState(() => _folderResumes[folder.path] = r);
      });
      _loadContinueWatching();
    }
  }

  // ── Search helpers ─────────────────────────────────────────────────────────

  List<VideoFolder> _filtered(List<VideoFolder> folders) {
    if (_searchQuery.isEmpty) return folders;
    return folders
        .where((f) => f.name.toLowerCase().contains(_searchQuery))
        .toList();
  }

  /// Videos matching the query by filename, searched across every folder —
  /// not just the ones whose folder name also matches — so a video can be
  /// found without knowing which folder it lives in. Memoized so an unrelated
  /// rebuild (resume loaded, new-badge change, …) doesn't re-scan the whole
  /// library; recomputed only when the query or the folder list changes.
  List<({VideoFile video, VideoFolder folder})> _matchedVideos(
      List<VideoFolder> folders) {
    if (_searchQuery.isEmpty) return const [];
    if (_matchedForQuery == _searchQuery &&
        identical(_matchedForFolders, folders)) {
      return _matchedCache;
    }
    final out = <({VideoFile video, VideoFolder folder})>[];
    for (final folder in folders) {
      for (final v in folder.videos) {
        if (v.name.toLowerCase().contains(_searchQuery)) {
          out.add((video: v, folder: folder));
        }
      }
    }
    _matchedForQuery = _searchQuery;
    _matchedForFolders = folders;
    _matchedCache = out;
    return out;
  }

  void _toggleSearch() {
    _searchDebounce?.cancel();
    setState(() {
      _searchOpen = !_searchOpen;
      if (!_searchOpen) {
        _searchCtrl.clear();
        _searchQuery = '';
      }
    });
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    super.build(context);

    if (_checkingPermission) {
      return const Center(child: CircularProgressIndicator());
    }
    if (!_permissionGranted) {
      return PermissionPrompt(onRetry: _checkPermissionsAndLoad);
    }

    final (:folders, :isScanning, :fromCache, :storageRoots, :newPaths) =
        ref.watch(foldersProvider.select((s) => (
              folders: s.folders,
              isScanning: s.isScanning,
              fromCache: s.fromCache,
              storageRoots: s.storageRoots,
              newPaths: s.newPaths,
            )));
            
    final continueWatchingEnabled = ref.watch(continueWatchingEnabledProvider);

    if (isScanning && folders.isEmpty) {
      return Consumer(
        builder: (context, ref, _) {
          final progress =
              ref.watch(foldersProvider.select((s) => s.scanProgress));
          return ScanningScreen(
              progress: progress, storageCount: storageRoots.length);
        },
      );
    }
    if (!isScanning && folders.isEmpty) {
      return EmptyLibrary(
          onScan: () =>
              ref.read(foldersProvider.notifier).load(forceScan: true));
    }

    final allFolders = folders;
    final hasMultiStorage = storageRoots.length > 1;

    // _lastFoldersLoaded guard removed — resume data is now loaded lazily
    // inside itemBuilder via _ensureResumeLoaded().

    final displayFolders = _filtered(allFolders);
    // Video-name matches across the whole library, shown below any matching
    // folders so a video can be found without knowing which folder it's in.
    final matchedVideos = _matchedVideos(allFolders);
    final showVideoHeader =
        displayFolders.isNotEmpty && matchedVideos.isNotEmpty;
    final totalResults = displayFolders.length +
        (showVideoHeader ? 1 : 0) +
        matchedVideos.length;
    // Continue Watching strip: only outside of search, as the first list item.
    final showContinueWatching = continueWatchingEnabled &&
        _searchQuery.isEmpty && _continueWatching.isNotEmpty;
    final cwCount = showContinueWatching ? 1 : 0;

    return Column(
      children: [
        // ── Header ─────────────────────────────────────────────────────────
        LibraryHeader(
          folderCount: allFolders.length,
          filteredCount: _searchQuery.isNotEmpty ? displayFolders.length : null,
          storageCount: hasMultiStorage ? storageRoots.length : null,
          isScanning: isScanning,
          fromCache: fromCache,
          searchOpen: _searchOpen,
          searchCtrl: _searchCtrl,
          onToggleSearch: _toggleSearch,
          onRescan: isScanning
              ? null
              : () => ref.read(foldersProvider.notifier).load(forceScan: true),
        ),

        // ── Folder list with pull-to-refresh ────────────────────────────────
        Expanded(
          child: RefreshIndicator(
            onRefresh: () =>
                ref.read(foldersProvider.notifier).load(forceScan: true),
            color: context.colors.accent,
            backgroundColor: context.colors.surface,
            child: totalResults == 0
                ? NoResults(query: _searchQuery)
                : ListView.builder(
                    padding: EdgeInsets.fromLTRB(
                      16,
                      8,
                      16,
                      8 + MediaQuery.of(context).padding.bottom,
                    ),
                    itemCount: totalResults + cwCount,
                    itemBuilder: (_, i) {
                      if (showContinueWatching && i == 0) {
                        return ContinueWatchingRow(
                          items: _continueWatching,
                          onTap: _openContinueWatching,
                          onRemove: _confirmRemoveContinueWatching,
                        );
                      }
                      final j = i - cwCount;
                      if (j < displayFolders.length) {
                        final folder     = displayFolders[j];
                        // FIX #OPT-6: trigger resume load the first time this
                        // item scrolls into view rather than loading all at once.
                        _ensureResumeLoaded(folder);
                        final resume     = _folderResumes[folder.path];
                        final isExternal = hasMultiStorage &&
                            !folder.path.contains('/emulated/');
                        // newPaths already watched above — no extra select needed.
                        final isNew = newPaths.contains(folder.path);
                        return FolderCard(
                          key: ValueKey(folder.path),
                          folder: folder,
                          isExternal: isExternal,
                          isNew: isNew,
                          resumePosition: resume?.position,
                          onTap: () => _openFolder(folder),
                          onResume: resume != null
                              ? () => _resumeFolder(folder, resume)
                              : null,
                        );
                      }

                      var idx = j - displayFolders.length;
                      if (showVideoHeader) {
                        if (idx == 0) {
                          return Padding(
                            padding: const EdgeInsets.fromLTRB(4, 4, 4, 8),
                            child: Text(
                              'Videos · ${matchedVideos.length}',
                              style: context.textStyles.label,
                            ),
                          );
                        }
                        idx -= 1;
                      }
                      final match = matchedVideos[idx];
                      return SearchVideoRow(
                        video: match.video,
                        folderName: match.folder.name,
                        onTap: () => widget.onOpenVideo(
                          match.video,
                          playlist: match.folder.videos,
                          index: match.folder.videos.indexOf(match.video),
                        ),
                      );
                    },
                  ),
          ),
        ),
      ],
    );
  }
}

