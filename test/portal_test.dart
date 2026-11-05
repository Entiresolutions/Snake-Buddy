import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:snake_game/controllers/campaign_controller.dart';
import 'package:snake_game/controllers/canvas_theme_controller.dart';
import 'package:snake_game/controllers/settings_controller.dart';
import 'package:snake_game/ui/screens/snake/snake_play_screen.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('Level 15 snake enters portal and teleports without crash', (tester) async {
    final settings = SettingsController();
    await settings.load();

    final canvasThemes = CanvasThemeController();
    await canvasThemes.load();

    final campaign = CampaignController();
    await campaign.load();

    await tester.pumpWidget(
      MaterialApp(
        home: SnakePlayScreen(
          settings: settings,
          canvasThemes: canvasThemes,
          campaign: campaign,
          initialLevelId: 15,
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    // Tap to dismiss intro if showing
    final introFinder = find.text('GOAL: Score 100 points');
    if (introFinder.evaluate().isNotEmpty) {
      await tester.tap(introFinder);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
    }

    final dynamic state = tester.state(find.byType(SnakePlayScreen));

    // Snake start: [7, 9], [7, 10], [7, 11] facing up
    // Move up to row 2 (at [7, 2])
    for (int i = 0; i < 7; i++) {
      state.stepLogicForTest();
      await tester.pump();
    }

    // Turn left towards Portal A at [3, 2]
    state.setDirectionForTest('left');
    for (int i = 0; i < 4; i++) {
      state.stepLogicForTest();
      await tester.pump();
    }

    // Head is now at Portal A!
    // Step several more times so body and tail pass through
    for (int i = 0; i < 10; i++) {
      state.stepLogicForTest();
      await tester.pump();
    }

    expect(tester.takeException(), isNull);
  });
}
