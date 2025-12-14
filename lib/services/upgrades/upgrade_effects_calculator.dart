import 'dart:math' show min, max;

import '../../constants/game_config.dart';

class UpgradeEffectsCalculator {
  static double speedMultiplier({required int level}) {
    return 1.0 + (level * GameConstants.SPEED_BONUS_PER_LEVEL);
  }

  static double bulkMultiplier({required int level}) {
    return 1.0 + (level * GameConstants.BULK_BONUS_PER_LEVEL);
  }

  static double efficiencyReduction({required int level}) {
    return min(
      level * GameConstants.EFFICIENCY_UPGRADE_MULTIPLIER,
      GameConstants.EFFICIENCY_MAX_REDUCTION,
    );
  }

  static double metalPerPaperclip({required int efficiencyLevel}) {
    final reduction = efficiencyReduction(level: efficiencyLevel);
    final efficiencyMultiplier = 1.0 - reduction;
    return GameConstants.METAL_PER_PAPERCLIP * efficiencyMultiplier;
  }

  static double qualityMultiplier({required int level}) {
    return 1.0 + (level * GameConstants.QUALITY_UPGRADE_BASE);
  }

  static double autoclipperDiscount({required int level}) {
    return min(1.0, level * GameConstants.AUTOMATION_DISCOUNT_BASE);
  }

  static double autoclipperCost({
    required int autoclippersOwned,
    required int automationLevel,
  }) {
    final baseCost = GameConstants.BASE_AUTOCLIPPER_COST;
    final discount = autoclipperDiscount(level: automationLevel);
    final costMultiplier = autoclippersOwned * 0.1;
    final finalCost = baseCost * (1.0 + costMultiplier) * (1.0 - discount);
    return max(finalCost, baseCost * 0.5);
  }

  static double metalStorageCapacity({required int storageLevel}) {
    return GameConstants.INITIAL_STORAGE_CAPACITY *
        (1 + (storageLevel * GameConstants.STORAGE_UPGRADE_MULTIPLIER));
  }
}
