import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_video_player/core/theme/app_theme.dart';
import 'package:flutter_video_player/data/models/video_file.dart';
import 'package:flutter_video_player/presentation/widgets/common/resume_dialog.dart';
import 'package:flutter_video_player/presentation/widgets/library/scan_mode_sheet.dart';
import 'package:flutter_video_player/presentation/providers/theme_provider.dart';
import 'package:flutter_video_player/presentation/providers/player_provider.dart';
import 'package:flutter_video_player/presentation/providers/scan_mode_provider.dart';
import 'package:flutter_video_player/presentation/providers/folders_provider.dart';
import 'package:flutter_video_player/presentation/widgets/library/menu_sheet.dart';
import 'package:flutter_video_player/data/services/media_session_service.dart';
import 'package:flutter_video_player/data/services/open_file_service.dart';
import 'package:flutter_video_player/data/services/position_service.dart';
import 'package:flutter_video_player/data/services/recent_files_service.dart';
import 'library_screen.dart';
import 'player_screen.dart';
import 'package:flutter_video_player/presentation/widgets/common/smooth_page_route.dart';

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
    final themeIcon = ref.watch(themeProvider.select((m) => m == ThemeMode.light 
        ? Icons.light_mode_rounded 
        : (m == ThemeMode.dark ? Icons.dark_mode_rounded : Icons.brightness_auto_rounded)));

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
            IconButton(
              icon: const Icon(Icons.more_vert_rounded),
              tooltip: 'More options',
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  useSafeArea: true,
                  isScrollControlled: true,
                  showDragHandle: false,
                  backgroundColor: Colors.transparent,
                  builder: (_) => MenuSheet(
                    onOpenFile: () => _pickAndOpenVideo(context),
                  ),
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
