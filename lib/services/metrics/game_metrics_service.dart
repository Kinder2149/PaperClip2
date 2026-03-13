import '../../constants/game_config.dart';
import '../../models/game_state.dart';
import '../market/market_insights_service.dart';
import '../upgrades/upgrade_effects_calculator.dart';
import '../units/value_objects.dart';

class MarketUiMetrics {
  final UnitsPerSecond demandPerSecondEstimated;
  final UnitsPerSecond productionPerSecondEstimated;
  final UnitsPerSecond salesPerSecondEstimated;
  final Money revenuePerSecondEstimated;

  final double qualityBonus;
  final double effectiveSellPrice;

  const MarketUiMetrics({
    required this.demandPerSecondEstimated,
    required this.productionPerSecondEstimated,
    required this.salesPerSecondEstimated,
    required this.revenuePerSecondEstimated,
    required this.qualityBonus,
    required this.effectiveSellPrice,
  });
}

class ProductionUiMetrics {
  final UnitsPerSecond demandPerSecondEstimated;
  final UnitsPerSecond baseProductionPerSecondEstimated;
  final UnitsPerSecond actualProductionPerSecondEstimated;

  final double metalPerPaperclip;
  final UnitsPerSecond metalUsagePerSecondEstimated;
  final UnitsPerSecond metalSavedPerSecondEstimated;
  final Ratio metalSavingRatio;

  const ProductionUiMetrics({
    required this.demandPerSecondEstimated,
    required this.baseProductionPerSecondEstimated,
    required this.actualProductionPerSecondEstimated,
    required this.metalPerPaperclip,
    required this.metalUsagePerSecondEstimated,
    required this.metalSavedPerSecondEstimated,
    required this.metalSavingRatio,
  });
}

class GameMetricsService {
  const GameMetricsService();

  static const MarketInsightsService _insightsService = MarketInsightsService();

  MarketUiMetrics computeMarket(GameState gameState) {
    final sellPrice = gameState.player.sellPrice;
    final marketingLevel = gameState.player.getMarketingLevel();
    final autoClipperCount = gameState.player.autoClipperCount;

    final qualityLevel = gameState.player.upgrades['quality']?.level ?? 0;
    final speedLevel = gameState.player.upgrades['speed']?.level ?? 0;
    final bulkLevel = gameState.player.upgrades['bulk']?.level ?? 0;

    final insights = _insightsService.compute(
      market: gameState.market,
      input: MarketInsightsInput(
        sellPrice: sellPrice,
        marketingLevel: marketingLevel,
        autoClipperCount: autoClipperCount,
        speedLevel: speedLevel,
        bulkLevel: bulkLevel,
        qualityLevel: qualityLevel,
      ),
    );

    final demandPerSecond = UnitsPerMinute(insights.demandPerMin).toPerSecond();
    final productionPerSecond = UnitsPerMinute(insights.productionPerMin).toPerSecond();
    final salesPerSecond = UnitsPerMinute(insights.effectiveSalesPerMin).toPerSecond();

    final revenuePerSecond = Money(
      insights.profitabilityPerMin / const Minutes(1.0).toSeconds().value,
    );

    return MarketUiMetrics(
      demandPerSecondEstimated: demandPerSecond,
      productionPerSecondEstimated: productionPerSecond,
      salesPerSecondEstimated: salesPerSecond,
      revenuePerSecondEstimated: revenuePerSecond,
      qualityBonus: insights.qualityBonus,
      effectiveSellPrice: insights.effectiveSellPrice,
    );
  }

  ProductionUiMetrics computeProduction(GameState gameState) {
    final demandPerSecond = gameState.market.calculateDemandPerSecond(
      price: gameState.player.sellPrice,
      marketingLevel: gameState.player.getMarketingLevel(),
    );

    final efficiencyLevel = gameState.player.upgrades['efficiency']?.level ?? 0;
    final speedLevel = gameState.player.upgrades['speed']?.level ?? 0;
    final bulkLevel = gameState.player.upgrades['bulk']?.level ?? 0;

    final speedBonus = UpgradeEffectsCalculator.speedMultiplier(level: speedLevel);
    final bulkBonus = UpgradeEffectsCalculator.bulkMultiplier(level: bulkLevel);

    final baseProductionPerSecond = UnitsPerSecond(
      gameState.player.autoClipperCount * GameConstants.BASE_AUTOCLIPPER_PRODUCTION,
    );
    final actualProductionPerSecond = UnitsPerSecond(
      baseProductionPerSecond.value * speedBonus * bulkBonus,
    );

    final metalPerPaperclip = UpgradeEffectsCalculator.metalPerPaperclip(
      efficiencyLevel: efficiencyLevel,
    );

    final metalUsagePerSecond = UnitsPerSecond(
      actualProductionPerSecond.value * metalPerPaperclip,
    );

    final baseMetalUsagePerSecond = UnitsPerSecond(
      actualProductionPerSecond.value * GameConstants.METAL_PER_PAPERCLIP,
    );

    final metalSavedPerSecond = UnitsPerSecond(
      baseMetalUsagePerSecond.value - metalUsagePerSecond.value,
    );

    final savingRatio = GameConstants.METAL_PER_PAPERCLIP > 0
        ? Ratio((GameConstants.METAL_PER_PAPERCLIP - metalPerPaperclip) / GameConstants.METAL_PER_PAPERCLIP)
        : const Ratio(0.0);

    return ProductionUiMetrics(
      demandPerSecondEstimated: demandPerSecond,
      baseProductionPerSecondEstimated: baseProductionPerSecond,
      actualProductionPerSecondEstimated: actualProductionPerSecond,
      metalPerPaperclip: metalPerPaperclip,
      metalUsagePerSecondEstimated: metalUsagePerSecond,
      metalSavedPerSecondEstimated: metalSavedPerSecond,
      metalSavingRatio: savingRatio,
    );
  }
}
