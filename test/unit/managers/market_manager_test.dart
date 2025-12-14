import 'package:flutter_test/flutter_test.dart';
import 'package:paperclip2/managers/market_manager.dart';
import 'package:paperclip2/managers/player_manager.dart';
import 'package:paperclip2/models/statistics_manager.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('MarketManager', () {
    test('processSales retourne none si autoSellEnabled=false', () {
      final player = PlayerManager();
      final stats = StatisticsManager();
      final market = MarketManager()..setManagers(player, stats);

      market.autoSellEnabled = false;

      final result = market.processSales(
        playerPaperclips: 100,
        sellPrice: 0.2,
        marketingLevel: 0,
        updatePaperclips: (_) {},
        updateMoney: (_) {},
        updateMarketState: false,
        requireAutoSellEnabled: true,
      );

      expect(result.quantity, 0);
      expect(result.revenue, 0.0);
      expect(stats.totalMoneyEarned, 0.0);
    });

    test('processSales vend des trombones, crédite l’argent et met à jour stats', () {
      final player = PlayerManager();
      final stats = StatisticsManager();
      final market = MarketManager()..setManagers(player, stats);

      // Forcer un état stable
      market.autoSellEnabled = true;

      double paperclipsDelta = 0.0;
      double moneyDelta = 0.0;

      const playerPaperclips = 100.0;
      const sellPrice = 0.20;

      final result = market.processSales(
        playerPaperclips: playerPaperclips,
        sellPrice: sellPrice,
        marketingLevel: 0,
        updatePaperclips: (delta) => paperclipsDelta += delta,
        updateMoney: (delta) => moneyDelta += delta,
        updateMarketState: false,
      );

      // Doit vendre quelque chose si playerPaperclips > 0
      expect(result.quantity, greaterThan(0));

      // Le manager applique un bonus qualité : salePrice = sellPrice * (1 + sellPrice*0.10)
      final expectedUnitPrice = sellPrice * (1.0 + (sellPrice * 0.10));
      expect(result.unitPrice, closeTo(expectedUnitPrice, 0.0001));

      expect(paperclipsDelta, closeTo(-result.quantity.toDouble(), 0.0001));
      expect(moneyDelta, closeTo(result.revenue, 0.0001));

      expect(stats.totalMoneyEarned, closeTo(result.revenue, 0.0001));
      expect(market.salesHistory.length, 1);
      expect(market.salesHistory.first.quantity, result.quantity);
    });

    test('processSales retourne none si playerPaperclips=0', () {
      final player = PlayerManager();
      final stats = StatisticsManager();
      final market = MarketManager()..setManagers(player, stats);

      double moneyDelta = 0.0;

      final result = market.processSales(
        playerPaperclips: 0,
        sellPrice: 0.2,
        marketingLevel: 0,
        updatePaperclips: (_) {},
        updateMoney: (delta) => moneyDelta += delta,
        updateMarketState: false,
      );

      expect(result, MarketSaleResult.none);
      expect(moneyDelta, 0.0);
      expect(stats.totalMoneyEarned, 0.0);
    });
  });
}
