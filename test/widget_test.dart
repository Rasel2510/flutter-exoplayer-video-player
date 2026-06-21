import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_video_player/app.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  testWidgets('App loads smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: VideoPlayerApp()));
    expect(find.text('Videos'), findsOneWidget);
  });
}
