import 'package:flutter_test/flutter_test.dart';

import 'package:paperclip2/managers/market_manager.dart';
import 'package:paperclip2/constants/game_config.dart';
import 'package:paperclip2/services/market/market_insights_service.dart';

void main() {
  group('MarketInsightsService', () {
    test('compute: demand uses MarketManager.calculateDemand and production is 0 when no autoclippers', () {
      final market = MarketManager();
      const service = MarketInsightsService();

      const input = MarketInsightsInput(
        sellPrice: 0.0,
        marketingLevel: 0,
        autoClipperCount: 0,
        speedLevel: 0,
        bulkLevel: 0,
        qualityLevel: 0,
      );

      final insights = service.compute(market: market, input: input);

      // Demand is expressed as units/sec in MarketManager and exposed here as units/min.
      expect(insights.demandPerMin, closeTo(GameConstants.BASE_DEMAND * 60.0, 1e-9));
      expect(insights.productionPerMin, 0.0);
      expect(insights.effectiveSalesPerMin, 0.0);
      expect(insights.profitabilityPerMin, 0.0);
      expect(insights.isOverProducing, isFalse);
      expect(insights.isUnderProducing, isTrue);
    });

    test('compute: production applies speed/bulk bonuses and profitability matches effectiveSales*sellPrice', () {
      final market = MarketManager();
      const service = MarketInsightsService();

      const input = MarketInsightsInput(
        sellPrice: 1.0,
        marketingLevel: 0,
        autoClipperCount: 2,
        speedLevel: 1,
        bulkLevel: 1,
        qualityLevel: 0,
      );

      final insights = service.compute(market: market, input: input);

      // base production per min = autoClipperCount * BASE_AUTOCLIPPER_PRODUCTION * 60
      const expectedProduction = (2 * (GameConstants.BASE_AUTOCLIPPER_PRODUCTION * 60.0)) *
          (1.0 + (1 * GameConstants.SPEED_BONUS_PER_LEVEL)) *
          (1.0 + (1 * GameConstants.BULK_BONUS_PER_LEVEL));

      expect(insights.productionPerMin, closeTo(expectedProduction, 1e-9));
      expect(insights.effectiveSalesPerMin, closeTo(
        insights.demandPerMin < expectedProduction ? insights.demandPerMin : expectedProduction,
        1e-9,
      ));
      expect(insights.profitabilityPerMin, closeTo(insights.effectiveSalesPerMin * 1.0, 1e-9));
    });

    test('compute: qualityBonus and effectiveSellPrice are derived from UpgradeEffectsCalculator', () {
      final market = MarketManager();
      const service = MarketInsightsService();

      const input = MarketInsightsInput(
        sellPrice: 2.0,
        marketingLevel: 0,
        autoClipperCount: 0,
        speedLevel: 0,
        bulkLevel: 0,
        qualityLevel: 2,
      );

      final insights = service.compute(market: market, input: input);

      // qualityMultiplier(level: 2) is tested elsewhere, here we only validate consistency.
      expect(insights.effectiveSellPrice, closeTo(2.0 * insights.qualityBonus, 1e-9));
      expect(insights.qualityBonus, greaterThanOrEqualTo(1.0));
    });

    test('compute: profitability uses effective sell price (includes quality)', () {
      final market = MarketManager();
      const service = MarketInsightsService();

      const input = MarketInsightsInput(
        sellPrice: 2.0,
        marketingLevel: 0,
        autoClipperCount: 1,
        speedLevel: 0,
        bulkLevel: 0,
        qualityLevel: 2,
      );

      final insights = service.compute(market: market, input: input);

      // profitabilityPerMin should match effectiveSalesPerMin * effectiveSellPrice
      expect(
        insights.profitabilityPerMin,
        closeTo(insights.effectiveSalesPerMin * insights.effectiveSellPrice, 1e-9),
      );
    });
  });
}
