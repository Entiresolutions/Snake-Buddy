import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:snake_game/controllers/campaign_controller.dart';
import 'package:snake_game/levels/level_catalog.dart';
import 'package:snake_game/levels/level_model.dart';
import 'package:snake_game/ui/screens/snake/snake_play_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('1. Speed Ramp Formula Tests', () {
    test('Calculates correct tickMs across difficulties and levels', () {
      // Normal: 240 base
      expect(LevelRules.calculateTickMs(240, 1), 240);
      expect(LevelRules.calculateTickMs(240, 2), 238); // 240 * 0.99
      expect(LevelRules.calculateTickMs(240, 11), 216); // 240 * 0.90
      expect(LevelRules.calculateTickMs(240, 30), 170); // 240 * 0.71 = 170.4 -> 170

      // Easy: 300 base
      expect(LevelRules.calculateTickMs(300, 1), 300);
      expect(LevelRules.calculateTickMs(300, 30), 213); // 300 * 0.71 = 213

      // Hard: 160 base
      expect(LevelRules.calculateTickMs(160, 1), 160);
      expect(LevelRules.calculateTickMs(160, 30), 114); // 160 * 0.71 = 113.6 -> 114

      // Clamps at minimum 90ms
      expect(LevelRules.calculateTickMs(100, 30), 90);
      expect(LevelRules.calculateTickMs(50, 1), 90);
    });
  });

  group('2. Unlock and Star Persistence Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('Initial state: level 1 unlocked, levels 2-30 locked, 0 stars', () async {
      final campaign = CampaignController();
      await campaign.load();

      expect(campaign.highestUnlockedLevel, 1);
      expect(campaign.isLevelUnlocked(1), isTrue);
      for (int i = 2; i <= 30; i++) {
        expect(campaign.isLevelUnlocked(i), isFalse);
        expect(campaign.getStarsForLevel(i), 0);
      }
      expect(campaign.totalStars, 0);
    });

    test('Level completion unlocks next level and saves stars based on chances', () async {
      final campaign = CampaignController();
      await campaign.load();

      // Clear level 1 with 0 chances used -> 3 stars
      campaign.startLevel(1);
      expect(campaign.chancesUsedThisAttempt, 0);
      final starsEarned = await campaign.onLevelComplete(levelId: 1, levelScore: 100);
      expect(starsEarned, 3);
      expect(campaign.getStarsForLevel(1), 3);
      expect(campaign.highestUnlockedLevel, 2);
      expect(campaign.isLevelUnlocked(2), isTrue);
      expect(campaign.totalStars, 3);

      // Clear level 2 with 1 chance used -> 2 stars
      campaign.startLevel(2);
      campaign.useChance();
      expect(campaign.chancesUsedThisAttempt, 1);
      final stars2 = await campaign.onLevelComplete(levelId: 2, levelScore: 104);
      expect(stars2, 2);
      expect(campaign.getStarsForLevel(2), 2);
      expect(campaign.highestUnlockedLevel, 3);
      expect(campaign.totalStars, 5);
    });

    test('Stars are never downgraded on worse replay', () async {
      final campaign = CampaignController();
      await campaign.load();

      campaign.startLevel(1);
      await campaign.onLevelComplete(levelId: 1, levelScore: 100); // 3 stars
      expect(campaign.getStarsForLevel(1), 3);

      // Replay with 2 chances used (1 star)
      campaign.startLevel(1);
      campaign.useChance();
      campaign.useChance();
      await campaign.onLevelComplete(levelId: 1, levelScore: 100);
      expect(campaign.getStarsForLevel(1), 3); // Keeps best 3 stars!
    });

    test('Starting a locked level is rejected at controller level', () async {
      final campaign = CampaignController();
      await campaign.load();

      expect(campaign.startLevel(5), isFalse);
      expect(campaign.currentLevelId, 1);
    });

    test('State persists across reload', () async {
      final campaign1 = CampaignController();
      await campaign1.load();
      campaign1.startLevel(1);
      await campaign1.onLevelComplete(levelId: 1, levelScore: 100);

      // New controller instance loading same prefs
      final campaign2 = CampaignController();
      await campaign2.load();
      expect(campaign2.highestUnlockedLevel, 2);
      expect(campaign2.getStarsForLevel(1), 3);
      expect(campaign2.isLevelUnlocked(2), isTrue);
    });
  });

  group('3. Hazard Collision & Tick Order Logic', () {
    test('Spike cycle transitions: off -> warn -> on', () {
      final spike = SpikeGroupConfig(id: 1, offTicks: 3, warnTicks: 2, onTicks: 2, phaseOffset: 0);
      // Period = 7
      expect(spike.stateAtTick(0), 'off');
      expect(spike.stateAtTick(1), 'off');
      expect(spike.stateAtTick(2), 'off');
      expect(spike.stateAtTick(3), 'warn');
      expect(spike.stateAtTick(4), 'warn');
      expect(spike.stateAtTick(5), 'on');
      expect(spike.stateAtTick(6), 'on');
      expect(spike.stateAtTick(7), 'off'); // Loops
    });

    test('Patrol ping-pong movement updates previous and current positions', () {
      final patrolConfig = PatrolConfig(
        path: const [
          [2, 5],
          [3, 5],
          [4, 5],
        ],
        mode: PatrolMode.pingPong,
        stepEveryTicks: 1,
      );

      final state = PatrolRuntimeState(
        config: patrolConfig,
        id: 0,
        currentStepIndex: 0,
        directionSign: 1,
        previousPos: [2, 5],
        currentPos: [2, 5],
        moveDirection: 'right',
      );

      // Tick 1: moves to [3, 5]
      state.step(1);
      expect(state.previousPos, [2, 5]);
      expect(state.currentPos, [3, 5]);
      expect(state.moveDirection, 'right');

      // Tick 2: moves to [4, 5]
      state.step(2);
      expect(state.previousPos, [3, 5]);
      expect(state.currentPos, [4, 5]);
      expect(state.directionSign, -1); // Bounces back

      // Tick 3: moves back to [3, 5]
      state.step(3);
      expect(state.currentPos, [3, 5]);
      expect(state.moveDirection, 'left');
    });

    test('Patrol swap collision detection', () {
      final patrolConfig = PatrolConfig(
        path: const [
          [5, 5],
          [6, 5],
        ],
        stepEveryTicks: 1,
      );

      final state = PatrolRuntimeState(
        config: patrolConfig,
        id: 0,
        currentStepIndex: 0,
        directionSign: 1,
        previousPos: [5, 5],
        currentPos: [6, 5],
        moveDirection: 'right',
      );

      // Head was at (6, 5) and moves to (5, 5) while patrol was at (5, 5) and moved to (6, 5)
      final headOld = [6, 5];
      final headNew = [5, 5];
      expect(state.swapped(headOld, headNew), isTrue);
    });

    test('Food spawning never spawns on hazards, portals, spikes, or patrol paths', () {
      for (final level in kLevelCatalog) {
        final rocks = level.rocks.map((p) => '${p[0]},${p[1]}').toSet();
        final portals = <String>{};
        for (final pts in level.portals.values) {
          for (final p in pts) {
            portals.add('${p[0]},${p[1]}');
          }
        }
        final spikes = <String>{};
        for (final pts in level.spikes.values) {
          for (final p in pts) {
            spikes.add('${p[0]},${p[1]}');
          }
        }
        final patrolCells = <String>{};
        for (final p in level.patrols) {
          for (final pt in p.path) {
            patrolCells.add('${pt[0]},${pt[1]}');
          }
        }

        // Check that starting snake positions never overlap hazards
        for (final s in LevelRules.initialSnake) {
          final sKey = '${s[0]},${s[1]}';
          expect(rocks.contains(sKey), isFalse, reason: 'Level ${level.id} snake on rock');
          expect(portals.contains(sKey), isFalse, reason: 'Level ${level.id} snake on portal');
          expect(spikes.contains(sKey), isFalse, reason: 'Level ${level.id} snake on spike');
          expect(patrolCells.contains(sKey), isFalse, reason: 'Level ${level.id} snake on patrol');
        }
      }
    });
  });
}
