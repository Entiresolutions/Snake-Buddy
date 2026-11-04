import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:snake_game/controllers/canvas_theme_controller.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('CanvasThemeController unit tests', () {
    test('Only meadow unlocked on fresh install', () async {
      final controller = CanvasThemeController();
      await controller.load();

      expect(controller.selectedThemeId, 'meadow');
      expect(controller.unlockedIds, {'meadow'});
      expect(controller.isUnlocked('meadow'), isTrue);
      expect(controller.isUnlocked('ocean'), isFalse);
      expect(controller.unlockedCount, 1);
    });

    test('Thresholds unlock correctly at exact boundary (14 vs 15 points)',
        () async {
      final controller = CanvasThemeController();
      await controller.load();

      // Score 14 should NOT unlock Ocean (unlockScore: 15)
      final unlockedAt14 = controller.checkUnlock(14);
      expect(unlockedAt14, isEmpty);
      expect(controller.isUnlocked('ocean'), isFalse);

      // Score 15 should unlock Ocean
      final unlockedAt15 = controller.checkUnlock(15);
      expect(unlockedAt15.length, 1);
      expect(unlockedAt15.first.id, 'ocean');
      expect(controller.isUnlocked('ocean'), isTrue);
      expect(controller.unlockedIds.contains('ocean'), isTrue);
    });

    test('Unlocks persist across loads', () async {
      final controller1 = CanvasThemeController();
      await controller1.load();
      controller1.checkUnlock(35); // Unlocks Ocean (15) and Desert (35)
      expect(controller1.isUnlocked('desert'), isTrue);

      final controller2 = CanvasThemeController();
      await controller2.load();
      expect(controller2.isUnlocked('meadow'), isTrue);
      expect(controller2.isUnlocked('ocean'), isTrue);
      expect(controller2.isUnlocked('desert'), isTrue);
      expect(controller2.isUnlocked('candy'), isFalse);
    });

    test(
        'Migration unlocks canvases matching existing high score on first launch',
        () async {
      SharedPreferences.setMockInitialValues({});
      final controller = CanvasThemeController();
      // High score is 65 -> should unlock meadow (0), ocean (15), desert (35), candy (60)
      await controller.load(highScore: 65);

      expect(controller.isUnlocked('meadow'), isTrue);
      expect(controller.isUnlocked('ocean'), isTrue);
      expect(controller.isUnlocked('desert'), isTrue);
      expect(controller.isUnlocked('candy'), isTrue);
      expect(controller.isUnlocked('frost'), isFalse);
      expect(controller.isUnlocked('midnight'), isFalse);
    });

    test(
        'Selecting a locked theme is rejected and preserves previous selection',
        () async {
      final controller = CanvasThemeController();
      await controller.load();

      expect(controller.selectedThemeId, 'meadow');
      final result = await controller.selectTheme('midnight');
      expect(result, isFalse);
      expect(controller.selectedThemeId, 'meadow');
    });

    test('Selecting an unlocked theme succeeds and persists', () async {
      final controller = CanvasThemeController();
      await controller.load();
      controller.checkUnlock(15); // Unlocks ocean

      final result = await controller.selectTheme('ocean');
      expect(result, isTrue);
      expect(controller.selectedThemeId, 'ocean');
      expect(controller.selectedTheme.name, 'Ocean Breeze');

      // Reload in fresh instance
      final reloaded = CanvasThemeController();
      await reloaded.load();
      expect(reloaded.selectedThemeId, 'ocean');
    });

    test('Invalid or locked stored id falls back to meadow', () async {
      SharedPreferences.setMockInitialValues({
        'canvas.selectedTheme': 'non_existent_or_locked_theme',
      });
      final controller = CanvasThemeController();
      await controller.load();
      expect(controller.selectedThemeId, 'meadow');
    });

    test('NEW badge tracking works and clears after markAllAsViewed', () async {
      final controller = CanvasThemeController();
      await controller.load();

      expect(controller.isNew('meadow'), isFalse);

      controller.checkUnlock(15); // Unlocks ocean
      expect(controller.isNew('ocean'), isTrue);

      await controller.markAllAsViewed();
      expect(controller.isNew('ocean'), isFalse);
    });
  });
}
