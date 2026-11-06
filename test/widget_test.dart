import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:snake_game/controllers/settings_controller.dart';
import 'package:snake_game/main.dart';
import 'package:snake_game/screens/splash_screen.dart';

void main() {
  testWidgets('SnakeApp smoke test', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final settings = SettingsController();
    await settings.load();
    await tester.pumpWidget(
      SnakeApp(
        settings: settings,
        home: SplashScreen(settings: settings),
      ),
    );
    expect(find.byType(SnakeApp), findsOneWidget);
    expect(find.text('Loading...'), findsOneWidget);
    for (var i = 0; i < 32; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    await tester
        .runAsync(() => Future<void>.delayed(const Duration(seconds: 3)));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('PLAY'), findsOneWidget);

    await tester.tap(find.text('SETTINGS'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Show grid lines'), findsOneWidget);
    await tester.pageBack();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    await tester.tap(find.text('PLAY'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('SELECT LEVEL'), findsOneWidget);

    // Tap level 1 tile
    await tester.tap(find.byKey(const ValueKey('level_tile_1')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('SNAKE'), findsOneWidget);

    // Dismiss intro card to start game
    await tester.tap(find.text('Tap anywhere to start'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byTooltip('Pause'), findsOneWidget);
    expect(find.text('Start'), findsNothing);
  });
}
