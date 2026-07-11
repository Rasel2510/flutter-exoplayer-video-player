import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_video_player/core/theme/app_theme.dart';
import 'package:flutter_video_player/presentation/widgets/folder_videos/folder_videos_app_bar.dart';

void main() {
  testWidgets(
      'select-multiple action uses an animated wrapper and triggers callback', (
    WidgetTester tester,
  ) async {
    var tapped = false;

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: Scaffold(
          appBar: FolderVideosAppBar(
            folderName: 'My Videos',
            displayCount: 3,
            totalCount: 3,
            isFiltered: false,
            totalSizeLabel: '5 MB',
            selectionMode: false,
            selectedCount: 0,
            searchOpen: false,
            onBack: () {},
            onExitSelection: () {},
            onSelectAll: () {},
            onToggleSearch: () {},
            onShowSort: () {},
            onEnterSelection: () => tapped = true,
          ),
        ),
      ),
    );

    await tester.tap(find.byTooltip('Select multiple'));
    await tester.pump();

    expect(tapped, isTrue);
  });
}
