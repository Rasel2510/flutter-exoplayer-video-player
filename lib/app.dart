import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/theme/app_theme.dart';
import 'presentation/providers/theme_provider.dart';
import 'presentation/widgets/common/thumbnail_widget.dart';
import 'presentation/widgets/player/mini_player/mini_player_overlay.dart';
import 'presentation/screens/home_screen.dart';

final appNavigatorKey = GlobalKey<NavigatorState>();

class VideoPlayerApp extends ConsumerWidget {
  const VideoPlayerApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);

    return MaterialApp(
      navigatorKey: appNavigatorKey,
      title: 'Ayesha',
      debugShowCheckedModeBanner: false,
      themeMode: themeMode,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      builder: (context, child) => MiniPlayerOverlay(child: child!),
      // FIX #OPT-8: ShimmerScope provides a single shared AnimationController
      // to all VideoThumbnailWidget instances.  Without this wrapper every
      // loading thumbnail would spin up its own controller.
      home: const ShimmerScope(child: HomeScreen()),
    );
  }
}

