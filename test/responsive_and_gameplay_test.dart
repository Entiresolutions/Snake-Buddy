import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:snake_game/controllers/canvas_theme_controller.dart';
import 'package:snake_game/controllers/settings_controller.dart';
import 'package:snake_game/screens/home_screen.dart';
import 'package:snake_game/screens/settings_screen.dart';
import 'package:snake_game/ui/screens/snake/snake_play_screen.dart';
import 'package:snake_game/widgets/dialogs/game_complete_dialog.dart';
import 'package:snake_game/widgets/dialogs/game_over_dialog.dart';
import 'package:snake_game/widgets/dialogs/level_complete_dialog.dart';

void main() {
  const resolutions = [
    Size(320, 568),
    Size(360, 640),
    Size(375, 667),
    Size(390, 844),
    Size(412, 915),
    Size(430, 932),
    Size(844, 390), // landscape
    Size(768, 1024), // tablet portrait
    Size(1024, 768), // tablet landscape
  ];

  const textScales = [1.0, 1.3];

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Responsive screen layout tests (Zero RenderFlex overflows)', () {
    for (final res in resolutions) {
      for (final scale in textScales) {
        testWidgets(
            'Home & Settings render at ${res.width}x${res.height} scale $scale',
            (tester) async {
          tester.view.physicalSize = res;
          tester.view.devicePixelRatio = 1.0;
          addTearDown(() => tester.view.resetPhysicalSize());

          final settings = SettingsController();
          await settings.load();

          // Test Home Screen
          await tester.pumpWidget(
            MaterialApp(
              themeMode: ThemeMode.light,
              home: MediaQuery(
                data: MediaQueryData(
                  size: res,
                  textScaler: TextScaler.linear(scale),
                ),
                child: HomeScreen(settings: settings),
              ),
            ),
          );

          await tester.pump();
          await tester.pump(const Duration(milliseconds: 200));
          expect(find.text('PLAY'), findsOneWidget);
          expect(find.text('SETTINGS'), findsOneWidget);
          final errHome = tester.takeException();
          if (errHome != null) {
            // ignore: avoid_print
            print('DEBUG HOME ERROR: $errHome');
          }
          expect(errHome, isNull);

          // Test Settings Screen
          await tester.pumpWidget(
            MaterialApp(
              themeMode: ThemeMode.light,
              home: MediaQuery(
                data: MediaQueryData(
                  size: res,
                  textScaler: TextScaler.linear(scale),
                ),
                child: SettingsScreen(settings: settings),
              ),
            ),
          );

          await tester.pump();
          await tester.pump(const Duration(milliseconds: 200));
          expect(find.text('SETTINGS'), findsOneWidget);
          expect(find.text('Theme'), findsOneWidget);
          await tester.scrollUntilVisible(find.text('Difficulty'), 50.0);
          expect(find.text('Difficulty'), findsOneWidget);
          await tester.scrollUntilVisible(find.text('Control Type'), 50.0);
          expect(find.text('Control Type'), findsOneWidget);
          expect(tester.takeException(), isNull);
        });

        testWidgets(
            'Game screen (Swipe & Buttons) renders at ${res.width}x${res.height} scale $scale',
            (tester) async {
          tester.view.physicalSize = res;
          tester.view.devicePixelRatio = 1.0;
          addTearDown(() => tester.view.resetPhysicalSize());

          final settings = SettingsController();
          await settings.load();

          // 1. Swipe mode
          await settings.setControls(ControlType.swipe);
          await tester.pumpWidget(
            MaterialApp(
              themeMode: ThemeMode.light,
              home: MediaQuery(
                data: MediaQueryData(
                  size: res,
                  textScaler: TextScaler.linear(scale),
                ),
                child: SnakePlayScreen(settings: settings),
              ),
            ),
          );

          await tester.pump();
          await tester.pump(const Duration(milliseconds: 200));
          expect(find.text('SNAKE'), findsOneWidget);
          expect(find.text('SCORE'), findsOneWidget);
          expect(find.text('BEST'), findsOneWidget);
          final errGameSwipe = tester.takeException();
          if (errGameSwipe != null) {
            // ignore: avoid_print
            print('DEBUG GAME SWIPE ERROR: $errGameSwipe');
          }
          expect(errGameSwipe, isNull);

          // 2. Button controls (D-Pad) mode
          await settings.setControls(ControlType.buttons);
          await tester.pumpWidget(
            MaterialApp(
              themeMode: ThemeMode.light,
              home: MediaQuery(
                data: MediaQueryData(
                  size: res,
                  textScaler: TextScaler.linear(scale),
                ),
                child: SnakePlayScreen(settings: settings),
              ),
            ),
          );

          await tester.pump();
          await tester.pump(const Duration(milliseconds: 200));
          expect(find.bySemanticsLabel('Move Up'), findsOneWidget);
          expect(find.bySemanticsLabel('Move Down'), findsOneWidget);
          expect(find.bySemanticsLabel('Move Left'), findsOneWidget);
          expect(find.bySemanticsLabel('Move Right'), findsOneWidget);
          final errGameButtons = tester.takeException();
          if (errGameButtons != null) {
            // ignore: avoid_print
            print('DEBUG GAME BUTTONS ERROR: $errGameButtons');
          }
          expect(errGameButtons, isNull);
        });
      }
    }

    testWidgets('GameOverDialog, LevelCompleteDialog, GameCompleteDialog render on narrow screens without overflow',
        (tester) async {
      final testSizes = [
        const Size(320, 568),
        const Size(360, 640),
        const Size(375, 667),
        const Size(390, 844),
      ];

      final canvasThemes = CanvasThemeController();
      await canvasThemes.load();

      for (final sz in testSizes) {
        for (final scale in [1.0, 1.3]) {
          tester.view.physicalSize = sz;
          tester.view.devicePixelRatio = 1.0;

          // 1. GameOverDialog
          await tester.pumpWidget(
            MaterialApp(
              home: MediaQuery(
                data: MediaQueryData(
                  size: sz,
                  textScaler: TextScaler.linear(scale),
                ),
                child: Scaffold(
                  body: GameOverDialog(
                    levelId: 7,
                    levelScore: 0,
                    runScore: 0,
                    bestRunScore: 3,
                    chancesRemaining: 2,
                    isNewBest: false,
                    unlockedThemes: const [],
                    canvasThemes: canvasThemes,
                    onSecondChance: () {},
                    onRetry: () {},
                    onLevelSelect: () {},
                    onHome: () {},
                  ),
                ),
              ),
            ),
          );
          await tester.pump();
          expect(find.text('GAME OVER'), findsOneWidget);
          expect(find.text('Level 7'), findsOneWidget);
          expect(find.text('0/100'), findsOneWidget);
          expect(tester.takeException(), isNull);

          // 2. LevelCompleteDialog
          await tester.pumpWidget(
            MaterialApp(
              home: MediaQuery(
                data: MediaQueryData(
                  size: sz,
                  textScaler: TextScaler.linear(scale),
                ),
                child: Scaffold(
                  body: LevelCompleteDialog(
                    levelId: 7,
                    levelScore: 104,
                    runScore: 240,
                    bestRunScore: 350,
                    earnedStars: 3,
                    unlockedThemes: const [],
                    canvasThemes: canvasThemes,
                    onNextLevel: () {},
                    onReplay: () {},
                    onLevelSelect: () {},
                  ),
                ),
              ),
            ),
          );
          await tester.pump();
          expect(find.text('LEVEL 7 CLEARED!'), findsOneWidget);
          expect(tester.takeException(), isNull);

          // 3. GameCompleteDialog
          await tester.pumpWidget(
            MaterialApp(
              home: MediaQuery(
                data: MediaQueryData(
                  size: sz,
                  textScaler: TextScaler.linear(scale),
                ),
                child: Scaffold(
                  body: GameCompleteDialog(
                    runScore: 3200,
                    bestRunScore: 3200,
                    totalStars: 90,
                    onPlayAgain: () {},
                    onLevelSelect: () {},
                    onHome: () {},
                  ),
                ),
              ),
            ),
          );
          await tester.pump();
          expect(find.text('YOU WIN!'), findsOneWidget);
          expect(tester.takeException(), isNull);
        }
      }
      tester.view.resetPhysicalSize();
    });
  });

  group('Gameplay & Mechanics Verification', () {
    testWidgets('Pause dialog, Game Over dialog, High score persistence',
        (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final settings = SettingsController();
      await settings.load();

      await tester.pumpWidget(
        MaterialApp(
          themeMode: ThemeMode.light,
          home: SnakePlayScreen(settings: settings),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Tap Pause
      await tester.tap(find.byTooltip('Pause'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Game Paused'), findsOneWidget);
      expect(find.text('RESUME'), findsOneWidget);
      expect(find.text('HOME'), findsOneWidget);

      // Tap Resume
      await tester.tap(find.text('RESUME'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Game Paused'), findsNothing);

      // Verify difficulty changes live
      expect(settings.tickDuration, const Duration(milliseconds: 240));
      await settings.setDifficulty(GameDifficulty.hard);
      expect(settings.tickDuration, const Duration(milliseconds: 160));
      await settings.setDifficulty(GameDifficulty.easy);
      expect(settings.tickDuration, const Duration(milliseconds: 300));

      // Verify high score recording
      await settings.recordHighScore(42);
      expect(settings.highScore, 42);
      await settings.resetHighScore();
      expect(settings.highScore, 0);

      // Verify no restart button on play screen
      expect(find.byTooltip('Restart'), findsNothing);
    });

    testWidgets('Settings screen does not contain DATA tab or Reset high score',
        (tester) async {
      final settings = SettingsController();
      await settings.load();

      await tester.pumpWidget(
        MaterialApp(
          themeMode: ThemeMode.light,
          home: SettingsScreen(settings: settings),
        ),
      );

      await tester.pump();
      expect(find.text('DATA'), findsNothing);
      expect(find.text('Reset high score'), findsNothing);
    });
  });
}
