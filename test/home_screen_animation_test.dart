import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:snake_game/controllers/canvas_theme_controller.dart';
import 'package:snake_game/controllers/settings_controller.dart';
import 'package:snake_game/screens/home_screen.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('HomeScreen has top-left Theme button and navigates to ThemeScreen',
      (tester) async {
    final settings = SettingsController();
    await settings.load();
    final canvasThemes = CanvasThemeController();
    await canvasThemes.load();

    await tester.pumpWidget(
      MaterialApp(
        themeMode: ThemeMode.light,
        home: HomeScreen(
          settings: settings,
          canvasThemes: canvasThemes,
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    // Verify THEME button exists at the top
    expect(find.text('THEME'), findsOneWidget);
    expect(find.byIcon(Icons.palette_rounded), findsOneWidget);

    // Tap THEME button
    await tester.tap(find.text('THEME'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Should navigate to ThemeScreen
    expect(find.text('CANVAS COLLECTION'), findsOneWidget);
    expect(find.text('ACTIVE CANVAS'), findsOneWidget);
  });

  testWidgets('HomeScreen snake animates and updates when canvas theme changes',
      (tester) async {
    final settings = SettingsController();
    await settings.load();
    final canvasThemes = CanvasThemeController();
    await canvasThemes.load(highScore: 50); // Unlocks Ocean

    await tester.pumpWidget(
      MaterialApp(
        themeMode: ThemeMode.light,
        home: HomeScreen(
          settings: settings,
          canvasThemes: canvasThemes,
        ),
      ),
    );

    await tester.pump();
    // Snake sprites: tail_left, body_horizontal, head_right
    expect(find.byType(Transform), findsWidgets);
    expect(find.byType(ColorFiltered), findsNothing); // meadow has no filter

    // Select Ocean Breeze
    await canvasThemes.selectTheme('ocean');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // Should now have ColorFiltered layer for the recolored snake
    expect(find.byType(ColorFiltered), findsOneWidget);

    // Advance time to verify animation ticks smoothly without throwing
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 500));
    expect(tester.takeException(), isNull);
  });

  testWidgets('HomeScreen UNLOCK ALL button unlocks all levels and themes for testing',
      (tester) async {
    final settings = SettingsController();
    await settings.load();
    final canvasThemes = CanvasThemeController();
    await canvasThemes.load();

    await tester.pumpWidget(
      MaterialApp(
        themeMode: ThemeMode.light,
        home: HomeScreen(
          settings: settings,
          canvasThemes: canvasThemes,
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    // Initially UNLOCK ALL button is present
    expect(find.text('UNLOCK ALL'), findsOneWidget);
    expect(find.text('1/30'), findsOneWidget);
    expect(canvasThemes.unlockedCount, 1);

    // Tap UNLOCK ALL
    await tester.tap(find.text('UNLOCK ALL'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Verifications:
    // 1. All themes unlocked
    expect(canvasThemes.unlockedCount, canvasThemes.totalCount);
    // 2. Levels chip shows 30/30
    expect(find.text('30/30'), findsOneWidget);
    // 3. Button changes state to UNLOCKED
    expect(find.text('UNLOCKED'), findsOneWidget);
    // 4. SnackBar is displayed
    expect(find.text('All 30 levels and all themes unlocked!'), findsOneWidget);
  });
}

