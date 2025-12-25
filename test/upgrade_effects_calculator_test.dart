import 'package:flutter_test/flutter_test.dart';
import 'package:paperclip2/services/upgrades/upgrade_effects_calculator.dart';
import 'package:paperclip2/constants/game_config.dart';

void main() {
  group('UpgradeEffectsCalculator', () {
    test('speedMultiplier increases linearly with level', () {
      expect(UpgradeEffectsCalculator.speedMultiplier(level: 0), 1.0);
      expect(UpgradeEffectsCalculator.speedMultiplier(level: 1), 1.0 + GameConstants.SPEED_BONUS_PER_LEVEL);
      expect(UpgradeEffectsCalculator.speedMultiplier(level: 5), 1.0 + 5 * GameConstants.SPEED_BONUS_PER_LEVEL);
    });

    test('bulkMultiplier increases linearly with level', () {
      expect(UpgradeEffectsCalculator.bulkMultiplier(level: 0), 1.0);
      expect(UpgradeEffectsCalculator.bulkMultiplier(level: 2), 1.0 + 2 * GameConstants.BULK_BONUS_PER_LEVEL);
    });

    test('efficiencyReduction is capped at EFFICIENCY_MAX_REDUCTION', () {
      final cap = GameConstants.EFFICIENCY_MAX_REDUCTION;
      final high = UpgradeEffectsCalculator.efficiencyReduction(level: 1000);
      expect(high, cap);
    });

    test('metalPerPaperclip applies efficiency reduction correctly', () {
      final base = GameConstants.METAL_PER_PAPERCLIP;
      final l0 = UpgradeEffectsCalculator.metalPerPaperclip(efficiencyLevel: 0);
      expect(l0, base);

      final l1 = UpgradeEffectsCalculator.metalPerPaperclip(efficiencyLevel: 1);
      final reduction = GameConstants.EFFICIENCY_UPGRADE_MULTIPLIER; // 0.1 per level
      expect(l1, closeTo(base * (1.0 - reduction), 1e-9));
    });

    test('autoclipperDiscount and cost behave with bounds', () {
      // discount capped at 1.0
      expect(UpgradeEffectsCalculator.autoclipperDiscount(level: 999), 1.0);

      // cost never below 50% of base
      final base = GameConstants.BASE_AUTOCLIPPER_COST;
      final cost = UpgradeEffectsCalculator.autoclipperCost(autoclippersOwned: 100, automationLevel: 999);
      expect(cost, greaterThanOrEqualTo(base * 0.5));
    });

    test('metalStorageCapacity scales with storage level', () {
      final baseCap = GameConstants.INITIAL_STORAGE_CAPACITY;
      expect(UpgradeEffectsCalculator.metalStorageCapacity(storageLevel: 0), baseCap * (1 + 0 * GameConstants.STORAGE_UPGRADE_MULTIPLIER));
      expect(UpgradeEffectsCalculator.metalStorageCapacity(storageLevel: 2), baseCap * (1 + 2 * GameConstants.STORAGE_UPGRADE_MULTIPLIER));
    });

    test('market upgrades caps are enforced', () {
      // reputation cap
      final rep = UpgradeEffectsCalculator.reputationBonus(level: 999);
      expect(rep, GameConstants.REPUTATION_BONUS_CAP);

      // volatility cap
      final vol = UpgradeEffectsCalculator.volatilityReduction(level: 999);
      expect(vol, GameConstants.VOLATILITY_REDUCTION_CAP);

      // metal discount cap
      final disc = UpgradeEffectsCalculator.metalDiscount(level: 999);
      expect(disc, GameConstants.METAL_DISCOUNT_CAP);
    });
  });
}
