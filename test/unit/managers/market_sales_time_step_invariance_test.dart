import 'package:flutter_test/flutter_test.dart';
import 'package:paperclip2/managers/market_manager.dart';
import 'package:paperclip2/managers/player_manager.dart';
import 'package:paperclip2/models/statistics_manager.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('MarketManager time invariance', () {
    test('processSales total quantity over 1s is stable across timestep', () {
      final player = PlayerManager();
      final stats = StatisticsManager();
      final market = MarketManager()..setManagers(player, stats);

      market.autoSellEnabled = true;
      market.reputation = 1.0;

      const startingPaperclips = 100000.0;
      const sellPrice = 0.2;
      const marketingLevel = 0;
      const qualityLevel = 0;

      int soldA = 0;
      double revenueA = 0.0;
      for (var i = 0; i < 10; i++) {
        final result = market.processSales(
          playerPaperclips: startingPaperclips,
          sellPrice: sellPrice,
          marketingLevel: marketingLevel,
          qualityLevel: qualityLevel,
          updatePaperclips: (_) {},
          updateMoney: (_) {},
          updateMarketState: false,
          elapsedSeconds: 0.1,
        );
        soldA += result.quantity;
        revenueA += result.revenue;
      }

      final player2 = PlayerManager();
      final stats2 = StatisticsManager();
      final market2 = MarketManager()..setManagers(player2, stats2);

      market2.autoSellEnabled = true;
      market2.reputation = 1.0;

      final resultB = market2.processSales(
        playerPaperclips: startingPaperclips,
        sellPrice: sellPrice,
        marketingLevel: marketingLevel,
        qualityLevel: qualityLevel,
        updatePaperclips: (_) {},
        updateMoney: (_) {},
        updateMarketState: false,
        elapsedSeconds: 1.0,
      );

      expect((soldA - resultB.quantity).abs(), lessThanOrEqualTo(1));
      expect((revenueA - resultB.revenue).abs(), lessThanOrEqualTo(sellPrice + 1e-6));
    });

    test('processSales revenue matches quantity * unitPrice per call', () {
      final player = PlayerManager();
      final stats = StatisticsManager();
      final market = MarketManager()..setManagers(player, stats);

      market.autoSellEnabled = true;
      market.reputation = 1.0;

      double remaining = 1000.0;
      for (var i = 0; i < 20; i++) {
        final result = market.processSales(
          playerPaperclips: remaining,
          sellPrice: 0.25,
          marketingLevel: 0,
          qualityLevel: 0,
          updatePaperclips: (delta) => remaining += delta,
          updateMoney: (_) {},
          updateMarketState: false,
          elapsedSeconds: 0.5,
        );

        expect(result.revenue, closeTo(result.quantity * result.unitPrice, 1e-9));
      }
    });

    test('processSales totals over 60s are stable across timestep', () {
      const durationSeconds = 60.0;
      const sellPrice = 0.2;
      const marketingLevel = 0;
      const qualityLevel = 0;
      const startingPaperclips = 1000000.0;

      final marketA = MarketManager()..setManagers(PlayerManager(), StatisticsManager());
      marketA.autoSellEnabled = true;
      marketA.reputation = 1.0;

      int soldA = 0;
      double revenueA = 0.0;
      final stepsA = (durationSeconds / 0.1).round();
      for (var i = 0; i < stepsA; i++) {
        final result = marketA.processSales(
          playerPaperclips: startingPaperclips,
          sellPrice: sellPrice,
          marketingLevel: marketingLevel,
          qualityLevel: qualityLevel,
          updatePaperclips: (_) {},
          updateMoney: (_) {},
          updateMarketState: false,
          elapsedSeconds: 0.1,
        );
        soldA += result.quantity;
        revenueA += result.revenue;
      }

      final marketB = MarketManager()..setManagers(PlayerManager(), StatisticsManager());
      marketB.autoSellEnabled = true;
      marketB.reputation = 1.0;

      int soldB = 0;
      double revenueB = 0.0;
      final stepsB = (durationSeconds / 1.0).round();
      for (var i = 0; i < stepsB; i++) {
        final result = marketB.processSales(
          playerPaperclips: startingPaperclips,
          sellPrice: sellPrice,
          marketingLevel: marketingLevel,
          qualityLevel: qualityLevel,
          updatePaperclips: (_) {},
          updateMoney: (_) {},
          updateMarketState: false,
          elapsedSeconds: 1.0,
        );
        soldB += result.quantity;
        revenueB += result.revenue;
      }

      expect((soldA - soldB).abs(), lessThanOrEqualTo(1));
      expect((revenueA - revenueB).abs(), lessThanOrEqualTo(sellPrice + 1e-6));
    });

    test('processSales does not exceed available stock over time steps', () {
      final player = PlayerManager();
      final stats = StatisticsManager();
      final market = MarketManager()..setManagers(player, stats);

      market.autoSellEnabled = true;
      market.reputation = 1.0;

      const startingPaperclips = 3.0;

      double remaining = startingPaperclips;
      var totalSold = 0;

      for (var i = 0; i < 20; i++) {
        final result = market.processSales(
          playerPaperclips: remaining,
          sellPrice: 0.2,
          marketingLevel: 0,
          qualityLevel: 0,
          updatePaperclips: (delta) {
            remaining += delta;
          },
          updateMoney: (_) {},
          updateMarketState: false,
          elapsedSeconds: 0.25,
        );
        totalSold += result.quantity;
      }

      expect(totalSold, lessThanOrEqualTo(startingPaperclips.toInt()));
      expect(remaining, greaterThanOrEqualTo(0.0));
    });
  });
}
