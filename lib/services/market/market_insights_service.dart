import 'dart:math' show min;

import '../../managers/market_manager.dart';
import '../../constants/game_config.dart';
import '../upgrades/upgrade_effects_calculator.dart';
import '../units/value_objects.dart';

class MarketInsightsInput {
  final double sellPrice;
  final int marketingLevel;
  final int autoClipperCount;

  final int speedLevel;
  final int bulkLevel;
  final int qualityLevel;

  const MarketInsightsInput({
    required this.sellPrice,
    required this.marketingLevel,
    required this.autoClipperCount,
    required this.speedLevel,
    required this.bulkLevel,
    required this.qualityLevel,
  });
}

class MarketInsights {
  final double demandPerMin;
  final double productionPerMin;
  final double effectiveSalesPerMin;
  final double profitabilityPerMin;

  final bool isOverProducing;
  final bool isUnderProducing;

  final double qualityBonus;
  final double effectiveSellPrice;

  const MarketInsights({
    required this.demandPerMin,
    required this.productionPerMin,
    required this.effectiveSalesPerMin,
    required this.profitabilityPerMin,
    required this.isOverProducing,
    required this.isUnderProducing,
    required this.qualityBonus,
    required this.effectiveSellPrice,
  });
}

class MarketInsightsService {
  const MarketInsightsService();

  MarketInsights compute({
    required MarketManager market,
    required MarketInsightsInput input,
  }) {
    final demandPerSec = market.calculateDemandPerSecond(
      price: input.sellPrice,
      marketingLevel: input.marketingLevel,
    );
    final demandPerMin = demandPerSec.toPerMinute().value;

    double productionPerMin = 0;
    if (input.autoClipperCount > 0) {
      productionPerMin = UnitsPerSecond(
        input.autoClipperCount * GameConstants.BASE_AUTOCLIPPER_PRODUCTION,
      ).toPerMinute().value;
      final speedBonus = UpgradeEffectsCalculator.speedMultiplier(level: input.speedLevel);
      final bulkBonus = UpgradeEffectsCalculator.bulkMultiplier(level: input.bulkLevel);
      productionPerMin *= speedBonus * bulkBonus;
    }

    final effectiveSalesPerMin = min(demandPerMin, productionPerMin);

    final qualityBonus = UpgradeEffectsCalculator.qualityMultiplier(level: input.qualityLevel);
    final effectiveSellPrice = input.sellPrice * qualityBonus;

    final profitabilityPerMin = effectiveSalesPerMin * effectiveSellPrice;

    return MarketInsights(
      demandPerMin: demandPerMin,
      productionPerMin: productionPerMin,
      effectiveSalesPerMin: effectiveSalesPerMin,
      profitabilityPerMin: profitabilityPerMin,
      isOverProducing: productionPerMin > demandPerMin,
      isUnderProducing: demandPerMin > productionPerMin,
      qualityBonus: qualityBonus,
      effectiveSellPrice: effectiveSellPrice,
    );
  }
}
