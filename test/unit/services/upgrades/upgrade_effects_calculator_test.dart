import 'package:flutter_test/flutter_test.dart';

import 'package:paperclip2/constants/game_config.dart';
import 'package:paperclip2/services/upgrades/upgrade_effects_calculator.dart';

void main() {
  group('UpgradeEffectsCalculator', () {
    test('speedMultiplier: level 0 = 1.0 et level 1 = 1 + SPEED_BONUS_PER_LEVEL', () {
      expect(UpgradeEffectsCalculator.speedMultiplier(level: 0), 1.0);
      expect(
        UpgradeEffectsCalculator.speedMultiplier(level: 1),
        closeTo(1.0 + GameConstants.SPEED_BONUS_PER_LEVEL, 0.000001),
      );
    });

    test('bulkMultiplier: level 0 = 1.0 et level 2 = 1 + 2*BULK_BONUS_PER_LEVEL', () {
      expect(UpgradeEffectsCalculator.bulkMultiplier(level: 0), 1.0);
      expect(
        UpgradeEffectsCalculator.bulkMultiplier(level: 2),
        closeTo(1.0 + (2 * GameConstants.BULK_BONUS_PER_LEVEL), 0.000001),
      );
    });

    test('efficiencyReduction est plafonnée à EFFICIENCY_MAX_REDUCTION', () {
      final highLevel = 999;
      final reduction = UpgradeEffectsCalculator.efficiencyReduction(level: highLevel);
      expect(reduction, closeTo(GameConstants.EFFICIENCY_MAX_REDUCTION, 0.000001));
    });

    test('metalPerPaperclip diminue quand efficiencyLevel augmente', () {
      final base = UpgradeEffectsCalculator.metalPerPaperclip(efficiencyLevel: 0);
      final improved = UpgradeEffectsCalculator.metalPerPaperclip(efficiencyLevel: 1);
      expect(improved, lessThan(base));
    });

    test('qualityMultiplier: level 0 = 1.0 et level 3 = 1 + 3*QUALITY_UPGRADE_BASE', () {
      expect(UpgradeEffectsCalculator.qualityMultiplier(level: 0), 1.0);
      expect(
        UpgradeEffectsCalculator.qualityMultiplier(level: 3),
        closeTo(1.0 + (3 * GameConstants.QUALITY_UPGRADE_BASE), 0.000001),
      );
    });

    test('autoclipperCost: respecte le plancher baseCost*0.5', () {
      final baseCost = GameConstants.BASE_AUTOCLIPPER_COST;
      final cost = UpgradeEffectsCalculator.autoclipperCost(
        autoclippersOwned: 0,
        automationLevel: 999,
      );
      expect(cost, greaterThanOrEqualTo(baseCost * 0.5));
    });

    test('metalStorageCapacity augmente avec storageLevel', () {
      final c0 = UpgradeEffectsCalculator.metalStorageCapacity(storageLevel: 0);
      final c1 = UpgradeEffectsCalculator.metalStorageCapacity(storageLevel: 1);
      expect(c1, greaterThan(c0));
    });
  });
}
