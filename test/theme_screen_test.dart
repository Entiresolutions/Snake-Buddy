import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:snake_game/controllers/canvas_theme_controller.dart';
import 'package:snake_game/controllers/settings_controller.dart';
import 'package:snake_game/screens/theme_screen.dart';

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

  group('ThemeScreen responsive and interaction tests', () {
    for (final res in resolutions) {
      for (final scale in textScales) {
        testWidgets(
            'ThemeScreen renders at ${res.width}x${res.height} scale $scale without overflow',
            (tester) async {
          tester.view.physicalSize = res;
          tester.view.devicePixelRatio = 1.0;
          addTearDown(() => tester.view.resetPhysicalSize());

          final settings = SettingsController();
          await settings.load();
          final canvasThemes = CanvasThemeController();
          await canvasThemes.load();

          await tester.pumpWidget(
            MaterialApp(
              themeMode: ThemeMode.light,
              home: MediaQuery(
                data: MediaQueryData(
                  size: res,
                  textScaler: TextScaler.linear(scale),
                ),
                child: ThemeScreen(
                  settings: settings,
                  canvasThemes: canvasThemes,
                ),
              ),
            ),
          );

          await tester.pump();
          await tester.pump(const Duration(milliseconds: 200));

          expect(find.text('THEME'), findsOneWidget);
          expect(find.text('ACTIVE CANVAS'), findsOneWidget);
          expect(find.text('CANVAS COLLECTION'), findsOneWidget);
          expect(find.text('Fresh Meadow'), findsWidgets);
          expect(find.text('Ocean Breeze'), findsOneWidget);

          final exception = tester.takeException();
          if (exception != null) {
            FlutterError.dumpErrorToConsole(FlutterErrorDetails(exception: exception));
          }
          expect(exception, isNull);
        });
      }
    }

    testWidgets('Tapping an unlocked canvas selects it', (tester) async {
      final settings = SettingsController();
      await settings.load();
      final canvasThemes = CanvasThemeController();
      // Unlock ocean
      await canvasThemes.load(highScore: 20);

      await tester.pumpWidget(
        MaterialApp(
          themeMode: ThemeMode.light,
          home: ThemeScreen(
            settings: settings,
            canvasThemes: canvasThemes,
          ),
        ),
      );

      await tester.pump();
      expect(canvasThemes.selectedThemeId, 'meadow');

      // Tap Ocean Breeze card
      await tester.tap(find.text('Ocean Breeze'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(canvasThemes.selectedThemeId, 'ocean');
      expect(find.text('Ocean Breeze'), findsWidgets);
    });

    testWidgets(
        'Tapping a locked canvas triggers snackbar and remains unselected',
        (tester) async {
      final settings = SettingsController();
      await settings.load();
      final canvasThemes = CanvasThemeController();
      await canvasThemes.load(highScore: 0);

      await tester.pumpWidget(
        MaterialApp(
          themeMode: ThemeMode.light,
          home: ThemeScreen(
            settings: settings,
            canvasThemes: canvasThemes,
          ),
        ),
      );

      await tester.pump();
      expect(canvasThemes.selectedThemeId, 'meadow');

      // Midnight is locked (unlockScore 150)
      await tester.scrollUntilVisible(
        find.text('Midnight Neon'),
        100,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('Midnight Neon'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(canvasThemes.selectedThemeId, 'meadow');
      expect(find.text('Score 150 points to unlock Midnight Neon.'),
          findsOneWidget);
    });
  });
}
