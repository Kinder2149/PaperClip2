import 'package:flutter_test/flutter_test.dart';

import 'package:paperclip2/models/game_state.dart';
import 'package:paperclip2/services/market/market_insights_service.dart';
import 'package:paperclip2/services/metrics/game_metrics_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('GameMetricsService', () {
    test('computeMarket returns non-negative rates and consistent sell price', () {
      final gameState = GameState();
      const service = GameMetricsService();

      final metrics = service.computeMarket(gameState);

      expect(metrics.demandPerSecondEstimated.value, greaterThanOrEqualTo(0.0));
      expect(metrics.productionPerSecondEstimated.value, greaterThanOrEqualTo(0.0));
      expect(metrics.salesPerSecondEstimated.value, greaterThanOrEqualTo(0.0));
      expect(metrics.revenuePerSecondEstimated.value, greaterThanOrEqualTo(0.0));

      expect(metrics.qualityBonus, greaterThanOrEqualTo(1.0));
      expect(metrics.effectiveSellPrice, closeTo(gameState.player.sellPrice * metrics.qualityBonus, 1e-9));
    });

    test('computeProduction returns non-negative usage and saved metal', () {
      final gameState = GameState();
      const service = GameMetricsService();

      final metrics = service.computeProduction(gameState);

      expect(metrics.demandPerSecondEstimated.value, greaterThanOrEqualTo(0.0));
      expect(metrics.baseProductionPerSecondEstimated.value, greaterThanOrEqualTo(0.0));
      expect(metrics.actualProductionPerSecondEstimated.value, greaterThanOrEqualTo(0.0));

      expect(metrics.metalUsagePerSecondEstimated.value, greaterThanOrEqualTo(0.0));
      expect(metrics.metalSavedPerSecondEstimated.value, greaterThanOrEqualTo(0.0));

      expect(metrics.metalSavingRatio.value, greaterThanOrEqualTo(0.0));
      expect(metrics.metalSavingRatio.value, lessThanOrEqualTo(1.0));
    });

    test('computeMarket revenuePerSecond is consistent with profitabilityPerMin', () {
      final gameState = GameState();
      const service = GameMetricsService();
      const insightsService = MarketInsightsService();

      final metrics = service.computeMarket(gameState);

      final insights = insightsService.compute(
        market: gameState.market,
        input: MarketInsightsInput(
          sellPrice: gameState.player.sellPrice,
          marketingLevel: gameState.player.getMarketingLevel(),
          autoClipperCount: gameState.player.autoClipperCount,
          speedLevel: gameState.player.upgrades['speed']?.level ?? 0,
          bulkLevel: gameState.player.upgrades['bulk']?.level ?? 0,
          qualityLevel: gameState.player.upgrades['quality']?.level ?? 0,
        ),
      );

      expect(
        metrics.revenuePerSecondEstimated.value * 60.0,
        closeTo(insights.profitabilityPerMin, 1e-9),
      );
    });
  });
}
