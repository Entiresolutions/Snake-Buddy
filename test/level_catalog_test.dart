import 'package:flutter_test/flutter_test.dart';
import 'package:snake_game/levels/level_catalog.dart';
import 'package:snake_game/levels/level_model.dart';
import 'package:snake_game/levels/level_validator.dart';

void main() {
  group('Level Catalog and Validator Unit Tests', () {
    test('Catalog contains exactly 30 levels numbered 1 to 30', () {
      expect(kLevelCatalog.length, 30);
      for (int i = 0; i < 30; i++) {
        expect(kLevelCatalog[i].id, i + 1);
      }
    });

    test('All 30 levels pass validation rules V1-V7 with zero errors', () {
      for (final level in kLevelCatalog) {
        final errors = LevelValidator.validate(level);
        if (errors.isNotEmpty) {
          fail('Level ${level.id} (${level.name}) failed validation:\n${errors.join('\n')}');
        }
        expect(errors, isEmpty);
      }
    });

    test('Speed ramp formula matches PRD specifications', () {
      // Easy: base 300ms
      expect(LevelRules.calculateTickMs(300, 1), 300);
      expect(LevelRules.calculateTickMs(300, 10), 273);
      expect(LevelRules.calculateTickMs(300, 30), 213);

      // Normal: base 240ms
      expect(LevelRules.calculateTickMs(240, 1), 240);
      expect(LevelRules.calculateTickMs(240, 10), 218);
      expect(LevelRules.calculateTickMs(240, 30), 170);

      // Hard: base 160ms (clamped at min 90ms)
      expect(LevelRules.calculateTickMs(160, 1), 160);
      expect(LevelRules.calculateTickMs(160, 30), 114);
      expect(LevelRules.calculateTickMs(100, 30), 90); // clamp at 90
    });

    test('Spike group cycle timing works accurately', () {
      const spike = SpikeGroupConfig(id: 1, offTicks: 3, warnTicks: 2, onTicks: 2);
      expect(spike.stateAtTick(0), 'off');
      expect(spike.stateAtTick(1), 'off');
      expect(spike.stateAtTick(2), 'off');
      expect(spike.stateAtTick(3), 'warn');
      expect(spike.stateAtTick(4), 'warn');
      expect(spike.stateAtTick(5), 'on');
      expect(spike.stateAtTick(6), 'on');
      expect(spike.stateAtTick(7), 'off'); // wraps around
    });
  });
}
