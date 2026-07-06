import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import '../core/theme/app_theme.dart';
import '../models/video_file.dart';
import '../presentation/widgets/resume_dialog.dart';
import '../presentation/widgets/library/scan_mode_sheet/scan_mode_sheet.dart';
import '../presentation/providers/theme_provider.dart';
import '../presentation/providers/player_provider.dart';
import '../presentation/providers/scan_mode_provider.dart';
import '../presentation/providers/folders_provider.dart';
import '../presentation/providers/continue_watching_provider.dart';
import '../services/media_session_service.dart';
import '../services/open_file_service.dart';
import '../services/position_service.dart';
import '../services/recent_files_service.dart';
import 'library_screen.dart';
import 'player_screen.dart';
import '../presentation/widgets/smooth_page_route.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // Videos opened from outside the app ("Open with" / VIEW intents).
    OpenFileService.setHandler(_openExternal);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final path = await OpenFileService.getInitialFile();
      if (path != null) _openExternal(path);
    });
  }

  void _openExternal(String path) {
    if (!mounted) return;
    final name = path.split('/').last.split('?').first;
    _openVideo(
      context,
      VideoFile(path: path, name: name, size: 0, modified: DateTime.now()),
    );
  }

  Future<void> _pickAndOpenVideo(BuildContext context) async {
    final result = await FilePicker.platform.pickFiles(type: FileType.video);
    if (result == null || result.files.single.path == null) return;
    final f = result.files.single;
    final vf = VideoFile(
      path: f.path!,
      name: f.name,
      size: f.size,
      modified: DateTime.now(),
    );
    await RecentFilesService.instance.addRecent(vf);
    if (!context.mounted) return;
    _openVideo(context, vf);
  }

  void _showScanModeSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      showDragHandle: false,
      backgroundColor: Colors.transparent,
      builder: (_) => ScanModeSheet(
        selected: ref.read(scanModeProvider),
        onSelect: (mode) async {
          if (mode == ref.read(scanModeProvider)) return;
          await ref.read(scanModeProvider.notifier).set(mode);
          // Re-scan from scratch with the newly chosen method.
          await ref.read(foldersProvider.notifier).rescanForModeChange();
        },
      ),
    );
  }

  Future<void> _openVideo(
    BuildContext context,
    VideoFile vf, {
    List<VideoFile> playlist = const [],
    int index = -1,
  }) async {
    final savedPos = await PositionService.instance.load(vf.path);
    Duration? resumeFrom;
    if (savedPos != null && savedPos > Duration.zero && context.mounted) {
      // FIX #3: use shared ResumeDialog
      resumeFrom = await ResumeDialog.show(context, savedPos);
      if (resumeFrom == null) return;
    }
    if (!context.mounted) return;
    Navigator.push(
      context,
      SmoothPageRoute(
        child: PlayerScreen(
          filePath: vf.path,
          fileName: vf.name,
          resumeFrom: resumeFrom,
          // When opened from a search result we pass the video's folder as the
          // playlist so next/previous and auto-play-next work just like opening
          // it from inside its folder.
          folderVideos: playlist,
          initialIndex: index,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeProvider);
    final themeIcon = themeMode == ThemeMode.light 
        ? Icons.light_mode_rounded 
        : (themeMode == ThemeMode.dark ? Icons.dark_mode_rounded : Icons.brightness_auto_rounded);

    return PopScope(
      // We handle the root back press ourselves so audio mode can background
      // the app (keeping playback + lock-screen controls alive) instead of
      // finishing the activity.
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        if (ref.read(playerProvider.notifier).audioMode) {
          await MediaSessionService.moveTaskToBack();
        } else {
          await SystemNavigator.pop();
        }
      },
      child: Scaffold(
        backgroundColor: context.colors.bg,
        appBar: AppBar(
          title: Row(
            children: [
              Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  color: context.colors.accent,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 10),
              const Text('Videos'),
            ],
          ),
          actions: [
            // MediaStore / hybrid / file-scanner only matter on Android.
            if (Platform.isAndroid)
              IconButton(
                icon: const Icon(Icons.travel_explore_rounded),
                tooltip: 'Library scan mode',
                onPressed: () => _showScanModeSheet(context, ref),
              ),
            IconButton(
              icon: Icon(themeIcon),
              tooltip: 'Toggle Theme',
              onPressed: () => ref.read(themeProvider.notifier).toggleTheme(),
            ),
            Consumer(
              builder: (context, ref, _) {
                final cwEnabled = ref.watch(continueWatchingEnabledProvider);
                return PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert_rounded),
                  tooltip: 'More options',
                  onSelected: (value) {
                    if (value == 'open_file') {
                      _pickAndOpenVideo(context);
                    } else if (value == 'continue_watching') {
                      ref.read(continueWatchingEnabledProvider.notifier).toggle();
                      ScaffoldMessenger.of(context).clearSnackBars();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            !cwEnabled
                                ? 'Continue Watching row shown'
                                : 'Continue Watching row hidden',
                          ),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem<String>(
                      value: 'open_file',
                      child: Row(
                        children: [
                          Icon(Icons.add_rounded, size: 20),
                          SizedBox(width: 12),
                          Text('Open file...'),
                        ],
                      ),
                    ),
                    CheckedPopupMenuItem<String>(
                      value: 'continue_watching',
                      checked: cwEnabled,
                      child: const Text('Show Continue Watching'),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
        body: LibraryScreen(
          onOpenVideo: (vf, {playlist = const [], index = -1}) =>
              _openVideo(context, vf, playlist: playlist, index: index),
        ),
      ),
    );
  }
}
